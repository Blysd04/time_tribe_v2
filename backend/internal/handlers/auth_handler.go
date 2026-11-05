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

func New(svc *services.Services) *Handler { return &Handler{svc: svc} }

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

func (h *Handler) Refresh(c *gin.Context) {
	var in struct {
		RefreshToken string `json:"refresh_token"`
		DeviceInfo   string `json:"device_info"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Auth.Refresh(c.Request.Context(), in.RefreshToken, in.DeviceInfo)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã cấp token mới", res)
}

func (h *Handler) Logout(c *gin.Context) {
	var in struct {
		RefreshToken string `json:"refresh_token"`
		FCMToken     string `json:"fcm_token"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	if err := h.svc.Auth.Logout(c.Request.Context(), middleware.UserID(c), in.RefreshToken, in.FCMToken); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã đăng xuất", nil)
}

func (h *Handler) ForgotPassword(c *gin.Context) {
	var in struct {
		Email string `json:"email"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Auth.ForgotPassword(c.Request.Context(), in.Email)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Nếu email tồn tại, đường dẫn đặt lại mật khẩu đã được gửi", res)
}

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
