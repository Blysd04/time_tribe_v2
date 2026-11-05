package services

import (
	"context"
	"encoding/json"
	"log"
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
}

// Notify lưu thông báo vào DB cho từng người nhận rồi gửi FCM ở goroutine riêng,
// để request của người dùng không phải chờ Firebase trả lời.
func (s *NotificationService) Notify(ctx context.Context, in NotifyInput) {
	if len(in.Recipients) == 0 {
		return
	}
	content, _ := json.Marshal(in.Args)
	now := time.Now().UTC()
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
	title, body := PushText(in.Kind, in.Args)
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
	go s.pushToUsers(recipients, title, body, data)
}

// pushToUsers lấy mã FCM của các thiết bị rồi gửi, mã nào đã chết thì xoá khỏi user_tokens.
func (s *NotificationService) pushToUsers(userIDs []string, title, body string, data map[string]string) {
	if !s.firebase.PushEnabled() {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	tokens, err := repository.FindMany[models.UserToken](ctx, s.store.UserTokens, bson.M{
		"user_id":    repository.In(userIDs),
		"token_type": models.TokenFCM,
		"expires_at": bson.M{"$gt": time.Now()},
	})
	if err != nil || len(tokens) == 0 {
		return
	}
	// Mỗi lần gửi tối đa 500 thiết bị theo giới hạn của FCM
	for start := 0; start < len(tokens); start += 500 {
		end := min(start+500, len(tokens))
		batch := tokens[start:end]
		regs := make([]string, len(batch))
		for i, t := range batch {
			regs[i] = t.Token
		}
		res, err := s.firebase.Messaging.SendEachForMulticast(ctx, &messaging.MulticastMessage{
			Tokens:       regs,
			Notification: &messaging.Notification{Title: title, Body: body},
			Data:         data,
			Android:      &messaging.AndroidConfig{Priority: "high"},
		})
		if err != nil {
			log.Printf("gửi FCM lỗi: %v", err)
			continue
		}
		for i, r := range res.Responses {
			if r.Success || r.Error == nil {
				continue
			}
			if messaging.IsRegistrationTokenNotRegistered(r.Error) || messaging.IsInvalidArgument(r.Error) {
				_, _ = s.store.UserTokens.DeleteOne(ctx, bson.M{"_id": batch[i].ID})
			}
		}
	}
}

// NotificationDTO là bản ghi notifications kèm vài trường tiện cho app:
// kind (chính là title), args (content đã parse) và tribe_id để lọc theo nhóm.
type NotificationDTO struct {
	models.Notification
	Kind    string            `json:"kind"`
	Args    map[string]string `json:"args"`
	TribeID *string           `json:"tribe_id"`
}

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

// List trả thông báo 30 ngày gần nhất của người dùng, kể cả thông báo chung (user_id null).
// filter: all, personal, hoặc id của một nhóm.
func (s *NotificationService) List(ctx context.Context, userID, filter string) ([]NotificationDTO, error) {
	since := time.Now().UTC().AddDate(0, 0, -models.NotificationRetentionDays)
	rows, err := repository.FindMany[models.Notification](ctx, s.store.Notifications, bson.M{
		"$or":        bson.A{bson.M{"user_id": userID}, bson.M{"user_id": nil}},
		"created_at": bson.M{"$gte": since},
	}, options.Find().SetSort(bson.D{{Key: "created_at", Value: -1}}).SetLimit(500))
	if err != nil {
		return nil, err
	}
	out := make([]NotificationDTO, 0, len(rows))
	for _, n := range rows {
		dto := toNotificationDTO(n)
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
// Thông báo chung của admin không tính vào vì cột is_read của nó dùng chung cho mọi người.
func (s *NotificationService) UnreadSummary(ctx context.Context, userID string) (map[string]any, error) {
	since := time.Now().UTC().AddDate(0, 0, -models.NotificationRetentionDays)
	rows, err := repository.FindMany[models.Notification](ctx, s.store.Notifications, bson.M{
		"user_id": userID, "is_read": false, "created_at": bson.M{"$gte": since},
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

func (s *NotificationService) MarkRead(ctx context.Context, userID, id string) error {
	res, err := s.store.Notifications.UpdateOne(ctx,
		bson.M{"_id": id, "user_id": userID},
		bson.M{"$set": bson.M{"is_read": true}})
	if err != nil {
		return err
	}
	if res.MatchedCount == 0 {
		return utils.NotFound("not_found_item", "Không tìm thấy thông báo")
	}
	return nil
}

func (s *NotificationService) MarkAllRead(ctx context.Context, userID string) (int64, error) {
	res, err := s.store.Notifications.UpdateMany(ctx,
		bson.M{"user_id": userID, "is_read": false},
		bson.M{"$set": bson.M{"is_read": true}})
	if err != nil {
		return 0, err
	}
	return res.ModifiedCount, nil
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
			})
			if err != nil {
				log.Printf("gửi thông báo chung lỗi: %v", err)
			}
		}()
	}
	return &n, nil
}
