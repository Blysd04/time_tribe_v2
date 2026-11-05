package services

import (
	"context"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/v2/bson"

	"timetribe-backend/internal/models"
	"timetribe-backend/internal/repository"
	"timetribe-backend/internal/utils"
)

// AttendanceDTO là phản hồi của một thành viên với hoạt động nhóm.
type AttendanceDTO struct {
	models.TribeBlockAttendance
	User models.AppUser `json:"user"`
}

// TribeBlockDTO là hoạt động nhóm kèm giờ UTC đầy đủ, giờ đã đổi sang múi giờ người xem
// và danh sách phản hồi của từng thành viên.
type TribeBlockDTO struct {
	models.TribeBlock
	StartUTC       time.Time       `json:"start_utc"`
	EndUTC         time.Time       `json:"end_utc"`
	LocalDate      string          `json:"local_date"`
	LocalStartTime string          `json:"local_start_time"`
	LocalEndTime   string          `json:"local_end_time"`
	MyStatus       string          `json:"my_status"`
	Counts         map[string]int  `json:"counts,omitempty"`
	Attendance     []AttendanceDTO `json:"attendance,omitempty"`
	TribeName      string          `json:"tribe_name,omitempty"`
	TribeColor     *string         `json:"tribe_color,omitempty"`
}

func (s *TribeService) blockDTO(b *models.TribeBlock, members []models.TribeAttendee, rows map[string]models.TribeBlockAttendance,
	myStatus string, loc *time.Location) TribeBlockDTO {
	r := utils.UTCRange(b.Date, b.StartTime, b.EndTime)
	if myStatus == "" {
		myStatus = models.AttendancePending
	}
	start, end := r.Start.In(loc), r.End.In(loc)
	dto := TribeBlockDTO{
		TribeBlock: *b, StartUTC: r.Start, EndUTC: r.End,
		LocalDate: start.Format(utils.DateLayout), LocalStartTime: start.Format(utils.ClockLayout),
		LocalEndTime: end.Format(utils.ClockLayout), MyStatus: myStatus,
	}
	if members != nil {
		dto.Counts = map[string]int{models.AttendanceAccepted: 0, models.AttendanceDeclined: 0, models.AttendancePending: 0}
		dto.Attendance = []AttendanceDTO{}
		for _, m := range members {
			row, ok := rows[m.UserID]
			if !ok {
				// Chưa có dòng điểm danh thì coi như đang chờ phản hồi
				row = models.TribeBlockAttendance{TribeBlockID: b.ID, UserID: m.UserID, Status: models.AttendancePending, UpdatedAt: b.CreatedAt}
			}
			dto.Counts[row.Status]++
			dto.Attendance = append(dto.Attendance, AttendanceDTO{TribeBlockAttendance: row})
		}
	}
	return dto
}

// statusMap trả trạng thái của một người với danh sách hoạt động (map theo block id).
func (s *TribeService) statusMap(ctx context.Context, blocks []models.TribeBlock, userID string) (map[string]string, error) {
	out := map[string]string{}
	if len(blocks) == 0 {
		return out, nil
	}
	ids := make([]string, len(blocks))
	for i, b := range blocks {
		ids[i] = b.ID
	}
	rows, err := repository.FindMany[models.TribeBlockAttendance](ctx, s.store.TribeBlockAttendance, bson.M{
		"tribe_block_id": repository.In(ids), "user_id": userID,
	})
	if err != nil {
		return nil, err
	}
	for _, r := range rows {
		out[r.TribeBlockID] = r.Status
	}
	return out, nil
}

// blocksInWindow lấy hoạt động của các nhóm có giao với cửa sổ thời gian (UTC).
// Vì date lưu theo UTC và có thể qua nửa đêm nên lấy rộng ra một ngày rồi lọc lại.
func (s *TribeService) blocksInWindow(ctx context.Context, filter bson.M, w utils.TimeRange) ([]models.TribeBlock, error) {
	filter["date"] = bson.M{
		"$gte": w.Start.AddDate(0, 0, -1).Format(utils.DateLayout),
		"$lte": w.End.Format(utils.DateLayout),
	}
	list, err := repository.FindMany[models.TribeBlock](ctx, s.store.TribeBlocks, filter)
	if err != nil {
		return nil, err
	}
	out := []models.TribeBlock{}
	for _, b := range list {
		if utils.UTCRange(b.Date, b.StartTime, b.EndTime).Overlaps(w) {
			out = append(out, b)
		}
	}
	sort.SliceStable(out, func(i, j int) bool {
		return utils.UTCRange(out[i].Date, out[i].StartTime, out[i].EndTime).Start.
			Before(utils.UTCRange(out[j].Date, out[j].StartTime, out[j].EndTime).Start)
	})
	return out, nil
}

// fillAttendance gắn danh sách phản hồi (kèm thông tin người dùng) cho nhiều hoạt động.
func (s *TribeService) fillAttendance(ctx context.Context, blocks []models.TribeBlock, members []models.TribeAttendee, me string, loc *time.Location) ([]TribeBlockDTO, error) {
	out := []TribeBlockDTO{}
	if len(blocks) == 0 {
		return out, nil
	}
	ids := make([]string, len(blocks))
	for i, b := range blocks {
		ids[i] = b.ID
	}
	rows, err := repository.FindMany[models.TribeBlockAttendance](ctx, s.store.TribeBlockAttendance, bson.M{"tribe_block_id": repository.In(ids)})
	if err != nil {
		return nil, err
	}
	byBlock := map[string]map[string]models.TribeBlockAttendance{}
	for _, r := range rows {
		if byBlock[r.TribeBlockID] == nil {
			byBlock[r.TribeBlockID] = map[string]models.TribeBlockAttendance{}
		}
		byBlock[r.TribeBlockID][r.UserID] = r
	}
	users, err := s.store.UsersByIDs(ctx, userIDsOf(members))
	if err != nil {
		return nil, err
	}
	for i := range blocks {
		b := &blocks[i]
		dto := s.blockDTO(b, members, byBlock[b.ID], byBlock[b.ID][me].Status, loc)
		for j := range dto.Attendance {
			u := users[dto.Attendance[j].UserID]
			dto.Attendance[j].User = u.Short()
		}
		out = append(out, dto)
	}
	return out, nil
}

// windowFromQuery: date (YYYY-MM-DD) tính theo múi giờ người xem, hoặc khoảng from/to.
func windowFromQuery(date, from, to string, loc *time.Location) (utils.TimeRange, error) {
	if date == "" && from == "" {
		date = utils.TodayIn(loc)
	}
	if date != "" {
		if _, err := utils.ParseDate(date); err != nil {
			return utils.TimeRange{}, utils.BadRequest("invalid_date", "date phải có dạng YYYY-MM-DD")
		}
		return utils.DayWindow(date, loc), nil
	}
	f, err1 := utils.ParseDate(from)
	t, err2 := utils.ParseDate(to)
	if err1 != nil || err2 != nil || t.Before(f) || t.Sub(f) > 62*24*time.Hour {
		return utils.TimeRange{}, utils.BadRequest("invalid_date", "from/to phải có dạng YYYY-MM-DD, to >= from và cách nhau tối đa 62 ngày")
	}
	return utils.TimeRange{Start: utils.DayWindow(from, loc).Start, End: utils.DayWindow(to, loc).End}, nil
}

// ListBlocks (COM-08): hoạt động của nhóm trong ngày người xem đang chọn.
func (s *TribeService) ListBlocks(ctx context.Context, me, tribeID, date, from, to string) ([]TribeBlockDTO, error) {
	tribe, _, err := s.membership(ctx, tribeID, me)
	if err != nil {
		return nil, err
	}
	loc := s.userLoc(ctx, me)
	w, err := windowFromQuery(date, from, to, loc)
	if err != nil {
		return nil, err
	}
	blocks, err := s.blocksInWindow(ctx, bson.M{"tribe_id": tribe.ID}, w)
	if err != nil {
		return nil, err
	}
	members, err := s.attendeesOf(ctx, tribe.ID)
	if err != nil {
		return nil, err
	}
	return s.fillAttendance(ctx, blocks, members, me, loc)
}

// loadBlock lấy hoạt động và kiểm tra người dùng có trong nhóm của hoạt động đó.
func (s *TribeService) loadBlock(ctx context.Context, me, blockID string) (*models.TribeBlock, *models.Tribe, *models.TribeAttendee, error) {
	b, err := repository.FindOne[models.TribeBlock](ctx, s.store.TribeBlocks, repository.ByID(blockID))
	if err != nil {
		return nil, nil, nil, err
	}
	if b == nil {
		return nil, nil, nil, utils.NotFound("not_found_item", "Không tìm thấy hoạt động nhóm")
	}
	tribe, att, err := s.membership(ctx, b.TribeID, me)
	if err != nil {
		return nil, nil, nil, err
	}
	return b, tribe, att, nil
}

func (s *TribeService) GetBlock(ctx context.Context, me, blockID string) (*TribeBlockDTO, error) {
	b, tribe, _, err := s.loadBlock(ctx, me, blockID)
	if err != nil {
		return nil, err
	}
	members, err := s.attendeesOf(ctx, tribe.ID)
	if err != nil {
		return nil, err
	}
	list, err := s.fillAttendance(ctx, []models.TribeBlock{*b}, members, me, s.userLoc(ctx, me))
	if err != nil {
		return nil, err
	}
	list[0].TribeName, list[0].TribeColor = tribe.Name, tribe.BackgroundColor
	return &list[0], nil
}

// TribeBlockInput: giờ gửi lên theo UTC. Có thể gửi một trong hai cách:
// date + start_time + end_time (đúng như cột trong bảng), hoặc start_utc + end_utc dạng RFC3339.
type TribeBlockInput struct {
	Task        *string `json:"task"`
	Description *string `json:"description"`
	Date        string  `json:"date"`
	StartTime   string  `json:"start_time"`
	EndTime     string  `json:"end_time"`
	StartUTC    string  `json:"start_utc"`
	EndUTC      string  `json:"end_utc"`
	ColorCode   *string `json:"color_code"`
	Remind      *int    `json:"remind"`
}

func (in *TribeBlockInput) hasTime() bool {
	return in.StartUTC != "" || in.Date != "" || in.StartTime != ""
}

// parseRange đổi dữ liệu nhập thành (date, start_time, end_time) theo UTC.
func (in *TribeBlockInput) parseRange() (string, string, string, utils.TimeRange, error) {
	bad := utils.BadRequest("invalid_time", "Thời gian không hợp lệ: gửi date/start_time/end_time (UTC) hoặc start_utc/end_utc (RFC3339)")
	var r utils.TimeRange
	if in.StartUTC != "" {
		st, err1 := time.Parse(time.RFC3339, in.StartUTC)
		en, err2 := time.Parse(time.RFC3339, in.EndUTC)
		if err1 != nil || err2 != nil {
			return "", "", "", r, bad
		}
		st, en = st.UTC().Truncate(time.Minute), en.UTC().Truncate(time.Minute)
		r = utils.TimeRange{Start: st, End: en}
		if !en.After(st) {
			return "", "", "", r, utils.BadRequest("invalid_time", "Giờ kết thúc phải sau giờ bắt đầu")
		}
	} else {
		if _, err := utils.ParseDate(in.Date); err != nil {
			return "", "", "", r, bad
		}
		st, err1 := utils.NormalizeClock(in.StartTime)
		en, err2 := utils.NormalizeClock(in.EndTime)
		if err1 != nil || err2 != nil {
			return "", "", "", r, bad
		}
		r = utils.UTCRange(in.Date, st, en)
	}
	if r.End.Sub(r.Start) < 5*time.Minute {
		return "", "", "", r, utils.BadRequest("duration_too_short", "Hoạt động phải dài ít nhất 5 phút")
	}
	if r.End.Sub(r.Start) >= 24*time.Hour {
		return "", "", "", r, utils.BadRequest("duration_too_long", "Hoạt động nhóm phải ngắn hơn 24 giờ")
	}
	return r.Start.Format(utils.DateLayout), r.Start.Format(utils.ClockLayout), r.End.Format(utils.ClockLayout), r, nil
}

func validateTaskText(task string, desc *string) (string, *string, error) {
	task = strings.TrimSpace(task)
	if utils.Len(task) < 2 || utils.Len(task) > 100 {
		return "", nil, utils.BadRequest("invalid_task", "Tên hoạt động phải từ 2 đến 100 ký tự")
	}
	desc = utils.TrimPtr(desc)
	if desc != nil && utils.Len(*desc) > 300 {
		return "", nil, utils.BadRequest("description_too_long", "Ghi chú tối đa 300 ký tự")
	}
	return task, desc, nil
}

// CreateBlock (COM-07): trưởng hoặc phó nhóm tạo hoạt động. Người tạo mặc định tham gia,
// những người khác ở trạng thái chờ và nhận thông báo mời.
func (s *TribeService) CreateBlock(ctx context.Context, me, tribeID string, in TribeBlockInput) (map[string]any, error) {
	tribe, att, err := s.membership(ctx, tribeID, me)
	if err != nil {
		return nil, err
	}
	if att.Role == models.TribeRoleMember {
		return nil, utils.ErrNotAllowed
	}
	if in.Task == nil {
		return nil, utils.BadRequest("invalid_task", "Thiếu tên hoạt động")
	}
	task, desc, err := validateTaskText(*in.Task, in.Description)
	if err != nil {
		return nil, err
	}
	date, st, en, r, err := in.parseRange()
	if err != nil {
		return nil, err
	}
	if r.Start.Before(time.Now().UTC().Add(-time.Minute)) {
		return nil, utils.BadRequest("past_time", "Không thể tạo hoạt động trong quá khứ")
	}
	color := "#3A86FF"
	if tribe.BackgroundColor != nil {
		color = *tribe.BackgroundColor
	}
	if in.ColorCode != nil && *in.ColorCode != "" {
		if !utils.IsHexColor(*in.ColorCode) {
			return nil, utils.BadRequest("invalid_color", "Mã màu phải có dạng #RRGGBB")
		}
		color = strings.ToUpper(*in.ColorCode)
	}
	remind := models.TribeBlockRemind
	if in.Remind != nil && utils.ContainsInt(models.RemindOptions, *in.Remind) {
		remind = *in.Remind
	}

	now := time.Now().UTC()
	block := models.TribeBlock{
		ID: uuid.NewString(), TribeID: tribe.ID, CreatedBy: me, Task: task, Description: desc,
		Date: date, StartTime: st, EndTime: en, ColorCode: color, Remind: remind, CreatedAt: now,
	}
	if _, err := s.store.TribeBlocks.InsertOne(ctx, block); err != nil {
		return nil, err
	}
	members, err := s.attendeesOf(ctx, tribe.ID)
	if err != nil {
		return nil, err
	}
	rows := make([]any, 0, len(members))
	for _, m := range members {
		status := models.AttendancePending
		if m.UserID == me {
			status = models.AttendanceAccepted
		}
		rows = append(rows, models.TribeBlockAttendance{ID: uuid.NewString(), TribeBlockID: block.ID, UserID: m.UserID, Status: status, UpdatedAt: now})
	}
	if _, err := s.store.TribeBlockAttendance.InsertMany(ctx, rows); err != nil {
		return nil, err
	}
	s.notify(ctx, tribe, without(userIDsOf(members), me), me, models.KindTribeNewBlock, models.NotiGroupSchedule,
		map[string]string{"task": task}, block.ID, models.RefTribeBlock)

	dto, err := s.GetBlock(ctx, me, block.ID)
	if err != nil {
		return nil, err
	}
	// Báo trước cho người tạo những ai đang bận đúng khung giờ này
	busy, _ := s.busyMembers(ctx, tribe, members, r)
	return map[string]any{"block": dto, "busy_member_ids": busy}, nil
}

// UpdateBlock (COM-09): sửa hoạt động. Đổi giờ thì mọi người (trừ người sửa) phải xác nhận lại.
func (s *TribeService) UpdateBlock(ctx context.Context, me, blockID string, in TribeBlockInput) (*TribeBlockDTO, error) {
	b, tribe, att, err := s.loadBlock(ctx, me, blockID)
	if err != nil {
		return nil, err
	}
	if att.Role == models.TribeRoleMember {
		return nil, utils.ErrNotAllowed
	}
	oldRange := utils.UTCRange(b.Date, b.StartTime, b.EndTime)
	if !oldRange.End.After(time.Now().UTC()) {
		return nil, utils.BadRequest("block_ended", "Hoạt động đã kết thúc, không thể sửa")
	}

	task := b.Task
	if in.Task != nil {
		task = *in.Task
	}
	desc := b.Description
	if in.Description != nil {
		desc = in.Description
	}
	task, desc, err = validateTaskText(task, desc)
	if err != nil {
		return nil, err
	}
	set := bson.M{"task": task, "description": desc}
	if in.ColorCode != nil && *in.ColorCode != "" {
		if !utils.IsHexColor(*in.ColorCode) {
			return nil, utils.BadRequest("invalid_color", "Mã màu phải có dạng #RRGGBB")
		}
		set["color_code"] = strings.ToUpper(*in.ColorCode)
	}

	timeChanged := false
	if in.hasTime() {
		date, st, en, r, err := in.parseRange()
		if err != nil {
			return nil, err
		}
		if !r.Start.Equal(oldRange.Start) || !r.End.Equal(oldRange.End) {
			if r.Start.Before(time.Now().UTC().Add(-time.Minute)) {
				return nil, utils.BadRequest("past_time", "Không thể dời hoạt động về quá khứ")
			}
			timeChanged = true
			set["date"], set["start_time"], set["end_time"] = date, st, en
		}
	}
	if _, err := s.store.TribeBlocks.UpdateOne(ctx, repository.ByID(b.ID), bson.M{"$set": set}); err != nil {
		return nil, err
	}

	members, err := s.attendeesOf(ctx, tribe.ID)
	if err != nil {
		return nil, err
	}
	kind := models.KindTribeBlockUpdated
	if timeChanged {
		kind = models.KindTribeBlockRescheduled
		now := time.Now().UTC()
		if _, err := s.store.TribeBlockAttendance.UpdateMany(ctx,
			bson.M{"tribe_block_id": b.ID, "user_id": bson.M{"$ne": me}},
			bson.M{"$set": bson.M{"status": models.AttendancePending, "updated_at": now}}); err != nil {
			return nil, err
		}
		if err := s.upsertAttendance(ctx, b.ID, me, models.AttendanceAccepted); err != nil {
			return nil, err
		}
	}
	s.notify(ctx, tribe, without(userIDsOf(members), me), me, kind, models.NotiGroupSchedule,
		map[string]string{"task": task}, b.ID, models.RefTribeBlock)
	return s.GetBlock(ctx, me, b.ID)
}

// DeleteBlock (COM-10): xoá điểm danh, xoá hoạt động, báo huỷ cho các thành viên.
func (s *TribeService) DeleteBlock(ctx context.Context, me, blockID string) error {
	b, tribe, att, err := s.loadBlock(ctx, me, blockID)
	if err != nil {
		return err
	}
	if att.Role == models.TribeRoleMember {
		return utils.ErrNotAllowed
	}
	if _, err := s.store.TribeBlockAttendance.DeleteMany(ctx, bson.M{"tribe_block_id": b.ID}); err != nil {
		return err
	}
	if _, err := s.store.TribeBlocks.DeleteOne(ctx, repository.ByID(b.ID)); err != nil {
		return err
	}
	members, _ := s.attendeesOf(ctx, tribe.ID)
	// Hoạt động đã bị xoá nên không gắn reference_id, app dựa vào tribe_id trong args để mở nhóm
	s.notify(ctx, tribe, without(userIDsOf(members), me), me, models.KindTribeBlockCancelled, models.NotiGroupSchedule,
		map[string]string{"task": b.Task}, "", models.RefTribeBlock)
	return nil
}

func (s *TribeService) upsertAttendance(ctx context.Context, blockID, userID, status string) error {
	now := time.Now().UTC()
	res, err := s.store.TribeBlockAttendance.UpdateOne(ctx,
		bson.M{"tribe_block_id": blockID, "user_id": userID},
		bson.M{"$set": bson.M{"status": status, "updated_at": now}})
	if err != nil {
		return err
	}
	if res.MatchedCount == 0 {
		_, err = s.store.TribeBlockAttendance.InsertOne(ctx, models.TribeBlockAttendance{
			ID: uuid.NewString(), TribeBlockID: blockID, UserID: userID, Status: status, UpdatedAt: now,
		})
	}
	return err
}

// Respond (COM-19): thành viên bấm Tham gia hoặc Không tham gia, báo về cho trưởng và phó nhóm.
func (s *TribeService) Respond(ctx context.Context, me, blockID, status string) (*TribeBlockDTO, error) {
	if status != models.AttendanceAccepted && status != models.AttendanceDeclined {
		return nil, utils.BadRequest("invalid_status", "status chỉ nhận accepted hoặc declined")
	}
	b, tribe, _, err := s.loadBlock(ctx, me, blockID)
	if err != nil {
		return nil, err
	}
	if !utils.UTCRange(b.Date, b.StartTime, b.EndTime).End.After(time.Now().UTC()) {
		return nil, utils.BadRequest("block_ended", "Hoạt động đã kết thúc")
	}
	current, err := repository.FindOne[models.TribeBlockAttendance](ctx, s.store.TribeBlockAttendance, bson.M{"tribe_block_id": b.ID, "user_id": me})
	if err != nil {
		return nil, err
	}
	if current == nil || current.Status != status {
		if err := s.upsertAttendance(ctx, b.ID, me, status); err != nil {
			return nil, err
		}
		members, _ := s.attendeesOf(ctx, tribe.ID)
		managers := []string{}
		for _, m := range members {
			if m.Role != models.TribeRoleMember && m.UserID != me {
				managers = append(managers, m.UserID)
			}
		}
		kind := models.KindTribeResponseAccepted
		if status == models.AttendanceDeclined {
			kind = models.KindTribeResponseDeclined
		}
		s.notify(ctx, tribe, managers, me, kind, models.NotiGroupSchedule,
			map[string]string{"task": b.Task}, b.ID, models.RefTribeBlockResponse)
	}
	return s.GetBlock(ctx, me, b.ID)
}

// ---------------------------------------------------------------------------
// Giờ rảnh của cả nhóm
// ---------------------------------------------------------------------------

// MemberBusy là các khoảng bận (UTC) của một thành viên. Chỉ trả khoảng thời gian,
// không trả nội dung lịch riêng để giữ quyền riêng tư.
type MemberBusy struct {
	UserID   string            `json:"user_id"`
	NickName string            `json:"nick_name"`
	Timezone string            `json:"timezone"`
	Busy     []utils.TimeRange `json:"busy"`
}

type Segment struct {
	Start       time.Time `json:"start"`
	End         time.Time `json:"end"`
	BusyUserIDs []string  `json:"busy_user_ids"`
	BusyCount   int       `json:"busy_count"`
}

type FreeWindow struct {
	Start      time.Time `json:"start"`
	End        time.Time `json:"end"`
	StartLocal string    `json:"start_local"`
	EndLocal   string    `json:"end_local"`
	Minutes    int       `json:"minutes"`
}

// busyByMember tính khoảng bận của từng người trong cửa sổ w: lịch cá nhân của họ
// và các hoạt động của nhóm khác mà họ đã nhận tham gia (không tính hoạt động của chính nhóm này).
func (s *TribeService) busyByMember(ctx context.Context, tribe *models.Tribe, members []models.TribeAttendee, w utils.TimeRange) ([]MemberBusy, error) {
	ids := userIDsOf(members)
	users, err := s.store.UsersByIDs(ctx, ids)
	if err != nil {
		return nil, err
	}
	// Lấy rộng ra hai ngày mỗi phía vì mỗi người một múi giờ
	personal, err := repository.FindMany[models.Timeblock](ctx, s.store.Timeblocks, bson.M{
		"user_id": repository.In(ids),
		"date": bson.M{
			"$gte": w.Start.AddDate(0, 0, -2).Format(utils.DateLayout),
			"$lte": w.End.AddDate(0, 0, 2).Format(utils.DateLayout),
		},
	})
	if err != nil {
		return nil, err
	}
	accepted, err := repository.FindMany[models.TribeBlockAttendance](ctx, s.store.TribeBlockAttendance, bson.M{
		"user_id": repository.In(ids), "status": models.AttendanceAccepted,
	})
	if err != nil {
		return nil, err
	}
	blockIDs := make([]string, 0, len(accepted))
	for _, a := range accepted {
		blockIDs = append(blockIDs, a.TribeBlockID)
	}
	otherBlocks := []models.TribeBlock{}
	if len(blockIDs) > 0 {
		otherBlocks, err = s.blocksInWindow(ctx, bson.M{"_id": repository.In(blockIDs), "tribe_id": bson.M{"$ne": tribe.ID}}, w)
		if err != nil {
			return nil, err
		}
	}
	blockByID := map[string]models.TribeBlock{}
	for _, b := range otherBlocks {
		blockByID[b.ID] = b
	}

	out := make([]MemberBusy, 0, len(members))
	for _, m := range members {
		u := users[m.UserID]
		mb := MemberBusy{UserID: m.UserID, NickName: u.NickName, Timezone: u.Timezone, Busy: []utils.TimeRange{}}
		loc := utils.LoadLocation(u.Timezone)
		for _, t := range personal {
			if t.UserID != m.UserID {
				continue
			}
			if c, ok := utils.LocalRange(t.Date, t.StartTime, t.EndTime, loc).Clip(w); ok {
				mb.Busy = append(mb.Busy, c)
			}
		}
		for _, a := range accepted {
			if a.UserID != m.UserID {
				continue
			}
			if b, ok := blockByID[a.TribeBlockID]; ok {
				if c, ok := utils.UTCRange(b.Date, b.StartTime, b.EndTime).Clip(w); ok {
					mb.Busy = append(mb.Busy, c)
				}
			}
		}
		sort.Slice(mb.Busy, func(i, j int) bool { return mb.Busy[i].Start.Before(mb.Busy[j].Start) })
		out = append(out, mb)
	}
	return out, nil
}

func (s *TribeService) busyMembers(ctx context.Context, tribe *models.Tribe, members []models.TribeAttendee, r utils.TimeRange) ([]string, error) {
	list, err := s.busyByMember(ctx, tribe, members, r)
	if err != nil {
		return nil, err
	}
	out := []string{}
	for _, m := range list {
		if len(m.Busy) > 0 {
			out = append(out, m.UserID)
		}
	}
	return out, nil
}

// Availability (COM-07, COM-08): chia ngày đang xem thành các đoạn, mỗi đoạn biết ai bận,
// và gợi ý các khoảng từ 30 phút trở lên mà cả nhóm đều rảnh.
func (s *TribeService) Availability(ctx context.Context, me, tribeID, date string) (map[string]any, error) {
	tribe, _, err := s.membership(ctx, tribeID, me)
	if err != nil {
		return nil, err
	}
	viewer, err := s.store.UserByID(ctx, me)
	if err != nil || viewer == nil {
		return nil, utils.ErrTribeMissing
	}
	loc := utils.LoadLocation(viewer.Timezone)
	w, err := windowFromQuery(date, "", "", loc)
	if err != nil {
		return nil, err
	}
	if date == "" {
		date = utils.TodayIn(loc)
	}
	members, err := s.attendeesOf(ctx, tribe.ID)
	if err != nil {
		return nil, err
	}
	busy, err := s.busyByMember(ctx, tribe, members, w)
	if err != nil {
		return nil, err
	}

	// Gom mọi mốc thời gian rồi chia đoạn
	points := map[int64]time.Time{w.Start.Unix(): w.Start, w.End.Unix(): w.End}
	for _, m := range busy {
		for _, r := range m.Busy {
			points[r.Start.Unix()], points[r.End.Unix()] = r.Start, r.End
		}
	}
	sorted := make([]time.Time, 0, len(points))
	for _, p := range points {
		sorted = append(sorted, p)
	}
	sort.Slice(sorted, func(i, j int) bool { return sorted[i].Before(sorted[j]) })

	segments := []Segment{}
	for i := 0; i+1 < len(sorted); i++ {
		piece := utils.TimeRange{Start: sorted[i], End: sorted[i+1]}
		ids := []string{}
		for _, m := range busy {
			for _, r := range m.Busy {
				if r.Overlaps(piece) {
					ids = append(ids, m.UserID)
					break
				}
			}
		}
		// Gộp đoạn liền kề có cùng tập người bận
		if n := len(segments); n > 0 && sameSet(segments[n-1].BusyUserIDs, ids) {
			segments[n-1].End = piece.End
			continue
		}
		segments = append(segments, Segment{Start: piece.Start, End: piece.End, BusyUserIDs: ids, BusyCount: len(ids)})
	}

	free := []FreeWindow{}
	for _, sg := range segments {
		if sg.BusyCount == 0 && sg.End.Sub(sg.Start) >= 30*time.Minute {
			free = append(free, FreeWindow{
				Start: sg.Start, End: sg.End,
				StartLocal: sg.Start.In(loc).Format("15:04"), EndLocal: sg.End.In(loc).Format("15:04"),
				Minutes: int(sg.End.Sub(sg.Start).Minutes()),
			})
		}
	}
	return map[string]any{
		"date": date, "timezone": viewer.Timezone, "window": w,
		"members": busy, "segments": segments, "free_windows": free,
	}, nil
}

func sameSet(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	m := map[string]bool{}
	for _, x := range a {
		m[x] = true
	}
	for _, x := range b {
		if !m[x] {
			return false
		}
	}
	return true
}

// BlocksForUser trả hoạt động nhóm hiện trên lịch cá nhân của người dùng trong cửa sổ w:
// gồm hoạt động đã tham gia và đang chờ xác nhận, hoạt động đã từ chối thì ẩn.
func (s *TribeService) BlocksForUser(ctx context.Context, me string, w utils.TimeRange, loc *time.Location) ([]TribeBlockDTO, error) {
	mine, err := repository.FindMany[models.TribeAttendee](ctx, s.store.TribeAttendees, bson.M{"user_id": me})
	if err != nil {
		return nil, err
	}
	out := []TribeBlockDTO{}
	if len(mine) == 0 {
		return out, nil
	}
	tribes, err := repository.FindMany[models.Tribe](ctx, s.store.Tribes, bson.M{"_id": repository.In(userIDsOfTribes(mine)), "deleted_at": nil})
	if err != nil {
		return nil, err
	}
	byID := map[string]models.Tribe{}
	ids := make([]string, 0, len(tribes))
	for _, t := range tribes {
		byID[t.ID] = t
		ids = append(ids, t.ID)
	}
	blocks, err := s.blocksInWindow(ctx, bson.M{"tribe_id": repository.In(ids)}, w)
	if err != nil {
		return nil, err
	}
	status, err := s.statusMap(ctx, blocks, me)
	if err != nil {
		return nil, err
	}
	for i := range blocks {
		b := &blocks[i]
		if status[b.ID] == models.AttendanceDeclined {
			continue
		}
		dto := s.blockDTO(b, nil, nil, status[b.ID], loc)
		t := byID[b.TribeID]
		dto.TribeName, dto.TribeColor = t.Name, t.BackgroundColor
		out = append(out, dto)
	}
	return out, nil
}
