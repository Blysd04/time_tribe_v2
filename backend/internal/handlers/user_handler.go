package handlers

import (
	"errors"
	"html"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"timetribe-backend/internal/middleware"
	"timetribe-backend/internal/services"
	"timetribe-backend/internal/utils"
)

// GetMe xử lý GET /users/me.
func (h *Handler) GetMe(c *gin.Context) {
	me, err := h.svc.Users.Me(c.Request.Context(), middleware.UserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", me)
}

// UpdateMe xử lý PATCH /users/me: sửa tên, email, múi giờ.
func (h *Handler) UpdateMe(c *gin.Context) {
	var in services.UpdateMeInput
	if !utils.BindJSON(c, &in) {
		return
	}
	me, err := h.svc.Users.UpdateMe(c.Request.Context(), middleware.UserID(c), in)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã lưu thông tin", me)
}

// UploadAvatar xử lý POST /users/me/avatar, ảnh gửi ở form-data tên avatar.
func (h *Handler) UploadAvatar(c *gin.Context) {
	fh, err := c.FormFile("avatar")
	if err != nil {
		utils.Fail(c, utils.BadRequest("validation_error", "Gửi ảnh ở trường form-data tên là avatar"))
		return
	}
	me, err := h.svc.Users.UploadAvatar(c.Request.Context(), middleware.UserID(c), fh)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã cập nhật ảnh đại diện", me)
}

// DeletePlan xử lý GET /users/me/delete-preview: xem trước các nhóm sẽ bị chuyển quyền hoặc giải tán.
func (h *Handler) DeletePlan(c *gin.Context) {
	plans, err := h.svc.Users.DeletePlan(c.Request.Context(), middleware.UserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", plans)
}

// DeleteMe xử lý DELETE /users/me: xoá tài khoản kèm lý do.
func (h *Handler) DeleteMe(c *gin.Context) {
	var in struct {
		Reason string `json:"reason"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	plans, err := h.svc.Users.DeleteAccount(c.Request.Context(), middleware.UserID(c), in.Reason)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Tài khoản đã được xoá", gin.H{"tribes": plans})
}

// UpdateFCMToken xử lý PUT /users/me/fcm-token: app gửi mã FCM mới khi Firebase đổi mã.
func (h *Handler) UpdateFCMToken(c *gin.Context) {
	var in struct {
		FCMToken string `json:"fcm_token"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	if err := h.svc.Users.UpdateFCMToken(c.Request.Context(), middleware.UserID(c), in.FCMToken); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã cập nhật fcm_token", nil)
}

// TestPush xử lý POST /users/me/test-push: gửi thông báo đẩy thử tới máy của chính mình.
func (h *Handler) TestPush(c *gin.Context) {
	if err := h.svc.Notifications.TestPush(c.Request.Context(), middleware.UserID(c)); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã gửi thông báo thử", nil)
}

// ClearFCMToken xử lý DELETE /users/me/fcm-token.
func (h *Handler) ClearFCMToken(c *gin.Context) {
	if err := h.svc.Users.ClearFCMToken(c.Request.Context(), middleware.UserID(c)); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã xoá fcm_token", nil)
}

// CancelEmailChange xử lý DELETE /users/me/pending-email: huỷ yêu cầu đổi email đang chờ.
func (h *Handler) CancelEmailChange(c *gin.Context) {
	me, err := h.svc.Users.CancelEmailChange(c.Request.Context(), middleware.UserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã huỷ yêu cầu đổi email", me)
}

// ConfirmEmail xử lý GET /auth/confirm-email?token=...: người dùng bấm link trong email mới.
// Trả về trang HTML đơn giản vì link được mở bằng trình duyệt, không phải app.
func (h *Handler) ConfirmEmail(c *gin.Context) {
	lang := services.NormalizeLang(c.Query("lang"))
	t := confirmTexts[lang]
	email, err := h.svc.Users.ConfirmEmailChange(c.Request.Context(), c.Query("token"))
	if err != nil {
		msg := t["error"]
		var appErr *utils.AppError
		if errors.As(err, &appErr) {
			if m, ok := t[appErr.Code]; ok {
				msg = m
			}
		}
		confirmPage(c, http.StatusBadRequest, lang, false, msg)
		return
	}
	confirmPage(c, http.StatusOK, lang, true, strings.ReplaceAll(t["done"], "{email}", email))
}

// confirmTexts: câu chữ trang xác nhận email theo ngôn ngữ (lấy từ ?lang= trong link của email).
var confirmTexts = map[string]map[string]string{
	services.LangVI: {
		"title_ok": "Đã xác nhận email", "title_fail": "Không xác nhận được",
		"done":           "Email đăng nhập của bạn đã đổi thành {email}. Hãy mở lại ứng dụng TimeTribe.",
		"invalid_token":  "Link xác nhận không hợp lệ hoặc đã được dùng.",
		"token_expired":  "Link xác nhận đã hết hạn, hãy đổi email lại trong ứng dụng.",
		"account_exists": "Email này đã được tài khoản khác sử dụng.",
		"error":          "Có lỗi xảy ra, vui lòng thử lại sau.",
	},
	services.LangEN: {
		"title_ok": "Email confirmed", "title_fail": "Couldn't confirm",
		"done":           "Your sign-in email is now {email}. Open the TimeTribe app again.",
		"invalid_token":  "This confirmation link is invalid or has already been used.",
		"token_expired":  "This confirmation link has expired. Change your email again in the app.",
		"account_exists": "This email is already used by another account.",
		"error":          "Something went wrong, please try again later.",
	},
	services.LangFR: {
		"title_ok": "E-mail confirmé", "title_fail": "Confirmation impossible",
		"done":           "Votre e-mail de connexion est désormais {email}. Rouvrez l'application TimeTribe.",
		"invalid_token":  "Ce lien de confirmation n'est pas valide ou a déjà été utilisé.",
		"token_expired":  "Ce lien de confirmation a expiré. Modifiez à nouveau votre e-mail dans l'application.",
		"account_exists": "Cet e-mail est déjà utilisé par un autre compte.",
		"error":          "Une erreur s'est produite, veuillez réessayer plus tard.",
	},
}

// confirmPage dựng trang kết quả xác nhận email.
func confirmPage(c *gin.Context, status int, lang string, ok bool, msg string) {
	t := confirmTexts[lang]
	title, color, icon := t["title_fail"], "#E63946", "✕"
	if ok {
		title, color, icon = t["title_ok"], "#2A9D8F", "✓"
	}
	page := `<!doctype html><html lang="` + lang + `"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>TimeTribe – ` + html.EscapeString(title) + `</title>
<link rel="icon" type="image/png" href="/favicon.png">
<style>body{margin:0;min-height:100vh;display:grid;place-items:center;background:#F4F7FB;font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;color:#1B2B44}
.card{background:#fff;max-width:420px;margin:16px;padding:32px 28px;border-radius:20px;box-shadow:0 10px 30px rgba(27,43,68,.08);text-align:center}
.icon{width:64px;height:64px;border-radius:50%;margin:0 auto 16px;display:grid;place-items:center;font-size:32px;color:#fff;background:` + color + `}
h1{font-size:22px;margin:0 0 8px}p{margin:0;line-height:1.5;color:#51607A}.brand{margin-top:24px;font-weight:700;color:#3A86FF}</style></head>
<body><div class="card"><div class="icon">` + icon + `</div><h1>` + html.EscapeString(title) + `</h1><p>` + html.EscapeString(msg) + `</p><div class="brand">TimeTribe</div></div></body></html>`
	c.Data(status, "text/html; charset=utf-8", []byte(page))
}
