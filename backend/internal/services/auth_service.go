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
}

func NewAuthService(cfg *config.Config, store *repository.Store, jwt *JWTManager, fb *FirebaseService, mailer *Mailer) *AuthService {
	return &AuthService{cfg: cfg, store: store, jwt: jwt, firebase: fb, mailer: mailer}
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
}

func buildMe(u *models.User, sec *models.UserSecurity) *MeResponse {
	return &MeResponse{User: *u, Role: sec.Role, AuthProvider: sec.AuthProvider, HasPassword: sec.PasswordHash != nil}
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
	user := models.User{ID: uuid.NewString(), Email: email, NickName: nick, Timezone: tz, CreatedAt: now, UpdatedAt: now}
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
	return s.issueTokens(ctx, user, sec, in.RememberMe, in.DeviceInfo)
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

// issueTokens tạo access token (JWT) và refresh token (lưu bản băm vào user_tokens).
func (s *AuthService) issueTokens(ctx context.Context, user *models.User, sec *models.UserSecurity, remember bool, device string) (*AuthResult, error) {
	access, err := s.jwt.Issue(user.ID, sec.Role)
	if err != nil {
		return nil, err
	}
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
	return &AuthResult{
		AccessToken: access, RefreshToken: refresh, TokenType: "Bearer",
		ExpiresIn: int(s.jwt.TTL().Seconds()), User: buildMe(user, sec),
	}, nil
}

type GoogleLoginInput struct {
	IDToken    string `json:"id_token"`
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
	return s.issueTokens(ctx, user, sec, true, in.DeviceInfo)
}

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
	user := &models.User{ID: uuid.NewString(), Email: email, NickName: nick, Timezone: tz, CreatedAt: now, UpdatedAt: now}
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

// Refresh đổi refresh token cũ lấy cặp token mới (token cũ bị xoá luôn).
func (s *AuthService) Refresh(ctx context.Context, refreshToken, device string) (*AuthResult, error) {
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
	_, _ = s.store.UserTokens.DeleteOne(ctx, repository.ByID(tok.ID))

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
	// Giữ nguyên thời hạn "ghi nhớ đăng nhập" nếu token cũ là loại dài hạn
	remember := tok.ExpiresAt.Sub(tok.CreatedAt) > s.cfg.RefreshTokenTTL
	if device == "" && tok.DeviceInfo != nil {
		device = *tok.DeviceInfo
	}
	return s.issueTokens(ctx, user, sec, remember, device)
}

// Logout (AU-06): xoá refresh token của thiết bị hiện tại, kèm mã FCM nếu app gửi lên.
func (s *AuthService) Logout(ctx context.Context, userID, refreshToken, fcmToken string) error {
	if refreshToken != "" {
		_, err := s.store.UserTokens.DeleteOne(ctx, bson.M{
			"user_id": userID, "token": utils.HashToken(refreshToken), "token_type": models.TokenRefresh,
		})
		if err != nil {
			return err
		}
	}
	if fcmToken != "" {
		_, _ = s.store.UserTokens.DeleteOne(ctx, bson.M{"user_id": userID, "token": fcmToken, "token_type": models.TokenFCM})
	}
	return nil
}

// ForgotPassword (AU-04 bước 1-3): tạo token khôi phục và gửi email.
// Luôn trả thành công dù email có tồn tại hay không, tránh lộ danh sách tài khoản.
// Ở môi trường dev chưa có SMTP thì trả kèm token để test trên Postman.
func (s *AuthService) ForgotPassword(ctx context.Context, email string) (map[string]any, error) {
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
	link := fmt.Sprintf("%s?token=%s", s.cfg.ResetPasswordURL, raw)
	body := fmt.Sprintf("Chào %s,\n\nBạn vừa yêu cầu đặt lại mật khẩu TimeTribe. Mở đường dẫn sau trong vòng %d phút để đặt mật khẩu mới:\n%s\n\nNếu không phải bạn yêu cầu, hãy bỏ qua email này.\n\nTimeTribe",
		user.NickName, int(s.cfg.ResetTokenTTL.Minutes()), link)
	if err := s.mailer.Send(user.Email, "Đặt lại mật khẩu TimeTribe", body); err != nil {
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
		"user_id": tok.UserID, "token_type": bson.M{"$in": bson.A{models.TokenResetPassword, models.TokenRefresh}},
	})
	return err
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
	_, err = s.store.UserTokens.DeleteMany(ctx, bson.M{"user_id": userID, "token_type": models.TokenRefresh})
	return err
}

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
