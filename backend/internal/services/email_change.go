package services

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/v2/bson"

	"timetribe-backend/internal/models"
	"timetribe-backend/internal/repository"
	"timetribe-backend/internal/utils"
)

const (
	// emailChangeTTL: link xác nhận email mới còn hiệu lực trong 24 giờ.
	emailChangeTTL = 24 * time.Hour
	// emailChangeCooldown: chặn bấm gửi lại liên tục (tránh spam hộp thư người khác).
	emailChangeCooldown = time.Minute
)

// Đổi email (INFO-01) theo hai bước:
//  1. PATCH /users/me có email mới: server KHÔNG đổi ngay, chỉ tạo token change_email (lưu bản băm,
//     kèm new_email) rồi gửi link xác nhận tới email mới, đồng thời báo cho email cũ.
//  2. Người dùng mở link GET /auth/confirm-email?token=... từ hộp thư mới: server kiểm tra token,
//     email chưa ai dùng, rồi mới lưu email mới.
//
// Như vậy không ai đổi được sang email mình không sở hữu. Điều này quan trọng vì đăng nhập Google
// gắn tài khoản theo email: nếu cho đổi tự do, kẻ xấu đặt email của nạn nhân vào tài khoản của mình,
// nạn nhân đăng nhập Google sẽ vào nhầm tài khoản đó.

// requestEmailChange tạo token xác nhận và gửi email tới địa chỉ mới.
func (s *UserService) requestEmailChange(ctx context.Context, u *models.User, newEmail string) error {
	last, err := repository.FindOne[models.UserToken](ctx, s.store.UserTokens,
		bson.M{"user_id": u.ID, "token_type": models.TokenChangeEmail})
	if err != nil {
		return err
	}
	now := time.Now().UTC()
	if last != nil && last.NewEmail != nil && *last.NewEmail == newEmail && now.Sub(last.CreatedAt) < emailChangeCooldown {
		return utils.NewError(http.StatusTooManyRequests, "too_many_requests",
			"Vừa gửi email xác nhận, vui lòng đợi một phút rồi thử lại")
	}
	// Mỗi người chỉ giữ một yêu cầu đổi email, yêu cầu mới thay yêu cầu cũ
	if _, err := s.store.UserTokens.DeleteMany(ctx, bson.M{"user_id": u.ID, "token_type": models.TokenChangeEmail}); err != nil {
		return err
	}
	raw := utils.RandomToken(32)
	tok := models.UserToken{
		ID: uuid.NewString(), UserID: u.ID, Token: utils.HashToken(raw), TokenType: models.TokenChangeEmail,
		NewEmail: utils.Ptr(newEmail), ExpiresAt: now.Add(emailChangeTTL), CreatedAt: now,
	}
	if _, err := s.store.UserTokens.InsertOne(ctx, tok); err != nil {
		return err
	}

	link := fmt.Sprintf("%s/api/v1/auth/confirm-email?token=%s", s.auth.cfg.BaseURL, raw)
	body := fmt.Sprintf("Chào %s,\n\nBạn vừa yêu cầu đổi email đăng nhập TimeTribe sang địa chỉ này.\n"+
		"Mở đường dẫn sau trong vòng 24 giờ để xác nhận:\n%s\n\n"+
		"Nếu không phải bạn yêu cầu, hãy bỏ qua email này, email của tài khoản sẽ không thay đổi.\n\nTimeTribe",
		u.NickName, link)
	if err := s.auth.mailer.Send(newEmail, "Xác nhận email mới cho TimeTribe", body); err != nil {
		log.Println(err)
		_, _ = s.store.UserTokens.DeleteOne(ctx, bson.M{"_id": tok.ID})
		return utils.NewError(http.StatusBadGateway, "email_send_failed", "Không gửi được email xác nhận, vui lòng thử lại")
	}
	// Báo cho email cũ để chủ tài khoản biết nếu có người khác đang đổi email
	notice := fmt.Sprintf("Chào %s,\n\nCó yêu cầu đổi email đăng nhập TimeTribe của bạn sang %s.\n"+
		"Email chỉ thay đổi khi địa chỉ mới bấm link xác nhận.\n"+
		"Nếu không phải bạn, hãy đổi mật khẩu ngay.\n\nTimeTribe", u.NickName, newEmail)
	if err := s.auth.mailer.Send(u.Email, "Yêu cầu đổi email TimeTribe", notice); err != nil {
		log.Println(err)
	}
	return nil
}

// pendingEmail trả email mới đang chờ xác nhận của người dùng, không có thì nil.
func (s *UserService) pendingEmail(ctx context.Context, userID string) *string {
	tok, err := repository.FindOne[models.UserToken](ctx, s.store.UserTokens, bson.M{
		"user_id": userID, "token_type": models.TokenChangeEmail, "expires_at": bson.M{"$gt": time.Now().UTC()},
	})
	if err != nil || tok == nil {
		return nil
	}
	return tok.NewEmail
}

// CancelEmailChange huỷ yêu cầu đổi email đang chờ.
func (s *UserService) CancelEmailChange(ctx context.Context, userID string) (*MeResponse, error) {
	if _, err := s.store.UserTokens.DeleteMany(ctx, bson.M{"user_id": userID, "token_type": models.TokenChangeEmail}); err != nil {
		return nil, err
	}
	return s.Me(ctx, userID)
}

// ConfirmEmailChange (bước 2): kiểm tra token trong link rồi lưu email mới. Trả về email mới.
func (s *UserService) ConfirmEmailChange(ctx context.Context, raw string) (string, error) {
	invalid := utils.BadRequest("invalid_token", "Link xác nhận không hợp lệ hoặc đã được dùng")
	if raw == "" {
		return "", invalid
	}
	tok, err := repository.FindOne[models.UserToken](ctx, s.store.UserTokens, bson.M{
		"token": utils.HashToken(raw), "token_type": models.TokenChangeEmail,
	})
	if err != nil {
		return "", err
	}
	if tok == nil || tok.NewEmail == nil {
		return "", invalid
	}
	if time.Now().UTC().After(tok.ExpiresAt) {
		_, _ = s.store.UserTokens.DeleteOne(ctx, bson.M{"_id": tok.ID})
		return "", utils.BadRequest("token_expired", "Link xác nhận đã hết hạn, hãy đổi email lại trong ứng dụng")
	}
	email := *tok.NewEmail
	if err := s.auth.ensureUnique(ctx, tok.UserID, email, ""); err != nil {
		return "", utils.Conflict("account_exists", "Email này đã được tài khoản khác sử dụng")
	}
	_, err = s.store.Users.UpdateOne(ctx, repository.ByID(tok.UserID),
		bson.M{"$set": bson.M{"email": email, "updated_at": time.Now().UTC()}})
	if err != nil {
		if repository.IsDuplicateKey(err) {
			return "", utils.Conflict("account_exists", "Email này đã được tài khoản khác sử dụng")
		}
		return "", err
	}
	_, _ = s.store.UserTokens.DeleteMany(ctx, bson.M{"user_id": tok.UserID, "token_type": models.TokenChangeEmail})
	return email, nil
}
