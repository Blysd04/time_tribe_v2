package services

import (
	"context"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"timetribe-backend/internal/config"
	"timetribe-backend/internal/models"
	"timetribe-backend/internal/repository"
	"timetribe-backend/internal/utils"
)

// Bỏ các ký tự dễ nhìn nhầm như O/0, I/1 để người dùng gõ mã cho dễ
const shareAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

type TemplateService struct {
	cfg        *config.Config
	store      *repository.Store
	timeblocks *TimeblockService
}

// NewTemplateService tạo service lịch mẫu.
func NewTemplateService(cfg *config.Config, store *repository.Store, tb *TimeblockService) *TemplateService {
	return &TemplateService{cfg: cfg, store: store, timeblocks: tb}
}

// TemplateDTO là bảng templates kèm các khối và vài số liệu cho thẻ lịch mẫu.
type TemplateDTO struct {
	models.Template
	Blocks     []models.TemplateBlock `json:"blocks"`
	BlockCount int                    `json:"block_count"`
	ActiveDays []int                  `json:"active_days"`
}

type TemplateBlockInput struct {
	DayIndex    int     `json:"day_index"`
	Title       string  `json:"title"`
	Description *string `json:"description"`
	StartTime   string  `json:"start_time"`
	EndTime     string  `json:"end_time"`
	ColorCode   string  `json:"color_code"`
	Remind      *int    `json:"remind"`
}

type TemplateInput struct {
	TemplateName *string               `json:"template_name"`
	Blocks       *[]TemplateBlockInput `json:"blocks"`
}

// toDTO sắp các khối theo thứ và giờ, đếm số khối và các thứ có hoạt động.
func (s *TemplateService) toDTO(t models.Template, blocks []models.TemplateBlock) TemplateDTO {
	sort.SliceStable(blocks, func(i, j int) bool {
		if blocks[i].DayIndex != blocks[j].DayIndex {
			return blocks[i].DayIndex < blocks[j].DayIndex
		}
		return blocks[i].StartTime < blocks[j].StartTime
	})
	days := []int{}
	seen := map[int]bool{}
	for _, b := range blocks {
		if !seen[b.DayIndex] {
			seen[b.DayIndex] = true
			days = append(days, b.DayIndex)
		}
	}
	return TemplateDTO{Template: t, Blocks: blocks, BlockCount: len(blocks), ActiveDays: days}
}

// blocksOf lấy khối của nhiều lịch mẫu, trả map theo id lịch mẫu.
func (s *TemplateService) blocksOf(ctx context.Context, ids ...string) (map[string][]models.TemplateBlock, error) {
	list, err := repository.FindMany[models.TemplateBlock](ctx, s.store.TemplateBlocks, bson.M{"template_id": repository.In(ids)})
	if err != nil {
		return nil, err
	}
	out := map[string][]models.TemplateBlock{}
	for _, b := range list {
		out[b.TemplateID] = append(out[b.TemplateID], b)
	}
	return out, nil
}

// List (TP-01): danh sách lịch mẫu kèm bộ đếm x/10.
func (s *TemplateService) List(ctx context.Context, userID string) (map[string]any, error) {
	list, err := repository.FindMany[models.Template](ctx, s.store.Templates, bson.M{"user_id": userID},
		options.Find().SetSort(bson.D{{Key: "date_modified", Value: -1}}))
	if err != nil {
		return nil, err
	}
	ids := make([]string, len(list))
	for i, t := range list {
		ids[i] = t.ID
	}
	blocks, err := s.blocksOf(ctx, ids...)
	if err != nil {
		return nil, err
	}
	out := make([]TemplateDTO, 0, len(list))
	for _, t := range list {
		bl := blocks[t.ID]
		if bl == nil {
			bl = []models.TemplateBlock{}
		}
		out = append(out, s.toDTO(t, bl))
	}
	return map[string]any{"templates": out, "count": len(out), "max": models.MaxTemplates}, nil
}

// own lấy một lịch mẫu và kiểm tra đúng là của mình.
func (s *TemplateService) own(ctx context.Context, userID, id string) (*models.Template, error) {
	t, err := repository.FindOne[models.Template](ctx, s.store.Templates, bson.M{"_id": id, "user_id": userID})
	if err != nil {
		return nil, err
	}
	if t == nil {
		return nil, utils.NotFound("not_found_item", "Không tìm thấy lịch mẫu")
	}
	return t, nil
}

// Get lấy chi tiết một lịch mẫu của mình kèm các khối.
func (s *TemplateService) Get(ctx context.Context, userID, id string) (*TemplateDTO, error) {
	t, err := s.own(ctx, userID, id)
	if err != nil {
		return nil, err
	}
	return s.load(ctx, t)
}

// load lấy các khối của một lịch mẫu rồi dựng dữ liệu trả về.
func (s *TemplateService) load(ctx context.Context, t *models.Template) (*TemplateDTO, error) {
	blocks, err := s.blocksOf(ctx, t.ID)
	if err != nil {
		return nil, err
	}
	bl := blocks[t.ID]
	if bl == nil {
		bl = []models.TemplateBlock{}
	}
	dto := s.toDTO(*t, bl)
	return &dto, nil
}

// validateTemplateName kiểm tra tên lịch mẫu không rỗng và không quá 255 ký tự.
func validateTemplateName(raw string) (string, error) {
	name := strings.TrimSpace(raw)
	if name == "" {
		return "", utils.BadRequest("empty_name", "Tên lịch mẫu không được để trống")
	}
	if utils.Len(name) > 255 {
		return "", utils.BadRequest("name_too_long", "Tên lịch mẫu tối đa 255 ký tự")
	}
	return name, nil
}

// validateBlocks kiểm tra từng khối và đảm bảo trong cùng một thứ không có khối đè giờ nhau.
func validateBlocks(templateID string, in []TemplateBlockInput) ([]models.TemplateBlock, error) {
	if len(in) > 100 {
		return nil, utils.BadRequest("too_many_blocks", "Một lịch mẫu tối đa 100 hoạt động")
	}
	out := make([]models.TemplateBlock, 0, len(in))
	for i, b := range in {
		bad := func(code, msg string) error {
			return utils.BadRequest(code, msg).WithDetails(map[string]int{"index": i})
		}
		if b.DayIndex < 1 || b.DayIndex > 7 {
			return nil, bad("invalid_day_index", "day_index phải từ 1 (thứ Hai) đến 7 (Chủ nhật)")
		}
		title, desc, err := validateTaskText(b.Title, b.Description)
		if err != nil {
			ae, _ := utils.AsAppError(err)
			return nil, bad(ae.Code, ae.Message)
		}
		st, err1 := utils.NormalizeClock(b.StartTime)
		en, err2 := utils.NormalizeClock(b.EndTime)
		if err1 != nil || err2 != nil {
			return nil, bad("invalid_time", "start_time/end_time phải có dạng HH:mm")
		}
		if utils.ClockMinutes(en)-utils.ClockMinutes(st) < 5 {
			return nil, bad("duration_too_short", "Giờ kết thúc phải sau giờ bắt đầu ít nhất 5 phút")
		}
		color := strings.ToUpper(strings.TrimSpace(b.ColorCode))
		if color == "" {
			color = "#3A86FF"
		}
		if !utils.IsHexColor(color) {
			return nil, bad("invalid_color", "Mã màu phải có dạng #RRGGBB")
		}
		remind := 15
		if b.Remind != nil {
			if !utils.ContainsInt(models.RemindOptions, *b.Remind) {
				return nil, bad("invalid_remind", "remind chỉ nhận 0, 5, 10, 15, 30 hoặc 60")
			}
			remind = *b.Remind
		}
		for _, o := range out {
			if o.DayIndex == b.DayIndex && utils.ClockMinutes(st) < utils.ClockMinutes(o.EndTime) && utils.ClockMinutes(en) > utils.ClockMinutes(o.StartTime) {
				return nil, bad("overlap", "Hoạt động bị trùng giờ với \""+o.Title+"\" trong cùng một thứ")
			}
		}
		out = append(out, models.TemplateBlock{
			ID: uuid.NewString(), TemplateID: templateID, DayIndex: b.DayIndex, Title: title, Description: desc,
			StartTime: st, EndTime: en, ColorCode: color, Remind: remind,
		})
	}
	return out, nil
}

// insertBlocks lưu nhiều khối của lịch mẫu một lần.
func (s *TemplateService) insertBlocks(ctx context.Context, blocks []models.TemplateBlock) error {
	if len(blocks) == 0 {
		return nil
	}
	docs := make([]any, len(blocks))
	for i := range blocks {
		docs[i] = blocks[i]
	}
	_, err := s.store.TemplateBlocks.InsertMany(ctx, docs)
	return err
}

// checkLimit chặn khi kho đã đủ 10 lịch mẫu.
func (s *TemplateService) checkLimit(ctx context.Context, userID string) error {
	n, err := s.store.Templates.CountDocuments(ctx, bson.M{"user_id": userID})
	if err != nil {
		return err
	}
	if n >= models.MaxTemplates {
		return utils.Conflict("limit_exceeded", "Bạn chỉ lưu được tối đa 10 lịch mẫu")
	}
	return nil
}

// Create (TP-02): lưu lịch mẫu mới cùng danh sách khối.
func (s *TemplateService) Create(ctx context.Context, userID string, in TemplateInput) (*TemplateDTO, error) {
	if err := s.checkLimit(ctx, userID); err != nil {
		return nil, err
	}
	raw := ""
	if in.TemplateName != nil {
		raw = *in.TemplateName
	}
	name, err := validateTemplateName(raw)
	if err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	t := models.Template{ID: uuid.NewString(), UserID: userID, TemplateName: name, DateModified: now, CreatedAt: now}
	var blocks []models.TemplateBlock
	if in.Blocks != nil {
		if blocks, err = validateBlocks(t.ID, *in.Blocks); err != nil {
			return nil, err
		}
	}
	if _, err := s.store.Templates.InsertOne(ctx, t); err != nil {
		return nil, err
	}
	if err := s.insertBlocks(ctx, blocks); err != nil {
		return nil, err
	}
	return s.load(ctx, &t)
}

// Update (TP-04, TP-05, TP-07): đổi tên và/hoặc thay toàn bộ danh sách khối
// (app gửi lại cả lịch mẫu khi bấm Lưu, khối nào không còn trong danh sách là đã bị xoá).
func (s *TemplateService) Update(ctx context.Context, userID, id string, in TemplateInput) (*TemplateDTO, error) {
	t, err := s.own(ctx, userID, id)
	if err != nil {
		return nil, err
	}
	set := bson.M{"date_modified": time.Now().UTC()}
	if in.TemplateName != nil {
		name, err := validateTemplateName(*in.TemplateName)
		if err != nil {
			return nil, err
		}
		set["template_name"] = name
	}
	if in.Blocks != nil {
		blocks, err := validateBlocks(t.ID, *in.Blocks)
		if err != nil {
			return nil, err
		}
		if _, err := s.store.TemplateBlocks.DeleteMany(ctx, bson.M{"template_id": t.ID}); err != nil {
			return nil, err
		}
		if err := s.insertBlocks(ctx, blocks); err != nil {
			return nil, err
		}
	}
	if _, err := s.store.Templates.UpdateOne(ctx, repository.ByID(t.ID), bson.M{"$set": set}); err != nil {
		return nil, err
	}
	return s.Get(ctx, userID, id)
}

// Delete (TP-06): xoá các khối rồi xoá lịch mẫu.
func (s *TemplateService) Delete(ctx context.Context, userID, id string) error {
	t, err := s.own(ctx, userID, id)
	if err != nil {
		return err
	}
	if _, err := s.store.TemplateBlocks.DeleteMany(ctx, bson.M{"template_id": t.ID}); err != nil {
		return err
	}
	_, err = s.store.Templates.DeleteOne(ctx, repository.ByID(t.ID))
	return err
}

// Share (TP-08): lấy share_code có sẵn hoặc tạo mới.
func (s *TemplateService) Share(ctx context.Context, userID, id string) (map[string]string, error) {
	t, err := s.own(ctx, userID, id)
	if err != nil {
		return nil, err
	}
	if t.ShareCode == nil {
		for attempt := 0; ; attempt++ {
			code := utils.RandomCode(8, shareAlphabet)
			_, err := s.store.Templates.UpdateOne(ctx, repository.ByID(t.ID), bson.M{"$set": bson.M{"share_code": code}})
			if err == nil {
				t.ShareCode = &code
				break
			}
			if !repository.IsDuplicateKey(err) || attempt >= 5 {
				return nil, err
			}
		}
	}
	return map[string]string{"share_code": *t.ShareCode}, nil
}

// GetShared xem trước lịch mẫu được chia sẻ (ai có mã cũng xem được).
func (s *TemplateService) GetShared(ctx context.Context, rawCode string) (map[string]any, error) {
	code := NormalizeCode(rawCode)
	if code == "" {
		return nil, utils.BadRequest("invalid_code", "Vui lòng nhập mã chia sẻ")
	}
	t, err := repository.FindOne[models.Template](ctx, s.store.Templates, bson.M{"share_code": code})
	if err != nil {
		return nil, err
	}
	if t == nil {
		return nil, utils.NotFound("not_found", "Không tìm thấy lịch mẫu với mã này")
	}
	dto, err := s.load(ctx, t)
	if err != nil {
		return nil, err
	}
	owner := ""
	if u, _ := s.store.UserByID(ctx, t.UserID); u != nil {
		owner = u.NickName
	}
	return map[string]any{"template": dto, "owner_nick_name": owner}, nil
}

// Import (TP-03): chép lịch mẫu từ mã chia sẻ về kho của mình, ghi nhớ original_template_id
// để lần sau nhập lại sẽ báo trùng.
func (s *TemplateService) Import(ctx context.Context, userID, rawCode string) (*TemplateDTO, error) {
	if err := s.checkLimit(ctx, userID); err != nil {
		return nil, err
	}
	code := NormalizeCode(rawCode)
	if code == "" {
		return nil, utils.BadRequest("invalid_code", "Vui lòng nhập mã chia sẻ")
	}
	src, err := repository.FindOne[models.Template](ctx, s.store.Templates, bson.M{"share_code": code})
	if err != nil {
		return nil, err
	}
	if src == nil {
		return nil, utils.NotFound("not_found", "Không tìm thấy lịch mẫu với mã này")
	}
	// Mẫu gốc mà bản chia sẻ này bắt nguồn từ đó (nếu nó cũng là bản đã nhập)
	rootID := src.ID
	if src.OriginalTemplateID != nil {
		rootID = *src.OriginalTemplateID
	}
	dup, err := s.store.Templates.CountDocuments(ctx, bson.M{
		"user_id": userID,
		"$or": bson.A{
			bson.M{"_id": bson.M{"$in": bson.A{src.ID, rootID}}},
			bson.M{"original_template_id": bson.M{"$in": bson.A{src.ID, rootID}}},
		},
	})
	if err != nil {
		return nil, err
	}
	if dup > 0 {
		return nil, utils.Conflict("duplicate", "Lịch mẫu này đã có trong kho của bạn")
	}

	srcBlocks, err := s.blocksOf(ctx, src.ID)
	if err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	t := models.Template{
		ID: uuid.NewString(), UserID: userID, OriginalTemplateID: utils.Ptr(src.ID),
		TemplateName: src.TemplateName, DateModified: now, CreatedAt: now,
	}
	blocks := make([]models.TemplateBlock, 0, len(srcBlocks[src.ID]))
	for _, b := range srcBlocks[src.ID] {
		b.ID, b.TemplateID = uuid.NewString(), t.ID
		blocks = append(blocks, b)
	}
	if _, err := s.store.Templates.InsertOne(ctx, t); err != nil {
		return nil, err
	}
	if err := s.insertBlocks(ctx, blocks); err != nil {
		return nil, err
	}
	return s.load(ctx, &t)
}

type ApplyInput struct {
	DayIndexes       []int `json:"day_indexes"`
	Weeks            int   `json:"weeks"`
	ReplaceConflicts bool  `json:"replace_conflicts"`
	DryRun           bool  `json:"dry_run"`
}

// Apply (TP-09): sinh lịch cá nhân từ lịch mẫu cho các thứ đã chọn trong 1-12 tuần tới,
// tính từ hôm nay theo múi giờ người dùng. Có trùng giờ mà chưa đồng ý thay thế thì trả 409
// kèm danh sách để app hỏi "Thay thế & Thêm".
func (s *TemplateService) Apply(ctx context.Context, userID, id string, in ApplyInput) (map[string]any, error) {
	dto, err := s.Get(ctx, userID, id)
	if err != nil {
		return nil, err
	}
	if in.Weeks == 0 {
		in.Weeks = 1
	}
	if in.Weeks < 1 || in.Weeks > 12 {
		return nil, utils.BadRequest("invalid_weeks", "Số tuần lặp lại từ 1 đến 12")
	}
	if len(in.DayIndexes) == 0 {
		in.DayIndexes = dto.ActiveDays
	}
	for _, d := range in.DayIndexes {
		if d < 1 || d > 7 {
			return nil, utils.BadRequest("invalid_day_index", "day_indexes chỉ nhận giá trị 1 đến 7")
		}
	}

	loc := s.timeblocks.loc(ctx, userID)
	today := time.Now().In(loc)
	todayIdx := int(today.Weekday())
	if todayIdx == 0 {
		todayIdx = 7
	}
	now := time.Now().UTC()
	toAdd := []models.Timeblock{}
	seenDay := map[int]bool{}
	for _, day := range in.DayIndexes {
		if seenDay[day] {
			continue
		}
		seenDay[day] = true
		offset := (day - todayIdx + 7) % 7
		for w := 0; w < in.Weeks; w++ {
			date := time.Date(today.Year(), today.Month(), today.Day()+offset+w*7, 0, 0, 0, 0, loc).Format(utils.DateLayout)
			for _, b := range dto.Blocks {
				if b.DayIndex != day {
					continue
				}
				toAdd = append(toAdd, models.Timeblock{
					ID: uuid.NewString(), UserID: userID, Task: b.Title, Description: b.Description, Date: date,
					StartTime: b.StartTime, EndTime: b.EndTime, ColorCode: b.ColorCode, Remind: b.Remind, CreatedAt: now,
				})
			}
		}
	}
	if len(toAdd) == 0 {
		return nil, utils.BadRequest("nothing_to_apply", "Các thứ đã chọn không có hoạt động nào")
	}

	// Tìm lịch cũ bị đè giờ
	conflicts := map[string]models.Timeblock{}
	conflictDates := map[string]bool{}
	for _, b := range toAdd {
		list, err := s.timeblocks.conflictsOn(ctx, userID, b.Date, b.StartTime, b.EndTime, "")
		if err != nil {
			return nil, err
		}
		for _, c := range list {
			conflicts[c.ID] = c
			conflictDates[b.Date] = true
		}
	}
	dates := make([]string, 0, len(conflictDates))
	for d := range conflictDates {
		dates = append(dates, d)
	}
	sort.Strings(dates)
	conflictList := make([]models.Timeblock, 0, len(conflicts))
	for _, c := range conflicts {
		conflictList = append(conflictList, c)
	}
	summary := map[string]any{"to_add": len(toAdd), "conflict_count": len(conflicts), "conflict_dates": dates, "conflicts": conflictList}

	if in.DryRun {
		summary["preview"] = toAdd
		return summary, nil
	}
	if len(conflicts) > 0 && !in.ReplaceConflicts {
		return nil, utils.Conflict("conflict", "Có hoạt động bị trùng giờ, gửi lại với replace_conflicts = true để thay thế").WithDetails(summary)
	}
	if len(conflicts) > 0 {
		ids := make([]string, 0, len(conflicts))
		for id := range conflicts {
			ids = append(ids, id)
		}
		if _, err := s.store.Timeblocks.DeleteMany(ctx, bson.M{"_id": repository.In(ids), "user_id": userID}); err != nil {
			return nil, err
		}
	}
	if err := s.timeblocks.insertCopies(ctx, toAdd); err != nil {
		return nil, err
	}
	return map[string]any{"added": len(toAdd), "overwritten": len(conflicts), "conflict_dates": dates}, nil
}
