package handlers

import (
	"github.com/gin-gonic/gin"

	"timetribe-backend/internal/middleware"
	"timetribe-backend/internal/services"
	"timetribe-backend/internal/utils"
)

type Handler struct {
	svc *services.Services
}

// New tạo handler dùng chung cho mọi API.
func New(svc *services.Services) *Handler { return &Handler{svc: svc} }

// Register xử lý POST /auth/register.
func (h *Handler) Register(c *gin.Context) {
	var in services.RegisterInput
	if !utils.BindJSON(c, &in) {
		return
	}
	user, err := h.svc.Auth.Register(c.Request.Context(), in)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, "Đăng ký thành công, mời bạn đăng nhập", user)
}

// Login xử lý POST /auth/login, body có thể kèm fcm_token.
func (h *Handler) Login(c *gin.Context) {
	var in services.LoginInput
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Auth.Login(c.Request.Context(), in)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đăng nhập thành công", res)
}

// GoogleLogin xử lý POST /auth/google.
func (h *Handler) GoogleLogin(c *gin.Context) {
	var in services.GoogleLoginInput
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Auth.GoogleLogin(c.Request.Context(), in)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đăng nhập Google thành công", res)
}

// Refresh xử lý POST /auth/refresh: đổi refresh token lấy access token mới.
func (h *Handler) Refresh(c *gin.Context) {
	var in struct {
		RefreshToken string `json:"refresh_token"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Auth.Refresh(c.Request.Context(), in.RefreshToken)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã cấp token mới", res)
}

// Logout xử lý POST /auth/logout: xoá phiên hiện tại (lấy từ access token) và fcm_token.
func (h *Handler) Logout(c *gin.Context) {
	if err := h.svc.Auth.Logout(c.Request.Context(), middleware.UserID(c), middleware.SessionID(c)); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã đăng xuất", nil)
}

// ForgotPassword xử lý POST /auth/forgot-password.
func (h *Handler) ForgotPassword(c *gin.Context) {
	var in struct {
		Email string `json:"email"`
		// Ngôn ngữ app đang dùng (vi, en, fr) để gửi email đúng ngôn ngữ
		Language string `json:"language"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Auth.ForgotPassword(c.Request.Context(), in.Email, in.Language)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Nếu email tồn tại, đường dẫn đặt lại mật khẩu đã được gửi", res)
}

// ResetPassword xử lý POST /auth/reset-password.
func (h *Handler) ResetPassword(c *gin.Context) {
	var in services.ResetPasswordInput
	if !utils.BindJSON(c, &in) {
		return
	}
	if err := h.svc.Auth.ResetPassword(c.Request.Context(), in); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đặt mật khẩu mới thành công, mời bạn đăng nhập lại", nil)
}

// ChangePassword xử lý PUT /auth/change-password.
func (h *Handler) ChangePassword(c *gin.Context) {
	var in services.ChangePasswordInput
	if !utils.BindJSON(c, &in) {
		return
	}
	if err := h.svc.Auth.ChangePassword(c.Request.Context(), middleware.UserID(c), in); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đổi mật khẩu thành công, mời bạn đăng nhập lại", nil)
}
