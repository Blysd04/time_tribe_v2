package services

import (
	"context"
	"mime/multipart"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/v2/bson"

	"timetribe-backend/internal/config"
	"timetribe-backend/internal/models"
	"timetribe-backend/internal/repository"
	"timetribe-backend/internal/utils"
)

// Bảng màu mặc định khi tạo nhóm, giống AppColors.palette ở front-end.
var tribePalette = []string{"#3A86FF", "#00B894", "#9B5DE5", "#FF007F", "#FFB703", "#FF7F50", "#0FA3B1", "#6C757D"}

const inviteAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

type TribeService struct {
	cfg      *config.Config
	store    *repository.Store
	notifier *NotificationService
	uploader *Uploader
}

func NewTribeService(cfg *config.Config, store *repository.Store, n *NotificationService, up *Uploader) *TribeService {
	return &TribeService{cfg: cfg, store: store, notifier: n, uploader: up}
}

// ---------------------------------------------------------------------------
// Kiểu dữ liệu trả về
// ---------------------------------------------------------------------------

// MemberDTO là một dòng tribe_attendees kèm thông tin người dùng.
type MemberDTO struct {
	models.TribeAttendee
	User models.AppUser `json:"user"`
}

// TribeDTO là bảng tribes kèm thành viên và vài số liệu cho màn hình danh sách nhóm.
type TribeDTO struct {
	models.Tribe
	InviteCode   string         `json:"invite_code"`
	InviteURL    string         `json:"invite_url"`
	MyRole       string         `json:"my_role"`
	MemberCount  int            `json:"member_count"`
	MaxMembers   int            `json:"max_members"`
	PendingCount int            `json:"pending_count"`
	NextBlock    *TribeBlockDTO `json:"next_block"`
	Members      []MemberDTO    `json:"members"`
}

// ---------------------------------------------------------------------------
// Hàm dùng chung
// ---------------------------------------------------------------------------

func (s *TribeService) inviteURL(code string) string {
	return strings.TrimRight(s.cfg.ShareBaseURL, "/") + "/tribe/" + code
}

// membership trả về nhóm (chưa giải tán) và dòng tribe_attendees của người dùng trong nhóm đó.
func (s *TribeService) membership(ctx context.Context, tribeID, userID string) (*models.Tribe, *models.TribeAttendee, error) {
	tribe, err := repository.FindOne[models.Tribe](ctx, s.store.Tribes, bson.M{"_id": tribeID, "deleted_at": nil})
	if err != nil {
		return nil, nil, err
	}
	if tribe == nil {
		return nil, nil, utils.ErrTribeMissing
	}
	me, err := repository.FindOne[models.TribeAttendee](ctx, s.store.TribeAttendees, bson.M{"tribe_id": tribeID, "user_id": userID})
	if err != nil {
		return nil, nil, err
	}
	if me == nil {
		return nil, nil, utils.ErrTribeMissing
	}
	return tribe, me, nil
}

// attendeesOf lấy thành viên của nhiều nhóm, sắp theo chức vụ rồi ngày vào nhóm.
func (s *TribeService) attendeesOf(ctx context.Context, tribeIDs ...string) ([]models.TribeAttendee, error) {
	list, err := repository.FindMany[models.TribeAttendee](ctx, s.store.TribeAttendees, bson.M{"tribe_id": repository.In(tribeIDs)})
	if err != nil {
		return nil, err
	}
	sort.SliceStable(list, func(i, j int) bool {
		ri, rj := models.RoleRank(list[i].Role), models.RoleRank(list[j].Role)
		if ri != rj {
			return ri < rj
		}
		return list[i].JoinedAt.Before(list[j].JoinedAt)
	})
	return list, nil
}

func userIDsOf(list []models.TribeAttendee) []string {
	ids := make([]string, len(list))
	for i, a := range list {
		ids[i] = a.UserID
	}
	return ids
}

func without(ids []string, exclude ...string) []string {
	out := make([]string, 0, len(ids))
outer:
	for _, id := range ids {
		for _, e := range exclude {
			if id == e {
				continue outer
			}
		}
		out = append(out, id)
	}
	return out
}

func (s *TribeService) nickName(ctx context.Context, userID string) string {
	u, err := s.store.UserByID(ctx, userID)
	if err != nil || u == nil {
		return "?"
	}
	return u.NickName
}

// notify gửi thông báo liên quan tới nhóm. Tham số luôn có tribe (tên) và tribe_id để app lọc theo nhóm.
func (s *TribeService) notify(ctx context.Context, tribe *models.Tribe, recipients []string, actorID, kind, typ string,
	args map[string]string, refID, refType string) {
	full := map[string]string{"tribe": tribe.Name, "tribe_id": tribe.ID}
	if actorID != "" {
		full["actor"] = s.nickName(ctx, actorID)
	}
	for k, v := range args {
		full[k] = v
	}
	in := NotifyInput{Recipients: recipients, Kind: kind, Type: typ, Args: full}
	if actorID != "" {
		in.CreatedBy = utils.Ptr(actorID)
	}
	if refID != "" {
		in.ReferenceID = utils.Ptr(refID)
	}
	if refType != "" {
		in.ReferenceType = utils.Ptr(refType)
	}
	s.notifier.Notify(ctx, in)
}

func (s *TribeService) buildDTO(ctx context.Context, tribe *models.Tribe, members []models.TribeAttendee, users map[string]models.User, me string) TribeDTO {
	dto := TribeDTO{
		Tribe: *tribe, InviteCode: tribe.InviteLink, InviteURL: s.inviteURL(tribe.InviteLink),
		MaxMembers: models.MaxMembersPerTribe, Members: []MemberDTO{},
	}
	for _, m := range members {
		if m.TribeID != tribe.ID {
			continue
		}
		u := users[m.UserID]
		dto.Members = append(dto.Members, MemberDTO{TribeAttendee: m, User: u.Short()})
		if m.UserID == me {
			dto.MyRole = m.Role
		}
	}
	dto.MemberCount = len(dto.Members)
	return dto
}

func (s *TribeService) countMyTribes(ctx context.Context, userID string) (int64, error) {
	return s.store.TribeAttendees.CountDocuments(ctx, bson.M{"user_id": userID})
}

// ---------------------------------------------------------------------------
// Quản lý nhóm
// ---------------------------------------------------------------------------

// List (COM-01): các nhóm đang tham gia, kèm thành viên, số hoạt động đang chờ mình trả lời
// và hoạt động sắp diễn ra gần nhất.
func (s *TribeService) List(ctx context.Context, me string) ([]TribeDTO, error) {
	mine, err := repository.FindMany[models.TribeAttendee](ctx, s.store.TribeAttendees, bson.M{"user_id": me})
	if err != nil {
		return nil, err
	}
	ids := userIDsOfTribes(mine)
	out := []TribeDTO{}
	if len(ids) == 0 {
		return out, nil
	}
	tribes, err := repository.FindMany[models.Tribe](ctx, s.store.Tribes, bson.M{"_id": repository.In(ids), "deleted_at": nil})
	if err != nil {
		return nil, err
	}
	members, err := s.attendeesOf(ctx, ids...)
	if err != nil {
		return nil, err
	}
	users, err := s.store.UsersByIDs(ctx, userIDsOf(members))
	if err != nil {
		return nil, err
	}

	// Hoạt động từ hôm qua (UTC) trở đi của các nhóm, đủ để tính "đang chờ" và "sắp tới"
	now := time.Now().UTC()
	blocks, err := repository.FindMany[models.TribeBlock](ctx, s.store.TribeBlocks, bson.M{
		"tribe_id": repository.In(ids), "date": bson.M{"$gte": now.AddDate(0, 0, -1).Format(utils.DateLayout)},
	})
	if err != nil {
		return nil, err
	}
	myStatus, err := s.statusMap(ctx, blocks, me)
	if err != nil {
		return nil, err
	}
	loc := s.userLoc(ctx, me)

	for i := range tribes {
		t := &tribes[i]
		dto := s.buildDTO(ctx, t, members, users, me)
		var next *models.TribeBlock
		var nextStart time.Time
		for j := range blocks {
			b := &blocks[j]
			if b.TribeID != t.ID {
				continue
			}
			r := utils.UTCRange(b.Date, b.StartTime, b.EndTime)
			if !r.End.After(now) {
				continue
			}
			if st, ok := myStatus[b.ID]; !ok || st == models.AttendancePending {
				dto.PendingCount++
			}
			if next == nil || r.Start.Before(nextStart) {
				next, nextStart = b, r.Start
			}
		}
		if next != nil {
			nb := s.blockDTO(next, nil, nil, myStatus[next.ID], loc)
			dto.NextBlock = &nb
		}
		out = append(out, dto)
	}
	sort.SliceStable(out, func(i, j int) bool { return out[i].CreatedAt.Before(out[j].CreatedAt) })
	return out, nil
}

func userIDsOfTribes(list []models.TribeAttendee) []string {
	ids := make([]string, len(list))
	for i, a := range list {
		ids[i] = a.TribeID
	}
	return ids
}

// Get trả chi tiết một nhóm (người xem phải là thành viên).
func (s *TribeService) Get(ctx context.Context, tribeID, me string) (*TribeDTO, error) {
	tribe, _, err := s.membership(ctx, tribeID, me)
	if err != nil {
		return nil, err
	}
	return s.detail(ctx, tribe, me)
}

func (s *TribeService) detail(ctx context.Context, tribe *models.Tribe, me string) (*TribeDTO, error) {
	members, err := s.attendeesOf(ctx, tribe.ID)
	if err != nil {
		return nil, err
	}
	users, err := s.store.UsersByIDs(ctx, userIDsOf(members))
	if err != nil {
		return nil, err
	}
	dto := s.buildDTO(ctx, tribe, members, users, me)
	return &dto, nil
}

func validateTribeName(raw string) (string, error) {
	name := strings.TrimSpace(raw)
	if name == "" {
		return "", utils.BadRequest("empty_name", "Tên nhóm không được để trống")
	}
	if utils.Len(name) > models.MaxTribeNameLength {
		return "", utils.BadRequest("name_too_long", "Tên nhóm tối đa 255 ký tự")
	}
	return name, nil
}

// Create (COM-03): tạo nhóm, sinh mã mời, người tạo là trưởng nhóm.
func (s *TribeService) Create(ctx context.Context, me, rawName string, color *string) (*TribeDTO, error) {
	name, err := validateTribeName(rawName)
	if err != nil {
		return nil, err
	}
	count, err := s.countMyTribes(ctx, me)
	if err != nil {
		return nil, err
	}
	if count >= models.MaxTribesPerUser {
		return nil, utils.Conflict("tribe_limit", "Bạn đã tham gia tối đa 5 nhóm")
	}
	bg := tribePalette[int(count)%len(tribePalette)]
	if color != nil && *color != "" {
		if !utils.IsHexColor(*color) {
			return nil, utils.BadRequest("invalid_color", "Mã màu phải có dạng #RRGGBB")
		}
		bg = strings.ToUpper(*color)
	}

	now := time.Now().UTC()
	tribe := models.Tribe{ID: uuid.NewString(), Name: name, CreatedBy: me, BackgroundColor: &bg, CreatedAt: now}
	// Mã mời là unique, trùng thì sinh lại
	for attempt := 0; ; attempt++ {
		tribe.InviteLink = utils.RandomCode(8, inviteAlphabet)
		_, err = s.store.Tribes.InsertOne(ctx, tribe)
		if err == nil {
			break
		}
		if !repository.IsDuplicateKey(err) || attempt >= 5 {
			return nil, err
		}
	}
	leader := models.TribeAttendee{ID: uuid.NewString(), TribeID: tribe.ID, UserID: me, Role: models.TribeRoleLeader, JoinedAt: now}
	if _, err := s.store.TribeAttendees.InsertOne(ctx, leader); err != nil {
		_, _ = s.store.Tribes.DeleteOne(ctx, repository.ByID(tribe.ID))
		return nil, err
	}
	return s.detail(ctx, &tribe, me)
}

// Join (COM-11): vào nhóm bằng link mời hoặc mã mời.
func (s *TribeService) Join(ctx context.Context, me, link string) (*TribeDTO, error) {
	code := strings.ToUpper(utils.LastPathSegment(link))
	if code == "" {
		return nil, utils.BadRequest("invalid_link", "Đường dẫn hoặc mã mời không hợp lệ")
	}
	tribe, err := repository.FindOne[models.Tribe](ctx, s.store.Tribes, bson.M{"invite_link": code, "deleted_at": nil})
	if err != nil {
		return nil, err
	}
	if tribe == nil {
		return nil, utils.NotFound("not_found", "Không tìm thấy nhóm với mã mời này")
	}
	exists, err := s.store.TribeAttendees.CountDocuments(ctx, bson.M{"tribe_id": tribe.ID, "user_id": me})
	if err != nil {
		return nil, err
	}
	if exists > 0 {
		return nil, utils.Conflict("already_member", "Bạn đã ở trong nhóm này rồi").WithDetails(map[string]string{"tribe_id": tribe.ID})
	}
	count, err := s.countMyTribes(ctx, me)
	if err != nil {
		return nil, err
	}
	if count >= models.MaxTribesPerUser {
		return nil, utils.Conflict("tribe_limit", "Bạn đã tham gia tối đa 5 nhóm")
	}
	members, err := s.attendeesOf(ctx, tribe.ID)
	if err != nil {
		return nil, err
	}
	if len(members) >= models.MaxMembersPerTribe {
		return nil, utils.Conflict("tribe_full", "Nhóm đã đủ 10 thành viên")
	}

	now := time.Now().UTC()
	att := models.TribeAttendee{ID: uuid.NewString(), TribeID: tribe.ID, UserID: me, Role: models.TribeRoleMember, JoinedAt: now}
	if _, err := s.store.TribeAttendees.InsertOne(ctx, att); err != nil {
		if repository.IsDuplicateKey(err) {
			return nil, utils.Conflict("already_member", "Bạn đã ở trong nhóm này rồi")
		}
		return nil, err
	}
	// Thành viên mới cần trả lời các hoạt động sắp tới của nhóm
	if err := s.addPendingForUpcoming(ctx, tribe.ID, me); err != nil {
		return nil, err
	}
	s.notify(ctx, tribe, userIDsOf(members), me, models.KindTribeMemberJoined, models.NotiTribeJoin, nil, tribe.ID, models.RefTribe)
	return s.detail(ctx, tribe, me)
}

func (s *TribeService) addPendingForUpcoming(ctx context.Context, tribeID, userID string) error {
	blocks, err := s.upcomingBlocks(ctx, tribeID)
	if err != nil {
		return err
	}
	now := time.Now().UTC()
	for _, b := range blocks {
		_, err := s.store.TribeBlockAttendance.InsertOne(ctx, models.TribeBlockAttendance{
			ID: uuid.NewString(), TribeBlockID: b.ID, UserID: userID, Status: models.AttendancePending, UpdatedAt: now,
		})
		if err != nil && !repository.IsDuplicateKey(err) {
			return err
		}
	}
	return nil
}

// upcomingBlocks trả các hoạt động chưa kết thúc của nhóm.
func (s *TribeService) upcomingBlocks(ctx context.Context, tribeID string) ([]models.TribeBlock, error) {
	now := time.Now().UTC()
	list, err := repository.FindMany[models.TribeBlock](ctx, s.store.TribeBlocks, bson.M{
		"tribe_id": tribeID, "date": bson.M{"$gte": now.AddDate(0, 0, -1).Format(utils.DateLayout)},
	})
	if err != nil {
		return nil, err
	}
	out := list[:0]
	for _, b := range list {
		if utils.UTCRange(b.Date, b.StartTime, b.EndTime).End.After(now) {
			out = append(out, b)
		}
	}
	return out, nil
}

// Rename (COM-05): chỉ trưởng nhóm được đổi tên.
func (s *TribeService) Rename(ctx context.Context, me, tribeID, rawName string) (*TribeDTO, error) {
	tribe, att, err := s.membership(ctx, tribeID, me)
	if err != nil {
		return nil, err
	}
	if att.Role != models.TribeRoleLeader {
		return nil, utils.ErrNotAllowed
	}
	name, err := validateTribeName(rawName)
	if err != nil {
		return nil, err
	}
	old := tribe.Name
	if old == name {
		return s.detail(ctx, tribe, me)
	}
	if _, err := s.store.Tribes.UpdateOne(ctx, repository.ByID(tribe.ID), bson.M{"$set": bson.M{"name": name}}); err != nil {
		return nil, err
	}
	members, _ := s.attendeesOf(ctx, tribe.ID)
	tribe.Name = name
	s.notify(ctx, tribe, without(userIDsOf(members), me), me, models.KindTribeRenamed, models.NotiTribeRole,
		map[string]string{"old": old, "new": name}, tribe.ID, models.RefTribe)
	return s.detail(ctx, tribe, me)
}

// UpdateAppearance (COM-04): trưởng hoặc phó nhóm đổi màu chủ đạo và ảnh nền.
func (s *TribeService) UpdateAppearance(ctx context.Context, me, tribeID string, color *string, image *multipart.FileHeader, removeImage bool) (*TribeDTO, error) {
	tribe, att, err := s.membership(ctx, tribeID, me)
	if err != nil {
		return nil, err
	}
	if att.Role == models.TribeRoleMember {
		return nil, utils.ErrNotAllowed
	}
	set := bson.M{}
	if color != nil && *color != "" {
		if !utils.IsHexColor(*color) {
			return nil, utils.BadRequest("invalid_color", "Mã màu phải có dạng #RRGGBB")
		}
		set["background_color"] = strings.ToUpper(*color)
	}
	if image != nil {
		url, err := s.uploader.UploadImage(ctx, image, "timetribe/tribes", tribe.ID, false)
		if err != nil {
			return nil, err
		}
		set["background_image_url"] = url
	} else if removeImage {
		set["background_image_url"] = nil
	}
	if len(set) == 0 {
		return nil, utils.BadRequest("validation_error", "Cần gửi background_color hoặc ảnh background_image")
	}
	if _, err := s.store.Tribes.UpdateOne(ctx, repository.ByID(tribe.ID), bson.M{"$set": set}); err != nil {
		return nil, err
	}
	tribe, _, err = s.membership(ctx, tribeID, me)
	if err != nil {
		return nil, err
	}
	return s.detail(ctx, tribe, me)
}

// Dissolve (COM-06): trưởng nhóm giải tán nhóm.
func (s *TribeService) Dissolve(ctx context.Context, me, tribeID string) error {
	tribe, att, err := s.membership(ctx, tribeID, me)
	if err != nil {
		return err
	}
	if att.Role != models.TribeRoleLeader {
		return utils.ErrNotAllowed
	}
	return s.dissolve(ctx, tribe, me)
}

// dissolve xoá mềm nhóm (ghi deleted_at), huỷ các hoạt động nhóm, xoá danh sách thành viên
// và báo cho mọi người còn lại.
func (s *TribeService) dissolve(ctx context.Context, tribe *models.Tribe, actor string) error {
	members, err := s.attendeesOf(ctx, tribe.ID)
	if err != nil {
		return err
	}
	now := time.Now().UTC()
	if _, err := s.store.Tribes.UpdateOne(ctx, repository.ByID(tribe.ID), bson.M{"$set": bson.M{"deleted_at": now}}); err != nil {
		return err
	}
	blocks, err := repository.FindMany[models.TribeBlock](ctx, s.store.TribeBlocks, bson.M{"tribe_id": tribe.ID})
	if err != nil {
		return err
	}
	if len(blocks) > 0 {
		ids := make([]string, len(blocks))
		for i, b := range blocks {
			ids[i] = b.ID
		}
		if _, err := s.store.TribeBlockAttendance.DeleteMany(ctx, bson.M{"tribe_block_id": repository.In(ids)}); err != nil {
			return err
		}
		if _, err := s.store.TribeBlocks.DeleteMany(ctx, bson.M{"tribe_id": tribe.ID}); err != nil {
			return err
		}
	}
	if _, err := s.store.TribeAttendees.DeleteMany(ctx, bson.M{"tribe_id": tribe.ID}); err != nil {
		return err
	}
	s.notify(ctx, tribe, without(userIDsOf(members), actor), actor, models.KindTribeDissolved, models.NotiTribeRole, nil, tribe.ID, models.RefTribe)
	return nil
}

// removeMember xoá người khỏi nhóm và xoá phản hồi của họ ở các hoạt động sắp tới.
func (s *TribeService) removeMember(ctx context.Context, tribeID, userID string) error {
	if _, err := s.store.TribeAttendees.DeleteOne(ctx, bson.M{"tribe_id": tribeID, "user_id": userID}); err != nil {
		return err
	}
	blocks, err := s.upcomingBlocks(ctx, tribeID)
	if err != nil || len(blocks) == 0 {
		return err
	}
	ids := make([]string, len(blocks))
	for i, b := range blocks {
		ids[i] = b.ID
	}
	_, err = s.store.TribeBlockAttendance.DeleteMany(ctx, bson.M{"tribe_block_id": repository.In(ids), "user_id": userID})
	return err
}

// Leave (COM-12, COM-13): rời nhóm.
// Trưởng nhóm còn người khác thì phải chọn người kế nhiệm (new_leader_id), ở một mình thì rời = giải tán.
func (s *TribeService) Leave(ctx context.Context, me, tribeID, newLeaderID string) (map[string]any, error) {
	tribe, att, err := s.membership(ctx, tribeID, me)
	if err != nil {
		return nil, err
	}
	members, err := s.attendeesOf(ctx, tribe.ID)
	if err != nil {
		return nil, err
	}
	if att.Role == models.TribeRoleLeader {
		if len(members) == 1 {
			if err := s.dissolve(ctx, tribe, me); err != nil {
				return nil, err
			}
			return map[string]any{"action": "dissolved"}, nil
		}
		if newLeaderID == "" {
			candidates := []map[string]string{}
			for _, m := range members {
				if m.UserID != me {
					candidates = append(candidates, map[string]string{"user_id": m.UserID, "role": m.Role})
				}
			}
			return nil, utils.Conflict("need_new_leader", "Trưởng nhóm cần chọn người kế nhiệm trước khi rời nhóm").WithDetails(candidates)
		}
		if err := s.transferLeader(ctx, tribe, members, me, newLeaderID); err != nil {
			return nil, err
		}
	}
	if err := s.removeMember(ctx, tribe.ID, me); err != nil {
		return nil, err
	}
	s.notify(ctx, tribe, without(userIDsOf(members), me), me, models.KindTribeMemberLeft, models.NotiTribeJoin, nil, tribe.ID, models.RefTribe)
	res := map[string]any{"action": "left"}
	if newLeaderID != "" {
		res["new_leader_id"] = newLeaderID
	}
	return res, nil
}

func findMember(members []models.TribeAttendee, userID string) *models.TribeAttendee {
	for i := range members {
		if members[i].UserID == userID {
			return &members[i]
		}
	}
	return nil
}

func countRole(members []models.TribeAttendee, role string, except string) int {
	n := 0
	for _, m := range members {
		if m.Role == role && m.UserID != except {
			n++
		}
	}
	return n
}

// Kick (COM-14): trưởng nhóm mời được phó nhóm và thành viên, phó nhóm chỉ mời được thành viên.
func (s *TribeService) Kick(ctx context.Context, me, tribeID, targetID string) error {
	tribe, att, err := s.membership(ctx, tribeID, me)
	if err != nil {
		return err
	}
	members, err := s.attendeesOf(ctx, tribe.ID)
	if err != nil {
		return err
	}
	target := findMember(members, targetID)
	if target == nil || targetID == me {
		return utils.NotFound("not_found_item", "Không tìm thấy thành viên trong nhóm")
	}
	allowed := (att.Role == models.TribeRoleLeader && target.Role != models.TribeRoleLeader) ||
		(att.Role == models.TribeRoleViceLeader && target.Role == models.TribeRoleMember)
	if !allowed {
		return utils.ErrNotAllowed
	}
	if err := s.removeMember(ctx, tribe.ID, targetID); err != nil {
		return err
	}
	s.notify(ctx, tribe, []string{targetID}, me, models.KindTribeKickedYou, models.NotiTribeRole, nil, tribe.ID, models.RefTribe)
	// Với những người còn lại, "actor" là người vừa rời nhóm
	s.notify(ctx, tribe, without(userIDsOf(members), me, targetID), "", models.KindTribeMemberLeft, models.NotiTribeJoin,
		map[string]string{"actor": s.nickName(ctx, targetID)}, tribe.ID, models.RefTribe)
	return nil
}

// ChangeRole xử lý COM-15 (bổ nhiệm phó nhóm), COM-17 (bãi nhiệm) và COM-16 (chuyển quyền trưởng nhóm).
func (s *TribeService) ChangeRole(ctx context.Context, me, tribeID, targetID, role string) (*TribeDTO, error) {
	tribe, att, err := s.membership(ctx, tribeID, me)
	if err != nil {
		return nil, err
	}
	if att.Role != models.TribeRoleLeader {
		return nil, utils.ErrNotAllowed
	}
	members, err := s.attendeesOf(ctx, tribe.ID)
	if err != nil {
		return nil, err
	}
	target := findMember(members, targetID)
	if target == nil || targetID == me {
		return nil, utils.NotFound("not_found_item", "Không tìm thấy thành viên trong nhóm")
	}

	switch role {
	case models.TribeRoleViceLeader:
		if target.Role != models.TribeRoleMember {
			return nil, utils.ErrNotAllowed
		}
		if countRole(members, models.TribeRoleViceLeader, "") >= models.MaxViceLeaders {
			return nil, utils.Conflict("vice_limit", "Nhóm đã có đủ 3 phó nhóm")
		}
		if err := s.setRole(ctx, tribe.ID, targetID, role); err != nil {
			return nil, err
		}
		s.notify(ctx, tribe, []string{targetID}, me, models.KindTribeRoleVice, models.NotiTribeRole, nil, tribe.ID, models.RefTribe)
	case models.TribeRoleMember:
		if target.Role != models.TribeRoleViceLeader {
			return nil, utils.ErrNotAllowed
		}
		if err := s.setRole(ctx, tribe.ID, targetID, role); err != nil {
			return nil, err
		}
		s.notify(ctx, tribe, []string{targetID}, me, models.KindTribeRoleViceRemoved, models.NotiTribeRole, nil, tribe.ID, models.RefTribe)
	case models.TribeRoleLeader:
		if err := s.transferLeader(ctx, tribe, members, me, targetID); err != nil {
			return nil, err
		}
	default:
		return nil, utils.BadRequest("invalid_role", "role chỉ nhận leader, vice_leader hoặc member")
	}
	return s.detail(ctx, tribe, me)
}

// transferLeader: người được chọn lên trưởng nhóm, trưởng nhóm cũ xuống phó nhóm nếu còn chỗ
// (dưới 3 phó), không thì xuống thành viên.
func (s *TribeService) transferLeader(ctx context.Context, tribe *models.Tribe, members []models.TribeAttendee, oldLeader, newLeader string) error {
	target := findMember(members, newLeader)
	if target == nil || newLeader == oldLeader {
		return utils.NotFound("not_found_item", "Người kế nhiệm không ở trong nhóm")
	}
	myNewRole := models.TribeRoleMember
	if countRole(members, models.TribeRoleViceLeader, newLeader) < models.MaxViceLeaders {
		myNewRole = models.TribeRoleViceLeader
	}
	if err := s.setRole(ctx, tribe.ID, newLeader, models.TribeRoleLeader); err != nil {
		return err
	}
	if err := s.setRole(ctx, tribe.ID, oldLeader, myNewRole); err != nil {
		return err
	}
	s.notify(ctx, tribe, []string{newLeader}, oldLeader, models.KindTribeRoleLeader, models.NotiTribeRole, nil, tribe.ID, models.RefTribe)
	return nil
}

func (s *TribeService) setRole(ctx context.Context, tribeID, userID, role string) error {
	_, err := s.store.TribeAttendees.UpdateOne(ctx, bson.M{"tribe_id": tribeID, "user_id": userID}, bson.M{"$set": bson.M{"role": role}})
	return err
}

// Invite (COM-18): trả mã mời và đường dẫn để app tạo mã QR.
func (s *TribeService) Invite(ctx context.Context, me, tribeID string) (map[string]string, error) {
	tribe, _, err := s.membership(ctx, tribeID, me)
	if err != nil {
		return nil, err
	}
	return map[string]string{"invite_link": tribe.InviteLink, "invite_code": tribe.InviteLink, "invite_url": s.inviteURL(tribe.InviteLink)}, nil
}

// ---------------------------------------------------------------------------
// Xoá tài khoản
// ---------------------------------------------------------------------------

// AccountDeletionPlan mô tả việc sẽ xảy ra với từng nhóm khi xoá tài khoản (AU-07).
type AccountDeletionPlan struct {
	TribeID     string  `json:"tribe_id"`
	TribeName   string  `json:"tribe_name"`
	MyRole      string  `json:"my_role"`
	Action      string  `json:"action"` // left, transfer_leader, dissolve
	NewLeaderID *string `json:"new_leader_id"`
	NewLeader   *string `json:"new_leader_nick_name"`
}

// DeletionPlan: trưởng nhóm thì tự chuyển quyền cho phó nhóm vào sớm nhất, không có phó thì
// thành viên vào sớm nhất; nhóm chỉ có một mình thì giải tán.
func (s *TribeService) DeletionPlan(ctx context.Context, me string) ([]AccountDeletionPlan, error) {
	mine, err := repository.FindMany[models.TribeAttendee](ctx, s.store.TribeAttendees, bson.M{"user_id": me})
	if err != nil {
		return nil, err
	}
	plans := []AccountDeletionPlan{}
	for _, a := range mine {
		tribe, err := repository.FindOne[models.Tribe](ctx, s.store.Tribes, bson.M{"_id": a.TribeID, "deleted_at": nil})
		if err != nil {
			return nil, err
		}
		if tribe == nil {
			continue
		}
		p := AccountDeletionPlan{TribeID: tribe.ID, TribeName: tribe.Name, MyRole: a.Role, Action: "left"}
		if a.Role == models.TribeRoleLeader {
			members, err := s.attendeesOf(ctx, tribe.ID)
			if err != nil {
				return nil, err
			}
			p.Action = "dissolve"
			for _, m := range members { // đã sắp phó nhóm trước, rồi theo ngày vào nhóm
				if m.UserID != me {
					p.Action = "transfer_leader"
					p.NewLeaderID = utils.Ptr(m.UserID)
					p.NewLeader = utils.Ptr(s.nickName(ctx, m.UserID))
					break
				}
			}
		}
		plans = append(plans, p)
	}
	return plans, nil
}

// LeaveAllForAccountDeletion thực hiện kế hoạch ở trên.
func (s *TribeService) LeaveAllForAccountDeletion(ctx context.Context, me string) ([]AccountDeletionPlan, error) {
	plans, err := s.DeletionPlan(ctx, me)
	if err != nil {
		return nil, err
	}
	for _, p := range plans {
		tribe, err := repository.FindOne[models.Tribe](ctx, s.store.Tribes, repository.ByID(p.TribeID))
		if err != nil || tribe == nil {
			continue
		}
		switch p.Action {
		case "dissolve":
			err = s.dissolve(ctx, tribe, me)
		case "transfer_leader":
			_, err = s.Leave(ctx, me, p.TribeID, *p.NewLeaderID)
		default:
			_, err = s.Leave(ctx, me, p.TribeID, "")
		}
		if err != nil {
			return nil, err
		}
	}
	return plans, nil
}

func (s *TribeService) userLoc(ctx context.Context, userID string) *time.Location {
	u, err := s.store.UserByID(ctx, userID)
	if err != nil || u == nil {
		return utils.LoadLocation(models.DefaultTimezone)
	}
	return utils.LoadLocation(u.Timezone)
}
