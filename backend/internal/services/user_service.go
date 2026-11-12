package services

import (
	"context"
	"mime/multipart"
	"strings"
	"time"

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
	notifier *NotificationService
}

// NewUserService tạo service hồ sơ người dùng.
func NewUserService(store *repository.Store, auth *AuthService, tribes *TribeService, up *Uploader, n *NotificationService) *UserService {
	return &UserService{store: store, auth: auth, tribes: tribes, uploader: up, notifier: n}
}

// Me lấy hồ sơ của chính mình (users + vài cột của user_securities).
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
	me := buildMe(u, sec)
	me.PendingEmail = s.pendingEmail(ctx, userID)
	return me, nil
}

type UpdateMeInput struct {
	NickName *string `json:"nick_name"`
	Email    *string `json:"email"`
	Timezone *string `json:"timezone"`
	// Chỉ nhận false: app báo người dùng đã xem xong phần chào mừng
	NeedsOnboarding *bool `json:"needs_onboarding"`
	// Cách chọn múi giờ: true = theo thiết bị; false = tự chọn, kèm thành phố và mã quốc gia để hiển thị
	TimezoneAuto    *bool   `json:"timezone_auto"`
	TimezoneCity    *string `json:"timezone_city"`
	TimezoneCountry *string `json:"timezone_country"`
	// Ngôn ngữ app (vi, en, fr) để gửi thông báo đẩy đúng ngôn ngữ
	Language *string `json:"language"`
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
	// Email không đổi ngay: gửi link xác nhận tới email mới, bấm link rồi mới lưu (xem email_change.go)
	newEmail := ""
	if in.Email != nil {
		email = strings.ToLower(strings.TrimSpace(*in.Email))
		if !utils.IsEmail(email) {
			fields["email"] = "email_invalid"
		} else {
			newEmail = email
		}
	}
	if in.Timezone != nil {
		if !utils.IsValidTimezone(*in.Timezone) {
			fields["timezone"] = "timezone_invalid"
		} else {
			set["timezone"] = *in.Timezone
		}
	}
	unset := bson.M{}
	if in.TimezoneAuto != nil {
		set["timezone_auto"] = *in.TimezoneAuto
		if *in.TimezoneAuto {
			// Theo thiết bị thì bỏ thành phố đã chọn trước đó
			unset["timezone_city"], unset["timezone_country"] = "", ""
		} else {
			if in.TimezoneCity != nil {
				set["timezone_city"] = strings.TrimSpace(*in.TimezoneCity)
			}
			if in.TimezoneCountry != nil {
				set["timezone_country"] = strings.TrimSpace(*in.TimezoneCountry)
			}
		}
	}
	if in.Language != nil {
		set["language"] = NormalizeLang(*in.Language)
	}
	if in.NeedsOnboarding != nil && !*in.NeedsOnboarding {
		set["needs_onboarding"] = false
	}
	if len(fields) > 0 {
		return nil, utils.BadRequest("validation_error", "Thông tin chưa hợp lệ").WithDetails(fields)
	}
	current, err := s.store.UserByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if current == nil {
		return nil, utils.NotFound("not_found_item", "Không tìm thấy tài khoản")
	}
	if newEmail == current.Email {
		newEmail, email = "", "" // giữ nguyên email thì bỏ qua
	}
	if newEmail != "" {
		if err := emailDomainError(newEmail); err != nil {
			return nil, err
		}
	}
	if len(set) == 0 && newEmail == "" {
		if in.Email != nil {
			return s.Me(ctx, userID)
		}
		return nil, utils.BadRequest("validation_error", "Không có thông tin nào cần cập nhật")
	}
	if err := s.auth.ensureUnique(ctx, userID, email, nick); err != nil {
		return nil, err
	}
	if newEmail != "" {
		if err := s.requestEmailChange(ctx, current, newEmail); err != nil {
			return nil, err
		}
	}
	if len(set) == 0 {
		return s.Me(ctx, userID)
	}
	set["updated_at"] = time.Now().UTC()
	update := bson.M{"$set": set}
	if len(unset) > 0 {
		update["$unset"] = unset
	}
	if _, err := s.store.Users.UpdateOne(ctx, repository.ByID(userID), update); err != nil {
		if repository.IsDuplicateKey(err) {
			return nil, utils.Conflict("account_exists", "Email hoặc tên hiển thị đã được sử dụng")
		}
		return nil, err
	}
	// Đổi múi giờ: tính lại lịch cá nhân để giữ đúng thời điểm thực (xem timezone_shift.go)
	if tz, ok := set["timezone"].(string); ok && tz != current.Timezone {
		s.shiftTimeblocks(ctx, userID, utils.LoadLocation(current.Timezone), utils.LoadLocation(tz))
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
	if err := s.notifier.ClearFCMToken(ctx, userID); err != nil {
		return nil, err
	}
	return plans, nil
}

// UpdateFCMToken cho app cập nhật users.fcm_token khi Firebase cấp mã mới (onTokenRefresh).
func (s *UserService) UpdateFCMToken(ctx context.Context, userID, token string) error {
	if strings.TrimSpace(token) == "" {
		return utils.BadRequest("validation_error", "Thiếu fcm_token")
	}
	return s.notifier.SaveFCMToken(ctx, userID, token)
}

// ClearFCMToken đặt fcm_token của mình về null, máy hiện tại thôi nhận thông báo đẩy.
func (s *UserService) ClearFCMToken(ctx context.Context, userID string) error {
	return s.notifier.ClearFCMToken(ctx, userID)
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
