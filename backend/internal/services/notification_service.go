package services

import (
	"context"
	"encoding/json"
	"log"
	"strings"
	"time"

	"firebase.google.com/go/v4/messaging"
	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"timetribe-backend/internal/models"
	"timetribe-backend/internal/repository"
	"timetribe-backend/internal/utils"
)

type NotificationService struct {
	store    *repository.Store
	firebase *FirebaseService
}

// NewNotificationService tạo service thông báo.
func NewNotificationService(store *repository.Store, fb *FirebaseService) *NotificationService {
	return &NotificationService{store: store, firebase: fb}
}

// NotifyInput mô tả một thông báo cần gửi cho nhiều người cùng lúc.
type NotifyInput struct {
	Recipients    []string
	CreatedBy     *string
	Kind          string
	Type          string
	Args          map[string]string
	ReferenceID   *string
	ReferenceType *string
	// SkipPush: chỉ lưu vào danh sách thông báo, không gửi FCM (VD nhắc bù khi hoạt động đã bắt đầu)
	SkipPush bool
	// At: thời điểm ghi vào created_at (nhắc lịch dùng đúng mốc nhắc, kể cả khi nhắc bù),
	// nil thì lấy giờ hiện tại.
	At *time.Time
}

// Notify lưu thông báo vào DB cho từng người nhận rồi gửi FCM ở goroutine riêng,
// để request của người dùng không phải chờ Firebase trả lời.
func (s *NotificationService) Notify(ctx context.Context, in NotifyInput) {
	if len(in.Recipients) == 0 {
		return
	}
	content, _ := json.Marshal(in.Args)
	now := time.Now().UTC()
	if in.At != nil {
		now = in.At.UTC()
	}
	docs := make([]any, 0, len(in.Recipients))
	seen := map[string]bool{}
	for _, uid := range in.Recipients {
		if seen[uid] {
			continue
		}
		seen[uid] = true
		docs = append(docs, models.Notification{
			ID:            uuid.NewString(),
			UserID:        utils.Ptr(uid),
			CreatedBy:     in.CreatedBy,
			Title:         in.Kind,
			Content:       string(content),
			Type:          in.Type,
			ReferenceID:   in.ReferenceID,
			ReferenceType: in.ReferenceType,
			IsRead:        false,
			CreatedAt:     now,
		})
	}
	if _, err := s.store.Notifications.InsertMany(ctx, docs); err != nil {
		log.Printf("lưu thông báo %s lỗi: %v", in.Kind, err)
	}

	recipients := make([]string, 0, len(seen))
	for uid := range seen {
		recipients = append(recipients, uid)
	}
	data := map[string]string{
		"kind": in.Kind,
		"type": in.Type,
		"args": string(content),
	}
	if in.ReferenceID != nil {
		data["reference_id"] = *in.ReferenceID
	}
	if in.ReferenceType != nil {
		data["reference_type"] = *in.ReferenceType
	}
	if in.SkipPush {
		return
	}
	kind, args := in.Kind, in.Args
	go s.pushToUsers(recipients, func(lang string) (string, string) { return PushText(lang, kind, args) }, data)
}

// TestPush gửi một thông báo đẩy thử tới máy của chính người dùng, để kiểm tra
// Firebase, mã FCM và quyền hiện thông báo trên máy. Trả lỗi rõ ràng nếu không gửi được.
func (s *NotificationService) TestPush(ctx context.Context, userID string) error {
	if !s.firebase.PushEnabled() {
		return utils.BadRequest("push_disabled", "Server chưa cấu hình Firebase (thiếu serviceAccountKey.json)")
	}
	u, err := s.store.UserByID(ctx, userID)
	if err != nil {
		return err
	}
	if u == nil || u.FCMToken == nil || *u.FCMToken == "" {
		return utils.BadRequest("no_fcm_token", "Tài khoản chưa có mã FCM của máy")
	}
	_, err = s.firebase.Messaging.Send(ctx, &messaging.Message{
		Token:        *u.FCMToken,
		Notification: &messaging.Notification{Title: "TimeTribe", Body: "Thông báo thử lúc " + time.Now().In(utils.LoadLocation(u.Timezone)).Format("15:04:05")},
		Data:         map[string]string{"kind": "test", "type": "system"},
		Android:      AndroidPush(),
	})
	if err != nil {
		log.Printf("gửi thông báo thử cho %s lỗi: %v", u.NickName, err)
		return utils.BadRequest("push_failed", "Firebase từ chối: "+err.Error())
	}
	return nil
}

// pushToUsers lấy users.fcm_token của người nhận rồi gửi, mã nào đã chết thì đặt lại null.
// text dựng tiêu đề + nội dung theo ngôn ngữ từng người (users.language), nên gửi theo từng nhóm ngôn ngữ.
func (s *NotificationService) pushToUsers(userIDs []string, text func(lang string) (string, string), data map[string]string) {
	if !s.firebase.PushEnabled() {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	users, err := repository.FindMany[models.User](ctx, s.store.Users, bson.M{
		"_id": repository.In(userIDs), "fcm_token": bson.M{"$type": "string"},
	})
	if err != nil || len(users) == 0 {
		return
	}
	byLang := map[string][]models.User{}
	for _, u := range users {
		lang := NormalizeLang(u.Language)
		byLang[lang] = append(byLang[lang], u)
	}
	for lang, group := range byLang {
		title, body := text(lang)
		s.sendMulticast(ctx, group, title, body, data)
	}
}

// sendMulticast gửi cùng một nội dung tới nhiều máy, mỗi lần tối đa 500 máy theo giới hạn của FCM.
func (s *NotificationService) sendMulticast(ctx context.Context, users []models.User, title, body string, data map[string]string) {
	for start := 0; start < len(users); start += 500 {
		end := min(start+500, len(users))
		batch := users[start:end]
		regs := make([]string, len(batch))
		for i, u := range batch {
			regs[i] = *u.FCMToken
		}
		res, err := s.firebase.Messaging.SendEachForMulticast(ctx, &messaging.MulticastMessage{
			Tokens:       regs,
			Notification: &messaging.Notification{Title: title, Body: body},
			Data:         data,
			Android:      AndroidPush(),
			APNS: &messaging.APNSConfig{
				Headers: map[string]string{"apns-priority": "10", "apns-push-type": "alert"},
				Payload: &messaging.APNSPayload{Aps: &messaging.Aps{Sound: "default"}},
			},
		})
		if err != nil {
			log.Printf("gửi FCM lỗi: %v", err)
			continue
		}
		log.Printf("FCM %q: gửi thành công %d/%d máy", title, res.SuccessCount, len(regs))
		for i, r := range res.Responses {
			if r.Success || r.Error == nil {
				continue
			}
			log.Printf("FCM tới %s lỗi: %v", batch[i].NickName, r.Error)
			// Chỉ xoá mã khi Firebase báo mã đã chết. Lỗi invalid-argument có thể do nội dung
			// tin nhắn, xoá mã lúc đó làm người dùng mất hẳn thông báo đẩy.
			if messaging.IsRegistrationTokenNotRegistered(r.Error) || messaging.IsSenderIDMismatch(r.Error) {
				_ = s.ClearFCMToken(ctx, batch[i].ID)
			}
		}
	}
}

// SaveFCMToken ghi mã thiết bị vào users.fcm_token và đăng ký topic thông báo chung.
// Mã rỗng thì bỏ qua, giữ nguyên giá trị đang có (người mới thì vẫn là null).
// Một máy chỉ nhận thông báo cho một tài khoản, nên mã này đang gắn với ai khác thì gỡ ra.
func (s *NotificationService) SaveFCMToken(ctx context.Context, userID, token string) error {
	token = strings.TrimSpace(token)
	if token == "" {
		return nil
	}
	if _, err := s.store.Users.UpdateMany(ctx,
		bson.M{"fcm_token": token, "_id": bson.M{"$ne": userID}},
		bson.M{"$set": bson.M{"fcm_token": nil}}); err != nil {
		return err
	}
	if _, err := s.store.Users.UpdateOne(ctx, repository.ByID(userID), bson.M{"$set": bson.M{"fcm_token": token}}); err != nil {
		return err
	}
	if s.firebase.PushEnabled() {
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			if _, err := s.firebase.Messaging.SubscribeToTopic(ctx, []string{token}, TopicAllUsers); err != nil {
				log.Printf("đăng ký topic %s lỗi: %v", TopicAllUsers, err)
			}
		}()
	}
	return nil
}

// ClearFCMToken đặt users.fcm_token về null (đăng xuất, xoá tài khoản, mã hết hiệu lực).
func (s *NotificationService) ClearFCMToken(ctx context.Context, userID string) error {
	_, err := s.store.Users.UpdateOne(ctx, repository.ByID(userID), bson.M{"$set": bson.M{"fcm_token": nil}})
	return err
}

// NotificationDTO là bản ghi notifications kèm vài trường tiện cho app:
// kind (chính là title), args (content đã parse) và tribe_id để lọc theo nhóm.
type NotificationDTO struct {
	models.Notification
	Kind    string            `json:"kind"`
	Args    map[string]string `json:"args"`
	TribeID *string           `json:"tribe_id"`
}

// toNotificationDTO tách content (JSON) thành args và lấy tribe_id ra cho app dễ dùng.
func toNotificationDTO(n models.Notification) NotificationDTO {
	dto := NotificationDTO{Notification: n, Kind: n.Title, Args: map[string]string{}}
	if err := json.Unmarshal([]byte(n.Content), &dto.Args); err != nil {
		// Thông báo hệ thống của admin là chữ thường, không phải JSON
		dto.Args = map[string]string{}
		dto.Kind = n.Type
	}
	if id, ok := dto.Args["tribe_id"]; ok && id != "" {
		dto.TribeID = utils.Ptr(id)
	}
	return dto
}

// windows trả mốc thời gian sớm nhất được xem: since cho thông báo riêng (30 ngày gần nhất) và
// sharedSince cho thông báo chung của admin. Thông báo chung gửi trước lúc tạo tài khoản không dành cho
// người này (VD tài khoản tạo hôm nay không thấy lời chào "4 ngày trước"), nên lấy mốc muộn hơn trong hai mốc.
func (s *NotificationService) windows(ctx context.Context, userID string) (since, sharedSince time.Time) {
	since = time.Now().UTC().AddDate(0, 0, -models.NotificationRetentionDays)
	sharedSince = since
	u, err := repository.FindOne[models.User](ctx, s.store.Users, repository.ByID(userID),
		options.FindOne().SetProjection(bson.M{"created_at": 1}))
	if err == nil && u != nil && u.CreatedAt.After(sharedSince) {
		sharedSince = u.CreatedAt
	}
	return since, sharedSince
}

// List trả thông báo 30 ngày gần nhất của người dùng, kể cả thông báo chung (user_id null).
// filter: all, personal, hoặc id của một nhóm.
func (s *NotificationService) List(ctx context.Context, userID, filter string) ([]NotificationDTO, error) {
	since, sharedSince := s.windows(ctx, userID)
	rows, err := repository.FindMany[models.Notification](ctx, s.store.Notifications, bson.M{
		"$or": bson.A{
			bson.M{"user_id": userID, "created_at": bson.M{"$gte": since}},
			bson.M{"user_id": nil, "created_at": bson.M{"$gte": sharedSince}},
		},
	}, options.Find().SetSort(bson.D{{Key: "created_at", Value: -1}}).SetLimit(500))
	if err != nil {
		return nil, err
	}
	out := make([]NotificationDTO, 0, len(rows))
	for _, n := range rows {
		dto := toNotificationDTO(n)
		// Thông báo chung: đã đọc hay chưa tính riêng cho từng người
		dto.IsRead = n.IsReadBy(userID)
		switch filter {
		case "", "all":
		case "personal":
			if dto.TribeID != nil {
				continue
			}
		default:
			if dto.TribeID == nil || *dto.TribeID != filter {
				continue
			}
		}
		out = append(out, dto)
	}
	return out, nil
}

// UnreadSummary đếm thông báo chưa đọc: tổng, cá nhân và theo từng nhóm (để hiện badge trên chip lọc).
// Thông báo chung của admin tính vào mục cá nhân nếu người này chưa đọc.
func (s *NotificationService) UnreadSummary(ctx context.Context, userID string) (map[string]any, error) {
	since, sharedSince := s.windows(ctx, userID)
	rows, err := repository.FindMany[models.Notification](ctx, s.store.Notifications, bson.M{
		"$or": bson.A{
			bson.M{"user_id": userID, "is_read": false, "created_at": bson.M{"$gte": since}},
			bson.M{"user_id": nil, "read_by": bson.M{"$ne": userID}, "created_at": bson.M{"$gte": sharedSince}},
		},
	})
	if err != nil {
		return nil, err
	}
	byTribe := map[string]int{}
	personal := 0
	for _, n := range rows {
		dto := toNotificationDTO(n)
		if dto.TribeID == nil {
			personal++
		} else {
			byTribe[*dto.TribeID]++
		}
	}
	return map[string]any{"total": len(rows), "personal": personal, "by_tribe": byTribe}, nil
}

// MarkRead (NOTI-02) đánh dấu một thông báo của mình (hoặc thông báo chung) là đã đọc.
func (s *NotificationService) MarkRead(ctx context.Context, userID, id string) error {
	res, err := s.store.Notifications.UpdateOne(ctx,
		bson.M{"_id": id, "user_id": userID},
		bson.M{"$set": bson.M{"is_read": true}})
	if err != nil {
		return err
	}
	if res.MatchedCount == 0 {
		// Thông báo chung: ghi id người đọc vào read_by
		res, err = s.store.Notifications.UpdateOne(ctx,
			bson.M{"_id": id, "user_id": nil},
			bson.M{"$addToSet": bson.M{"read_by": userID}})
		if err != nil {
			return err
		}
	}
	if res.MatchedCount == 0 {
		return utils.NotFound("not_found_item", "Không tìm thấy thông báo")
	}
	return nil
}

// MarkAllRead (NOTI-02) đánh dấu mọi thông báo của mình là đã đọc, trả về số dòng đã đổi.
func (s *NotificationService) MarkAllRead(ctx context.Context, userID string) (int64, error) {
	res, err := s.store.Notifications.UpdateMany(ctx,
		bson.M{"user_id": userID, "is_read": false},
		bson.M{"$set": bson.M{"is_read": true}})
	if err != nil {
		return 0, err
	}
	shared, err := s.store.Notifications.UpdateMany(ctx,
		bson.M{"user_id": nil, "read_by": bson.M{"$ne": userID}},
		bson.M{"$addToSet": bson.M{"read_by": userID}})
	if err != nil {
		return 0, err
	}
	return res.ModifiedCount + shared.ModifiedCount, nil
}

// Broadcast: admin gửi thông báo chung, lưu một bản ghi user_id = null và đẩy qua topic.
func (s *NotificationService) Broadcast(ctx context.Context, adminID, title, content string) (*models.Notification, error) {
	n := models.Notification{
		ID:        uuid.NewString(),
		UserID:    nil,
		CreatedBy: utils.Ptr(adminID),
		Title:     title,
		Content:   content,
		Type:      models.NotiSystemBroadcast,
		CreatedAt: time.Now().UTC(),
	}
	if _, err := s.store.Notifications.InsertOne(ctx, n); err != nil {
		return nil, err
	}
	if s.firebase.PushEnabled() {
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
			defer cancel()
			_, err := s.firebase.Messaging.Send(ctx, &messaging.Message{
				Topic:        TopicAllUsers,
				Notification: &messaging.Notification{Title: title, Body: content},
				Data:         map[string]string{"kind": models.NotiSystemBroadcast, "type": models.NotiSystemBroadcast},
				Android:      AndroidPush(),
			})
			if err != nil {
				log.Printf("gửi thông báo chung lỗi: %v", err)
			}
		}()
	}
	return &n, nil
}
