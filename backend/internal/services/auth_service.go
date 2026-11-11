package services

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/v2/bson"
	"golang.org/x/crypto/bcrypt"

	"timetribe-backend/internal/config"
	"timetribe-backend/internal/models"
	"timetribe-backend/internal/repository"
	"timetribe-backend/internal/utils"
)

const minPasswordLength = 6

type AuthService struct {
	cfg      *config.Config
	store    *repository.Store
	jwt      *JWTManager
	firebase *FirebaseService
	mailer   *Mailer
	notifier *NotificationService
}

// NewAuthService tạo service đăng nhập, đăng ký, đổi mật khẩu.
func NewAuthService(cfg *config.Config, store *repository.Store, jwt *JWTManager, fb *FirebaseService, mailer *Mailer, n *NotificationService) *AuthService {
	return &AuthService{cfg: cfg, store: store, jwt: jwt, firebase: fb, mailer: mailer, notifier: n}
}

// AuthResult là dữ liệu trả về sau khi đăng nhập thành công.
type AuthResult struct {
	AccessToken  string      `json:"access_token"`
	RefreshToken string      `json:"refresh_token"`
	TokenType    string      `json:"token_type"`
	ExpiresIn    int         `json:"expires_in"`
	User         *MeResponse `json:"user"`
}

// MeResponse là hồ sơ của chính người dùng: bảng users + vài cột của user_securities.
type MeResponse struct {
	models.User
	Role         string `json:"role"`
	AuthProvider string `json:"auth_provider"`
	HasPassword  bool   `json:"has_password"`
	TimezoneAuto bool   `json:"timezone_auto"`
	// Email mới đang chờ người dùng bấm link xác nhận (null nếu không có)
	PendingEmail *string `json:"pending_email"`
}

// buildMe ghép users và user_securities thành dữ liệu trả về cho app.
func buildMe(u *models.User, sec *models.UserSecurity) *MeResponse {
	return &MeResponse{User: *u, Role: sec.Role, AuthProvider: sec.AuthProvider, HasPassword: sec.PasswordHash != nil,
		TimezoneAuto: u.IsTimezoneAuto()}
}

type RegisterInput struct {
	NickName        string `json:"nick_name"`
	Email           string `json:"email"`
	Password        string `json:"password"`
	ConfirmPassword string `json:"confirm_password"`
	Timezone        string `json:"timezone"`
}

// Register (AU-01): kiểm tra dữ liệu, email và nick_name chưa ai dùng, băm mật khẩu rồi lưu
// vào users + user_securities. Không tự đăng nhập, app sẽ quay về màn hình đăng nhập.
func (s *AuthService) Register(ctx context.Context, in RegisterInput) (*MeResponse, error) {
	nick := strings.TrimSpace(in.NickName)
	email := strings.ToLower(strings.TrimSpace(in.Email))
	fields := map[string]string{}
	if nick == "" {
		fields["nick_name"] = "name_required"
	} else if utils.Len(nick) < 2 || utils.Len(nick) > 100 {
		fields["nick_name"] = "name_length"
	}
	if email == "" {
		fields["email"] = "email_required"
	} else if !utils.IsEmail(email) {
		fields["email"] = "email_invalid"
	}
	if in.Password == "" {
		fields["password"] = "create_password_required"
	} else if len(in.Password) < minPasswordLength {
		fields["password"] = "password_too_short"
	}
	if in.ConfirmPassword != in.Password {
		fields["confirm_password"] = "password_mismatch"
	}
	if len(fields) > 0 {
		return nil, utils.BadRequest("validation_error", "Thông tin đăng ký chưa hợp lệ").WithDetails(fields)
	}
	if err := emailDomainError(email); err != nil {
		return nil, err
	}

	if err := s.ensureUnique(ctx, "", email, nick); err != nil {
		return nil, err
	}

	tz := in.Timezone
	if !utils.IsValidTimezone(tz) {
		tz = models.DefaultTimezone
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(in.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}
	now := time.Now().UTC()
	user := models.User{ID: uuid.NewString(), Email: email, NickName: nick, Timezone: tz, NeedsOnboarding: true, CreatedAt: now, UpdatedAt: now}
	sec := models.UserSecurity{
		UserID: user.ID, Role: models.RoleCustomer, AuthProvider: models.ProviderLocal,
		PasswordHash: utils.Ptr(string(hash)), PasswordChangedAt: &now,
	}
	if _, err := s.store.Users.InsertOne(ctx, user); err != nil {
		if repository.IsDuplicateKey(err) {
			return nil, utils.Conflict("account_exists", "Email hoặc tên hiển thị đã được sử dụng")
		}
		return nil, err
	}
	if _, err := s.store.UserSecurities.InsertOne(ctx, sec); err != nil {
		// Không có transaction trên MongoDB chạy đơn lẻ nên tự dọn bản ghi users vừa tạo
		_, _ = s.store.Users.DeleteOne(ctx, repository.ByID(user.ID))
		return nil, err
	}
	return buildMe(&user, &sec), nil
}

// ensureUnique báo lỗi nếu email hoặc nick_name đã thuộc về người khác (bỏ qua chính exceptID).
func (s *AuthService) ensureUnique(ctx context.Context, exceptID, email, nick string) error {
	fields := map[string]string{}
	check := func(field, value string) error {
		if value == "" {
			return nil
		}
		filter := bson.M{field: value}
		if exceptID != "" {
			filter["_id"] = bson.M{"$ne": exceptID}
		}
		n, err := s.store.Users.CountDocuments(ctx, filter)
		if err != nil {
			return err
		}
		if n > 0 {
			fields[field] = "already_taken"
		}
		return nil
	}
	if err := check("email", email); err != nil {
		return err
	}
	if err := check("nick_name", nick); err != nil {
		return err
	}
	if len(fields) > 0 {
		return utils.Conflict("account_exists", "Email hoặc tên hiển thị đã được sử dụng").WithDetails(fields)
	}
	return nil
}

type LoginInput struct {
	Identifier string `json:"identifier"` // email hoặc nick_name
	Password   string `json:"password"`
	RememberMe bool   `json:"remember_me"`
	FCMToken   string `json:"fcm_token"` // mã nhận thông báo đẩy của máy, không có thì để trống
	DeviceInfo string `json:"device_info"`
}

// Login (AU-02): tìm theo email hoặc nick_name, kiểm tra khoá/xoá, so mật khẩu rồi cấp token.
func (s *AuthService) Login(ctx context.Context, in LoginInput) (*AuthResult, error) {
	id := strings.TrimSpace(in.Identifier)
	fields := map[string]string{}
	if id == "" {
		fields["identifier"] = "identifier_required"
	}
	if strings.TrimSpace(in.Password) == "" {
		fields["password"] = "password_required"
	}
	if len(fields) > 0 {
		return nil, utils.BadRequest("validation_error", "Vui lòng nhập đủ thông tin đăng nhập").WithDetails(fields)
	}

	// Gom chung lỗi sai tài khoản và sai mật khẩu để tránh bị dò tài khoản
	wrong := utils.Unauthorized("wrong_credentials", "Tài khoản hoặc mật khẩu không đúng")

	user, err := repository.FindOne[models.User](ctx, s.store.Users, bson.M{
		"$or": bson.A{bson.M{"email": strings.ToLower(id)}, bson.M{"nick_name": id}},
	})
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, wrong
	}
	sec, err := s.store.SecurityByUserID(ctx, user.ID)
	if err != nil {
		return nil, err
	}
	if sec == nil {
		return nil, wrong
	}
	if err := checkAccountState(sec); err != nil {
		return nil, err
	}
	if sec.PasswordHash == nil {
		return nil, utils.Unauthorized("google_account", "Tài khoản này đăng nhập bằng Google, vui lòng chọn Đăng nhập bằng Google")
	}
	if bcrypt.CompareHashAndPassword([]byte(*sec.PasswordHash), []byte(in.Password)) != nil {
		return nil, wrong
	}
	return s.startSession(ctx, user, sec, in.RememberMe, in.DeviceInfo, in.FCMToken)
}

// startSession dùng chung cho đăng nhập thường và đăng nhập Google.
// Mỗi tài khoản chỉ được đăng nhập trên một máy, nên trước khi cấp token mới thì xoá hết
// các phiên cũ, máy cũ sẽ bị đăng xuất ở request kế tiếp.
// fcm_token cũng ghi đè theo máy mới, máy mới không gửi thì để null để máy cũ thôi nhận thông báo.
func (s *AuthService) startSession(ctx context.Context, user *models.User, sec *models.UserSecurity, remember bool, device, fcmToken string) (*AuthResult, error) {
	if _, err := s.store.UserTokens.DeleteMany(ctx, bson.M{"user_id": user.ID, "token_type": models.TokenRefresh}); err != nil {
		return nil, err
	}
	fcmToken = strings.TrimSpace(fcmToken)
	if fcmToken != "" {
		if err := s.notifier.SaveFCMToken(ctx, user.ID, fcmToken); err != nil {
			return nil, err
		}
		user.FCMToken = &fcmToken
	} else {
		if err := s.notifier.ClearFCMToken(ctx, user.ID); err != nil {
			return nil, err
		}
		user.FCMToken = nil
	}
	return s.issueTokens(ctx, user, sec, remember, device)
}

// checkAccountState chặn tài khoản bị khoá hoặc đã xoá.
func checkAccountState(sec *models.UserSecurity) error {
	if sec.DeleteAt != nil {
		return utils.Forbidden("account_deleted", "Tài khoản đã bị xoá")
	}
	if sec.IsBanned {
		reason := ""
		if sec.BanReason != nil {
			reason = *sec.BanReason
		}
		return utils.Forbidden("account_banned", "Tài khoản đang bị khoá").WithDetails(map[string]string{"ban_reason": reason})
	}
	return nil
}

// issueTokens tạo một phiên mới: lưu refresh token (bản băm) vào user_tokens,
// rồi tạo access token có gắn id của phiên đó.
func (s *AuthService) issueTokens(ctx context.Context, user *models.User, sec *models.UserSecurity, remember bool, device string) (*AuthResult, error) {
	refresh := utils.RandomToken(32)
	ttl := s.cfg.RefreshTokenTTL
	if remember {
		ttl = s.cfg.RememberMeTTL
	}
	now := time.Now().UTC()
	tok := models.UserToken{
		ID: uuid.NewString(), UserID: user.ID, Token: utils.HashToken(refresh),
		TokenType: models.TokenRefresh, DeviceInfo: utils.TrimPtr(&device),
		ExpiresAt: now.Add(ttl), CreatedAt: now,
	}
	if _, err := s.store.UserTokens.InsertOne(ctx, tok); err != nil {
		return nil, err
	}
	access, err := s.jwt.Issue(user.ID, sec.Role, tok.ID)
	if err != nil {
		return nil, err
	}
	return &AuthResult{
		AccessToken: access, RefreshToken: refresh, TokenType: "Bearer",
		ExpiresIn: int(s.jwt.TTL().Seconds()), User: buildMe(user, sec),
	}, nil
}

type GoogleLoginInput struct {
	IDToken    string `json:"id_token"`
	FCMToken   string `json:"fcm_token"` // mã nhận thông báo đẩy của máy, không có thì để trống
	DeviceInfo string `json:"device_info"`
	Timezone   string `json:"timezone"`
}

// GoogleLogin (AU-03): app đăng nhập Google qua Firebase Auth rồi gửi Firebase ID token lên.
// Server xác thực token bằng Firebase Admin SDK, tìm theo google_id rồi tới email,
// chưa có thì tạo mới users + user_securities với auth_provider = google.
func (s *AuthService) GoogleLogin(ctx context.Context, in GoogleLoginInput) (*AuthResult, error) {
	if !s.firebase.AuthEnabled() {
		return nil, utils.NewError(http.StatusServiceUnavailable, "google_disabled", "Máy chủ chưa cấu hình Firebase")
	}
	if strings.TrimSpace(in.IDToken) == "" {
		return nil, utils.BadRequest("validation_error", "Thiếu id_token")
	}
	token, err := s.firebase.Auth.VerifyIDToken(ctx, in.IDToken)
	if err != nil {
		return nil, utils.Unauthorized("invalid_google_token", "Token Google không hợp lệ hoặc đã hết hạn")
	}

	email, _ := token.Claims["email"].(string)
	email = strings.ToLower(email)
	name, _ := token.Claims["name"].(string)
	picture, _ := token.Claims["picture"].(string)
	if email == "" {
		return nil, utils.BadRequest("email_missing", "Tài khoản Google không cung cấp email")
	}
	// Ưu tiên mã định danh Google gốc (sub), không có thì dùng uid của Firebase
	googleID := token.UID
	if ids, ok := token.Firebase.Identities["google.com"].([]any); ok && len(ids) > 0 {
		if v, ok := ids[0].(string); ok {
			googleID = v
		}
	}

	sec, err := repository.FindOne[models.UserSecurity](ctx, s.store.UserSecurities, bson.M{"google_id": googleID})
	if err != nil {
		return nil, err
	}
	var user *models.User
	if sec != nil {
		if user, err = s.store.UserByID(ctx, sec.UserID); err != nil {
			return nil, err
		}
	}
	if user == nil {
		// Có tài khoản cùng email đăng ký thường trước đó: gắn google_id vào luôn
		if user, err = repository.FindOne[models.User](ctx, s.store.Users, bson.M{"email": email}); err != nil {
			return nil, err
		}
		if user != nil {
			if sec, err = s.store.SecurityByUserID(ctx, user.ID); err != nil {
				return nil, err
			}
			if sec != nil && sec.DeleteAt == nil {
				_, err = s.store.UserSecurities.UpdateOne(ctx, repository.ByID(user.ID), bson.M{"$set": bson.M{"google_id": googleID}})
				if err != nil {
					return nil, err
				}
				sec.GoogleID = &googleID
			}
		}
	}

	if user == nil {
		user, sec, err = s.createGoogleUser(ctx, email, name, picture, googleID, in.Timezone)
		if err != nil {
			return nil, err
		}
	}
	if sec == nil {
		return nil, utils.Internal("Tài khoản thiếu thông tin bảo mật")
	}
	if err := checkAccountState(sec); err != nil {
		return nil, err
	}
	return s.startSession(ctx, user, sec, true, in.DeviceInfo, in.FCMToken)
}

// createGoogleUser tạo tài khoản mới cho người đăng nhập Google lần đầu, tên trùng thì thêm vài số phía sau.
func (s *AuthService) createGoogleUser(ctx context.Context, email, name, picture, googleID, tz string) (*models.User, *models.UserSecurity, error) {
	base := strings.TrimSpace(name)
	if base == "" {
		base = strings.Split(email, "@")[0]
	}
	if utils.Len(base) > 90 {
		base = string([]rune(base)[:90])
	}
	// nick_name là unique nên trùng thì thêm vài số phía sau
	nick := base
	for i := 0; i < 5; i++ {
		n, err := s.store.Users.CountDocuments(ctx, bson.M{"nick_name": nick})
		if err != nil {
			return nil, nil, err
		}
		if n == 0 {
			break
		}
		nick = fmt.Sprintf("%s %s", base, utils.RandomCode(4, "0123456789"))
	}
	if !utils.IsValidTimezone(tz) {
		tz = models.DefaultTimezone
	}
	now := time.Now().UTC()
	user := &models.User{ID: uuid.NewString(), Email: email, NickName: nick, Timezone: tz, NeedsOnboarding: true, CreatedAt: now, UpdatedAt: now}
	if picture != "" {
		user.AvatarURL = &picture
	}
	sec := &models.UserSecurity{
		UserID: user.ID, Role: models.RoleCustomer, AuthProvider: models.ProviderGoogle, GoogleID: &googleID,
	}
	if _, err := s.store.Users.InsertOne(ctx, user); err != nil {
		return nil, nil, err
	}
	if _, err := s.store.UserSecurities.InsertOne(ctx, sec); err != nil {
		_, _ = s.store.Users.DeleteOne(ctx, repository.ByID(user.ID))
		return nil, nil, err
	}
	return user, sec, nil
}

// Refresh đổi refresh token cũ lấy cặp token mới. Vẫn giữ nguyên phiên (id dòng user_tokens),
// chỉ thay chuỗi refresh token, nên máy đang dùng không bị coi là đăng nhập ở máy khác.
func (s *AuthService) Refresh(ctx context.Context, refreshToken string) (*AuthResult, error) {
	invalid := utils.Unauthorized("invalid_refresh_token", "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại")
	if refreshToken == "" {
		return nil, invalid
	}
	tok, err := repository.FindOne[models.UserToken](ctx, s.store.UserTokens, bson.M{
		"token": utils.HashToken(refreshToken), "token_type": models.TokenRefresh,
	})
	if err != nil {
		return nil, err
	}
	if tok == nil || tok.ExpiresAt.Before(time.Now()) {
		return nil, invalid
	}
	user, err := s.store.UserByID(ctx, tok.UserID)
	if err != nil || user == nil {
		return nil, invalid
	}
	sec, err := s.store.SecurityByUserID(ctx, user.ID)
	if err != nil || sec == nil {
		return nil, invalid
	}
	if err := checkAccountState(sec); err != nil {
		return nil, err
	}
	newRefresh := utils.RandomToken(32)
	if _, err := s.store.UserTokens.UpdateOne(ctx, repository.ByID(tok.ID), bson.M{"$set": bson.M{"token": utils.HashToken(newRefresh)}}); err != nil {
		return nil, err
	}
	access, err := s.jwt.Issue(user.ID, sec.Role, tok.ID)
	if err != nil {
		return nil, err
	}
	return &AuthResult{
		AccessToken: access, RefreshToken: newRefresh, TokenType: "Bearer",
		ExpiresIn: int(s.jwt.TTL().Seconds()), User: buildMe(user, sec),
	}, nil
}

// Logout (AU-06): xoá phiên đăng nhập hiện tại và đặt fcm_token về null
// để máy đã đăng xuất không nhận thông báo của tài khoản này nữa.
// Máy đó đăng nhập tài khoản khác ngay sau đó vẫn được, fcm_token sẽ gắn sang tài khoản mới.
func (s *AuthService) Logout(ctx context.Context, userID, sessionID string) error {
	_, err := s.store.UserTokens.DeleteOne(ctx, bson.M{"_id": sessionID, "user_id": userID, "token_type": models.TokenRefresh})
	if err != nil {
		return err
	}
	return s.notifier.ClearFCMToken(ctx, userID)
}

// ForgotPassword (AU-04 bước 1-3): tạo token khôi phục và gửi email.
// Luôn trả thành công dù email có tồn tại hay không, tránh lộ danh sách tài khoản.
// Ở môi trường dev chưa có SMTP thì trả kèm token để test trên Postman.
func (s *AuthService) ForgotPassword(ctx context.Context, email, language string) (map[string]any, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	if !utils.IsEmail(email) {
		return nil, utils.BadRequest("validation_error", "Email không hợp lệ").WithDetails(map[string]string{"email": "email_invalid"})
	}
	result := map[string]any{}
	user, err := repository.FindOne[models.User](ctx, s.store.Users, bson.M{"email": email})
	if err != nil {
		return nil, err
	}
	if user == nil {
		return result, nil
	}
	sec, err := s.store.SecurityByUserID(ctx, user.ID)
	if err != nil || sec == nil || checkAccountState(sec) != nil {
		return result, nil
	}

	// Mỗi người chỉ giữ một token khôi phục còn hiệu lực
	_, _ = s.store.UserTokens.DeleteMany(ctx, bson.M{"user_id": user.ID, "token_type": models.TokenResetPassword})
	raw := utils.RandomToken(32)
	now := time.Now().UTC()
	tok := models.UserToken{
		ID: uuid.NewString(), UserID: user.ID, Token: utils.HashToken(raw), TokenType: models.TokenResetPassword,
		ExpiresAt: now.Add(s.cfg.ResetTokenTTL), CreatedAt: now,
	}
	if _, err := s.store.UserTokens.InsertOne(ctx, tok); err != nil {
		return nil, err
	}
	// Ngôn ngữ email: ngôn ngữ app đang dùng lúc bấm "Quên mật khẩu" (chưa đăng nhập nên app gửi kèm),
	// không có thì theo ngôn ngữ đã lưu của tài khoản
	lang := user.Language
	if strings.TrimSpace(language) != "" {
		lang = language
	}
	link := withLang(fmt.Sprintf("%s?token=%s", s.cfg.ResetPasswordURL, raw), lang)
	subject, body := MailText(lang, mailResetPassword, map[string]string{
		"name": user.NickName, "minutes": fmt.Sprint(int(s.cfg.ResetTokenTTL.Minutes())), "link": link,
	})
	if err := s.mailer.Send(user.Email, subject, body); err != nil {
		log.Println(err)
	}
	if s.cfg.IsDev() && !s.mailer.Enabled() {
		result["debug_reset_token"] = raw
		result["debug_reset_link"] = link
	}
	return result, nil
}

type ResetPasswordInput struct {
	Token           string `json:"token"`
	NewPassword     string `json:"new_password"`
	ConfirmPassword string `json:"confirm_password"`
}

// ResetPassword (AU-04 bước 4-7): kiểm tra token, đổi mật khẩu, xoá token khôi phục và mọi phiên đăng nhập.
func (s *AuthService) ResetPassword(ctx context.Context, in ResetPasswordInput) error {
	if err := validateNewPassword(in.NewPassword, in.ConfirmPassword); err != nil {
		return err
	}
	tok, err := repository.FindOne[models.UserToken](ctx, s.store.UserTokens, bson.M{
		"token": utils.HashToken(strings.TrimSpace(in.Token)), "token_type": models.TokenResetPassword,
	})
	if err != nil {
		return err
	}
	if tok == nil || tok.ExpiresAt.Before(time.Now()) {
		return utils.BadRequest("invalid_reset_token", "Đường dẫn đặt lại mật khẩu không hợp lệ hoặc đã hết hạn")
	}
	if err := s.setPassword(ctx, tok.UserID, in.NewPassword); err != nil {
		return err
	}
	_, err = s.store.UserTokens.DeleteMany(ctx, bson.M{
		"user_id": tok.UserID, "token_type": bson.M{"$in": bson.A{models.TokenResetPassword, models.TokenRefresh, models.TokenChangeEmail}},
	})
	if err != nil {
		return err
	}
	s.afterPasswordChanged(ctx, tok.UserID)
	return nil
}

type ChangePasswordInput struct {
	CurrentPassword string `json:"current_password"`
	NewPassword     string `json:"new_password"`
	ConfirmPassword string `json:"confirm_password"`
}

// ChangePassword (AU-05): đúng mật khẩu cũ mới cho đổi, đổi xong thu hồi toàn bộ refresh token.
// Tài khoản Google chưa có mật khẩu thì được đặt mật khẩu lần đầu mà không cần mật khẩu cũ.
func (s *AuthService) ChangePassword(ctx context.Context, userID string, in ChangePasswordInput) error {
	sec, err := s.store.SecurityByUserID(ctx, userID)
	if err != nil {
		return err
	}
	if sec == nil {
		return utils.NotFound("not_found_item", "Không tìm thấy tài khoản")
	}
	if sec.PasswordHash != nil {
		if in.CurrentPassword == "" {
			return utils.BadRequest("validation_error", "Vui lòng nhập mật khẩu hiện tại").WithDetails(map[string]string{"current_password": "password_required"})
		}
		if bcrypt.CompareHashAndPassword([]byte(*sec.PasswordHash), []byte(in.CurrentPassword)) != nil {
			return utils.BadRequest("wrong_current_password", "Mật khẩu hiện tại không đúng")
		}
		if in.CurrentPassword == in.NewPassword {
			return utils.BadRequest("same_password", "Mật khẩu mới phải khác mật khẩu hiện tại")
		}
	}
	if err := validateNewPassword(in.NewPassword, in.ConfirmPassword); err != nil {
		return err
	}
	if err := s.setPassword(ctx, userID, in.NewPassword); err != nil {
		return err
	}
	// Đăng xuất mọi thiết bị và huỷ yêu cầu đổi email đang chờ (xem afterPasswordChanged)
	_, err = s.store.UserTokens.DeleteMany(ctx, bson.M{
		"user_id": userID, "token_type": bson.M{"$in": bson.A{models.TokenRefresh, models.TokenChangeEmail}},
	})
	if err != nil {
		return err
	}
	s.afterPasswordChanged(ctx, userID)
	return nil
}

// afterPasswordChanged gửi email báo mật khẩu vừa đổi tới email hiện tại của tài khoản.
//
// Đổi hoặc đặt lại mật khẩu cũng huỷ luôn yêu cầu đổi email đang chờ xác nhận (token change_email):
// người đổi mật khẩu thường là vì nghi tài khoản bị lộ, mà yêu cầu đổi email kia có thể do kẻ xấu tạo
// lúc còn giữ phiên đăng nhập. Nếu chính chủ vẫn muốn đổi email thì đăng nhập lại và gửi yêu cầu mới.
func (s *AuthService) afterPasswordChanged(ctx context.Context, userID string) {
	u, err := s.store.UserByID(ctx, userID)
	if err != nil || u == nil {
		return
	}
	subject, body := MailText(u.Language, mailPasswordChange, map[string]string{
		"name": u.NickName, "time": time.Now().UTC().Format("15:04 02/01/2006"),
	})
	if err := s.mailer.Send(u.Email, subject, body); err != nil {
		log.Println(err)
	}
}

// emailDomainError bắt lỗi gõ nhầm tên miền email (VD gmial.com) hoặc tên miền không nhận thư.
// Lỗi trả về có details {"email": mã lỗi, "email_suggestion": email gợi ý} để app hiện "Có phải ý bạn là ...?".
func emailDomainError(email string) error {
	code, suggestion := utils.CheckEmailDomain(email)
	switch code {
	case utils.EmailTypo:
		return utils.BadRequest("validation_error", "Email có vẻ bị gõ nhầm, có phải ý bạn là "+suggestion+"?").
			WithDetails(map[string]string{"email": code, "email_suggestion": suggestion})
	case utils.EmailDomainInvalid:
		return utils.BadRequest("validation_error", "Tên miền của email không nhận được thư, vui lòng kiểm tra lại").
			WithDetails(map[string]string{"email": code})
	}
	return nil
}

// validateNewPassword kiểm tra mật khẩu mới đủ dài và khớp với ô xác nhận.
func validateNewPassword(pw, confirm string) error {
	fields := map[string]string{}
	if len(pw) < minPasswordLength {
		fields["new_password"] = "password_too_short"
	}
	if pw != confirm {
		fields["confirm_password"] = "password_mismatch"
	}
	if len(fields) > 0 {
		return utils.BadRequest("validation_error", fmt.Sprintf("Mật khẩu mới tối thiểu %d ký tự và phải khớp với ô xác nhận", minPasswordLength)).WithDetails(fields)
	}
	return nil
}

// setPassword cập nhật password_hash và password_changed_at.
// Mọi access token phát hành trước mốc này sẽ bị middleware từ chối.
func (s *AuthService) setPassword(ctx context.Context, userID, pw string) error {
	hash, err := bcrypt.GenerateFromPassword([]byte(pw), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	_, err = s.store.UserSecurities.UpdateOne(ctx, repository.ByID(userID), bson.M{"$set": bson.M{
		"password_hash": string(hash), "password_changed_at": time.Now().UTC(),
	}})
	return err
}
