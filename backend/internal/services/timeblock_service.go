package services

import (
	"context"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"timetribe-backend/internal/models"
	"timetribe-backend/internal/repository"
	"timetribe-backend/internal/utils"
)

type TimeblockService struct {
	store  *repository.Store
	tribes *TribeService
}

func NewTimeblockService(store *repository.Store, tribes *TribeService) *TimeblockService {
	return &TimeblockService{store: store, tribes: tribes}
}

// TimeblockInput là dữ liệu tạo/sửa lịch cá nhân. repeating_dates là các ngày muốn nhân bản.
type TimeblockInput struct {
	Task           string   `json:"task"`
	Description    *string  `json:"description"`
	Date           string   `json:"date"`
	StartTime      string   `json:"start_time"`
	EndTime        string   `json:"end_time"`
	ColorCode      string   `json:"color_code"`
	Remind         *int     `json:"remind"`
	RepeatingDates []string `json:"repeating_dates"`
}

func (s *TimeblockService) loc(ctx context.Context, userID string) *time.Location {
	u, err := s.store.UserByID(ctx, userID)
	if err != nil || u == nil {
		return utils.LoadLocation(models.DefaultTimezone)
	}
	return utils.LoadLocation(u.Timezone)
}

// validate kiểm tra theo đúng quy tắc của AddEditTimeblockScreen: tên 2-100 ký tự,
// không chọn ngày quá khứ, kết thúc sau bắt đầu ít nhất 5 phút, ghi chú tối đa 300 ký tự.
func (s *TimeblockService) validate(in *TimeblockInput, today string) (*models.Timeblock, error) {
	task, desc, err := validateTaskText(in.Task, in.Description)
	if err != nil {
		return nil, err
	}
	if _, err := utils.ParseDate(in.Date); err != nil {
		return nil, utils.BadRequest("invalid_date", "date phải có dạng YYYY-MM-DD")
	}
	if in.Date < today {
		return nil, utils.BadRequest("past_date", "Không thể chọn ngày trong quá khứ")
	}
	st, err1 := utils.NormalizeClock(in.StartTime)
	en, err2 := utils.NormalizeClock(in.EndTime)
	if err1 != nil || err2 != nil {
		return nil, utils.BadRequest("invalid_time", "start_time/end_time phải có dạng HH:mm hoặc HH:mm:ss")
	}
	if utils.ClockMinutes(en)-utils.ClockMinutes(st) < 5 {
		return nil, utils.BadRequest("duration_too_short", "Giờ kết thúc phải sau giờ bắt đầu ít nhất 5 phút")
	}
	color := strings.ToUpper(strings.TrimSpace(in.ColorCode))
	if color == "" {
		color = "#3A86FF"
	}
	if !utils.IsHexColor(color) {
		return nil, utils.BadRequest("invalid_color", "Mã màu phải có dạng #RRGGBB")
	}
	remind := 15
	if in.Remind != nil {
		if !utils.ContainsInt(models.RemindOptions, *in.Remind) {
			return nil, utils.BadRequest("invalid_remind", "remind chỉ nhận 0, 5, 10, 15, 30 hoặc 60")
		}
		remind = *in.Remind
	}
	return &models.Timeblock{Task: task, Description: desc, Date: in.Date, StartTime: st, EndTime: en, ColorCode: color, Remind: remind}, nil
}

// conflictsOn trả các lịch cá nhân trùng giờ trong cùng một ngày.
func (s *TimeblockService) conflictsOn(ctx context.Context, userID, date, start, end, ignoreID string) ([]models.Timeblock, error) {
	list, err := repository.FindMany[models.Timeblock](ctx, s.store.Timeblocks, bson.M{"user_id": userID, "date": date})
	if err != nil {
		return nil, err
	}
	st, en := utils.ClockMinutes(start), utils.ClockMinutes(end)
	out := []models.Timeblock{}
	for _, t := range list {
		if t.ID == ignoreID {
			continue
		}
		if st < utils.ClockMinutes(t.EndTime) && en > utils.ClockMinutes(t.StartTime) {
			out = append(out, t)
		}
	}
	return out, nil
}

// List trả lịch cá nhân theo ngày (date) hoặc khoảng ngày (from, to).
func (s *TimeblockService) List(ctx context.Context, userID, date, from, to string) ([]models.Timeblock, error) {
	filter := bson.M{"user_id": userID}
	switch {
	case date != "":
		filter["date"] = date
	case from != "" && to != "":
		filter["date"] = bson.M{"$gte": from, "$lte": to}
	default:
		filter["date"] = utils.TodayIn(s.loc(ctx, userID))
	}
	return repository.FindMany[models.Timeblock](ctx, s.store.Timeblocks, filter,
		options.Find().SetSort(bson.D{{Key: "date", Value: 1}, {Key: "start_time", Value: 1}}))
}

// CountByDay đếm số hoạt động cá nhân + nhóm mỗi ngày, dùng cho huy hiệu trên CalendarPanel.
func (s *TimeblockService) CountByDay(ctx context.Context, userID, from, to string) (map[string]int, error) {
	if _, err := utils.ParseDate(from); err != nil {
		return nil, utils.BadRequest("invalid_date", "from/to phải có dạng YYYY-MM-DD")
	}
	if _, err := utils.ParseDate(to); err != nil || to < from {
		return nil, utils.BadRequest("invalid_date", "from/to phải có dạng YYYY-MM-DD và to >= from")
	}
	list, err := s.List(ctx, userID, "", from, to)
	if err != nil {
		return nil, err
	}
	out := map[string]int{}
	for _, t := range list {
		out[t.Date]++
	}
	loc := s.loc(ctx, userID)
	w := utils.TimeRange{Start: utils.DayWindow(from, loc).Start, End: utils.DayWindow(to, loc).End}
	group, err := s.tribes.BlocksForUser(ctx, userID, w, loc)
	if err != nil {
		return nil, err
	}
	for _, b := range group {
		out[b.LocalDate]++
	}
	return out, nil
}

func (s *TimeblockService) Get(ctx context.Context, userID, id string) (*models.Timeblock, error) {
	t, err := repository.FindOne[models.Timeblock](ctx, s.store.Timeblocks, bson.M{"_id": id, "user_id": userID})
	if err != nil {
		return nil, err
	}
	if t == nil {
		return nil, utils.NotFound("not_found_item", "Không tìm thấy hoạt động")
	}
	return t, nil
}

// SaveResult: bản ghi chính, các bản nhân bản đã tạo và các ngày bị bỏ qua (quá khứ hoặc trùng giờ).
type SaveResult struct {
	Timeblock    *models.Timeblock  `json:"timeblock"`
	Copies       []models.Timeblock `json:"copies"`
	SkippedDates []string           `json:"skipped_dates"`
}

// Create (PT-01): lưu hoạt động, nhân bản sang các ngày trong repeating_dates.
func (s *TimeblockService) Create(ctx context.Context, userID string, in TimeblockInput) (*SaveResult, error) {
	today := utils.TodayIn(s.loc(ctx, userID))
	t, err := s.validate(&in, today)
	if err != nil {
		return nil, err
	}
	conflicts, err := s.conflictsOn(ctx, userID, t.Date, t.StartTime, t.EndTime, "")
	if err != nil {
		return nil, err
	}
	if len(conflicts) > 0 {
		return nil, utils.Conflict("overlap", "Khung giờ này đã có hoạt động khác").WithDetails(conflicts)
	}
	t.ID, t.UserID, t.CreatedAt = uuid.NewString(), userID, time.Now().UTC()
	copies, skipped, err := s.makeCopies(ctx, t, in.RepeatingDates, today)
	if err != nil {
		return nil, err
	}
	t.RepeatingDates = copyDates(copies)
	if _, err := s.store.Timeblocks.InsertOne(ctx, t); err != nil {
		return nil, err
	}
	if err := s.insertCopies(ctx, copies); err != nil {
		return nil, err
	}
	return &SaveResult{Timeblock: t, Copies: copies, SkippedDates: skipped}, nil
}

// makeCopies tạo bản nhân bản cho từng ngày được chọn, bỏ qua ngày quá khứ, trùng ngày gốc
// hoặc đã có lịch đè giờ (giống DuplicateDatesSheet khoá các ngày đó).
func (s *TimeblockService) makeCopies(ctx context.Context, base *models.Timeblock, dates []string, today string) ([]models.Timeblock, []string, error) {
	copies, skipped := []models.Timeblock{}, []string{}
	seen := map[string]bool{base.Date: true}
	sort.Strings(dates)
	if len(dates) > 60 {
		return nil, nil, utils.BadRequest("too_many_dates", "Chỉ nhân bản tối đa 60 ngày một lần")
	}
	for _, d := range dates {
		if seen[d] {
			continue
		}
		seen[d] = true
		if _, err := utils.ParseDate(d); err != nil || d < today {
			skipped = append(skipped, d)
			continue
		}
		c, err := s.conflictsOn(ctx, base.UserID, d, base.StartTime, base.EndTime, "")
		if err != nil {
			return nil, nil, err
		}
		if len(c) > 0 {
			skipped = append(skipped, d)
			continue
		}
		cp := *base
		cp.ID, cp.Date, cp.RepeatingDates = uuid.NewString(), d, nil
		copies = append(copies, cp)
	}
	return copies, skipped, nil
}

func (s *TimeblockService) insertCopies(ctx context.Context, copies []models.Timeblock) error {
	if len(copies) == 0 {
		return nil
	}
	docs := make([]any, len(copies))
	for i := range copies {
		docs[i] = copies[i]
	}
	_, err := s.store.Timeblocks.InsertMany(ctx, docs)
	return err
}

func copyDates(copies []models.Timeblock) []string {
	if len(copies) == 0 {
		return nil
	}
	out := make([]string, len(copies))
	for i, c := range copies {
		out[i] = c.Date
	}
	return out
}

// Update (PT-02): chỉ sửa được hoạt động từ hôm nay trở đi, không đè giờ hoạt động khác,
// có thể chọn thêm ngày nhân bản.
func (s *TimeblockService) Update(ctx context.Context, userID, id string, in TimeblockInput) (*SaveResult, error) {
	old, err := s.Get(ctx, userID, id)
	if err != nil {
		return nil, err
	}
	today := utils.TodayIn(s.loc(ctx, userID))
	if old.Date < today {
		return nil, utils.BadRequest("past_date", "Không thể sửa hoạt động đã qua")
	}
	t, err := s.validate(&in, today)
	if err != nil {
		return nil, err
	}
	conflicts, err := s.conflictsOn(ctx, userID, t.Date, t.StartTime, t.EndTime, id)
	if err != nil {
		return nil, err
	}
	if len(conflicts) > 0 {
		return nil, utils.Conflict("overlap", "Khung giờ này đã có hoạt động khác").WithDetails(conflicts)
	}
	t.ID, t.UserID, t.CreatedAt = old.ID, userID, old.CreatedAt
	copies, skipped, err := s.makeCopies(ctx, t, in.RepeatingDates, today)
	if err != nil {
		return nil, err
	}
	t.RepeatingDates = append(old.RepeatingDates, copyDates(copies)...)
	if len(t.RepeatingDates) == 0 {
		t.RepeatingDates = nil
	}
	if _, err := s.store.Timeblocks.ReplaceOne(ctx, repository.ByID(id), t); err != nil {
		return nil, err
	}
	if err := s.insertCopies(ctx, copies); err != nil {
		return nil, err
	}
	return &SaveResult{Timeblock: t, Copies: copies, SkippedDates: skipped}, nil
}

// Delete (PT-04).
func (s *TimeblockService) Delete(ctx context.Context, userID, id string) error {
	res, err := s.store.Timeblocks.DeleteOne(ctx, bson.M{"_id": id, "user_id": userID})
	if err != nil {
		return err
	}
	if res.DeletedCount == 0 {
		return utils.NotFound("not_found_item", "Không tìm thấy hoạt động")
	}
	return nil
}

// Schedule (PT-03): dữ liệu cho trang chủ Lịch cá nhân theo bộ lọc all, personal, group.
func (s *TimeblockService) Schedule(ctx context.Context, userID, date, filter string) (map[string]any, error) {
	loc := s.loc(ctx, userID)
	if date == "" {
		date = utils.TodayIn(loc)
	}
	if _, err := utils.ParseDate(date); err != nil {
		return nil, utils.BadRequest("invalid_date", "date phải có dạng YYYY-MM-DD")
	}
	if filter == "" {
		filter = "all"
	}
	personal := []models.Timeblock{}
	group := []TribeBlockDTO{}
	var err error
	if filter == "all" || filter == "personal" {
		if personal, err = s.List(ctx, userID, date, "", ""); err != nil {
			return nil, err
		}
	}
	if filter == "all" || filter == "group" {
		if group, err = s.tribes.BlocksForUser(ctx, userID, utils.DayWindow(date, loc), loc); err != nil {
			return nil, err
		}
	}
	return map[string]any{
		"date": date, "timezone": loc.String(), "filter": filter,
		"personal": personal, "group": group, "total": len(personal) + len(group),
	}, nil
}
