package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/v2/bson"

	"timetribe-backend/internal/models"
	"timetribe-backend/internal/services"
	"timetribe-backend/internal/utils"
)

const (
	CtxUserID    = "user_id"
	CtxRole      = "role"
	CtxSessionID = "session_id"
)

// Auth kiểm tra header "Authorization: Bearer <access_token>".
// Ngoài chữ ký JWT còn đọc user_securities để chặn tài khoản bị khoá, đã xoá,
// hoặc token được cấp trước lần đổi mật khẩu gần nhất.
func Auth(svc *services.Services) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if !strings.HasPrefix(header, "Bearer ") {
			utils.Fail(c, utils.Unauthorized("missing_token", "Bạn cần đăng nhập để dùng chức năng này"))
			return
		}
		claims, err := svc.JWT.Parse(strings.TrimPrefix(header, "Bearer "))
		if err != nil {
			utils.Fail(c, utils.Unauthorized("invalid_token", "Phiên đăng nhập không hợp lệ hoặc đã hết hạn"))
			return
		}
		sec, err := svc.Store.SecurityByUserID(c.Request.Context(), claims.Subject)
		if err != nil {
			utils.Fail(c, err)
			return
		}
		if sec == nil || sec.DeleteAt != nil {
			utils.Fail(c, utils.Unauthorized("account_deleted", "Tài khoản không còn tồn tại"))
			return
		}
		if sec.IsBanned {
			utils.Fail(c, utils.Forbidden("account_banned", "Tài khoản đang bị khoá"))
			return
		}
		if sec.PasswordChangedAt != nil && claims.IssuedAt != nil &&
			sec.PasswordChangedAt.After(claims.IssuedAt.Time) {
			utils.Fail(c, utils.Unauthorized("token_revoked", "Mật khẩu đã thay đổi, vui lòng đăng nhập lại"))
			return
		}
		// Phiên của token này phải còn trong user_tokens. Đã đăng xuất hoặc tài khoản vừa
		// đăng nhập ở máy khác thì phiên bị xoá, máy này phải đăng nhập lại.
		alive, err := svc.Store.UserTokens.CountDocuments(c.Request.Context(), bson.M{
			"_id": claims.ID, "user_id": claims.Subject, "token_type": models.TokenRefresh,
		})
		if err != nil {
			utils.Fail(c, err)
			return
		}
		if claims.ID == "" || alive == 0 {
			utils.Fail(c, utils.Unauthorized("session_ended", "Phiên đăng nhập đã kết thúc, có thể tài khoản vừa đăng nhập trên máy khác"))
			return
		}
		c.Set(CtxUserID, claims.Subject)
		c.Set(CtxRole, sec.Role)
		c.Set(CtxSessionID, claims.ID)
		c.Next()
	}
}

// AdminOnly chặn các API admin nếu người gọi không có role admin.
func AdminOnly() gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.GetString(CtxRole) != models.RoleAdmin {
			utils.Fail(c, utils.Forbidden("admin_only", "Chỉ admin mới dùng được chức năng này"))
			return
		}
		c.Next()
	}
}

// CORS mở cho mọi nguồn vì client chính là app di động, web chỉ dùng khi dev.
func CORS() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Headers", "Authorization, Content-Type")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}

// UserID lấy id người đang đăng nhập mà middleware Auth đã gắn vào request.
func UserID(c *gin.Context) string { return c.GetString(CtxUserID) }

// SessionID lấy id phiên đăng nhập hiện tại (dùng khi đăng xuất).
func SessionID(c *gin.Context) string { return c.GetString(CtxSessionID) }
