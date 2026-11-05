package services

import (
	"context"
	"log"
	"mime/multipart"
	"strings"
	"time"

	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/v2/bson"

	"timetribe-backend/internal/models"
	"timetribe-backend/internal/repository"
	"timetribe-backend/internal/utils"
)

type UserService struct {
	store    *repository.Store
	auth     *AuthService
	tribes   *TribeService
	uploader *Uploader
	firebase *FirebaseService
}

func NewUserService(store *repository.Store, auth *AuthService, tribes *TribeService, up *Uploader, fb *FirebaseService) *UserService {
	return &UserService{store: store, auth: auth, tribes: tribes, uploader: up, firebase: fb}
}

func (s *UserService) Me(ctx context.Context, userID string) (*MeResponse, error) {
	u, err := s.store.UserByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	sec, err := s.store.SecurityByUserID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if u == nil || sec == nil {
		return nil, utils.NotFound("not_found_item", "Không tìm thấy tài khoản")
	}
	return buildMe(u, sec), nil
}

type UpdateMeInput struct {
	NickName *string `json:"nick_name"`
	Email    *string `json:"email"`
	Timezone *string `json:"timezone"`
}

// UpdateMe (INFO-01, INFO-04): sửa tên hiển thị, email, múi giờ IANA.
func (s *UserService) UpdateMe(ctx context.Context, userID string, in UpdateMeInput) (*MeResponse, error) {
	set := bson.M{}
	fields := map[string]string{}
	nick, email := "", ""
	if in.NickName != nil {
		nick = strings.TrimSpace(*in.NickName)
		if nick == "" {
			fields["nick_name"] = "name_required"
		} else if utils.Len(nick) < 2 || utils.Len(nick) > 100 {
			fields["nick_name"] = "name_length"
		} else {
			set["nick_name"] = nick
		}
	}
	if in.Email != nil {
		email = strings.ToLower(strings.TrimSpace(*in.Email))
		if !utils.IsEmail(email) {
			fields["email"] = "email_invalid"
		} else {
			set["email"] = email
		}
	}
	if in.Timezone != nil {
		if !utils.IsValidTimezone(*in.Timezone) {
			fields["timezone"] = "timezone_invalid"
		} else {
			set["timezone"] = *in.Timezone
		}
	}
	if len(fields) > 0 {
		return nil, utils.BadRequest("validation_error", "Thông tin chưa hợp lệ").WithDetails(fields)
	}
	if len(set) == 0 {
		return nil, utils.BadRequest("validation_error", "Không có thông tin nào cần cập nhật")
	}
	if err := s.auth.ensureUnique(ctx, userID, email, nick); err != nil {
		return nil, err
	}
	set["updated_at"] = time.Now().UTC()
	if _, err := s.store.Users.UpdateOne(ctx, repository.ByID(userID), bson.M{"$set": set}); err != nil {
		if repository.IsDuplicateKey(err) {
			return nil, utils.Conflict("account_exists", "Email hoặc tên hiển thị đã được sử dụng")
		}
		return nil, err
	}
	return s.Me(ctx, userID)
}

// UploadAvatar (INFO-02, INFO-03): ảnh từ thư viện hay máy ảnh đều gửi lên dạng multipart.
func (s *UserService) UploadAvatar(ctx context.Context, userID string, fh *multipart.FileHeader) (*MeResponse, error) {
	url, err := s.uploader.UploadImage(ctx, fh, "timetribe/avatars", userID, true)
	if err != nil {
		return nil, err
	}
	_, err = s.store.Users.UpdateOne(ctx, repository.ByID(userID), bson.M{"$set": bson.M{"avatar_url": url, "updated_at": time.Now().UTC()}})
	if err != nil {
		return nil, err
	}
	return s.Me(ctx, userID)
}

// DeletePlan cho màn hình DeleteAccountScreen biết các nhóm sẽ bị chuyển quyền hoặc giải tán.
func (s *UserService) DeletePlan(ctx context.Context, userID string) ([]AccountDeletionPlan, error) {
	return s.tribes.DeletionPlan(ctx, userID)
}

// DeleteAccount (AU-07): rời/chuyển quyền/giải tán nhóm, ghi delete_at + delete_reason,
// xoá toàn bộ token. Dữ liệu users vẫn giữ lại (xoá mềm).
func (s *UserService) DeleteAccount(ctx context.Context, userID, reason string) ([]AccountDeletionPlan, error) {
	reason = strings.TrimSpace(reason)
	if reason == "" {
		return nil, utils.BadRequest("reason_required", "Vui lòng chọn lý do xoá tài khoản")
	}
	if utils.Len(reason) > 255 {
		return nil, utils.BadRequest("reason_too_long", "Lý do tối đa 255 ký tự")
	}
	plans, err := s.tribes.LeaveAllForAccountDeletion(ctx, userID)
	if err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	if _, err := s.store.UserSecurities.UpdateOne(ctx, repository.ByID(userID), bson.M{"$set": bson.M{
		"delete_at": now, "delete_reason": reason,
	}}); err != nil {
		return nil, err
	}
	if _, err := s.store.UserTokens.DeleteMany(ctx, bson.M{"user_id": userID}); err != nil {
		return nil, err
	}
	return plans, nil
}

// RegisterDevice lưu mã FCM của thiết bị (token_type = fcm) và đăng ký topic thông báo chung.
// Một mã FCM chỉ thuộc về một người, đăng nhập tài khoản khác trên cùng máy thì chuyển chủ.
func (s *UserService) RegisterDevice(ctx context.Context, userID, fcmToken, device string) error {
	fcmToken = strings.TrimSpace(fcmToken)
	if fcmToken == "" {
		return utils.BadRequest("validation_error", "Thiếu fcm_token")
	}
	now := time.Now().UTC()
	_, err := s.store.UserTokens.UpdateOne(ctx,
		bson.M{"token": fcmToken},
		bson.M{
			"$set": bson.M{
				"user_id": userID, "token_type": models.TokenFCM, "device_info": utils.TrimPtr(&device),
				"expires_at": now.AddDate(0, 2, 0),
			},
			"$setOnInsert": bson.M{"_id": uuid.NewString(), "created_at": now},
		},
		upsertOne())
	if err != nil {
		return err
	}
	if s.firebase.PushEnabled() {
		go func() {
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			if _, err := s.firebase.Messaging.SubscribeToTopic(ctx, []string{fcmToken}, TopicAllUsers); err != nil {
				log.Printf("đăng ký topic %s lỗi: %v", TopicAllUsers, err)
			}
		}()
	}
	return nil
}

func (s *UserService) UnregisterDevice(ctx context.Context, userID, fcmToken string) error {
	_, err := s.store.UserTokens.DeleteOne(ctx, bson.M{"user_id": userID, "token": fcmToken, "token_type": models.TokenFCM})
	return err
}

// SetBan dành cho admin: khoá hoặc mở khoá tài khoản.
func (s *UserService) SetBan(ctx context.Context, userID string, banned bool, reason *string) error {
	set := bson.M{"is_banned": banned, "ban_reason": nil}
	if banned {
		set["ban_reason"] = utils.TrimPtr(reason)
	}
	res, err := s.store.UserSecurities.UpdateOne(ctx, repository.ByID(userID), bson.M{"$set": set})
	if err != nil {
		return err
	}
	if res.MatchedCount == 0 {
		return utils.NotFound("not_found_item", "Không tìm thấy tài khoản")
	}
	if banned {
		_, err = s.store.UserTokens.DeleteMany(ctx, bson.M{"user_id": userID, "token_type": models.TokenRefresh})
	}
	return err
}
