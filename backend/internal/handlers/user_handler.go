package handlers

import (
	"github.com/gin-gonic/gin"

	"timetribe-backend/internal/middleware"
	"timetribe-backend/internal/services"
	"timetribe-backend/internal/utils"
)

func (h *Handler) GetMe(c *gin.Context) {
	me, err := h.svc.Users.Me(c.Request.Context(), middleware.UserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", me)
}

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

func (h *Handler) DeletePlan(c *gin.Context) {
	plans, err := h.svc.Users.DeletePlan(c.Request.Context(), middleware.UserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", plans)
}

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

func (h *Handler) RegisterDevice(c *gin.Context) {
	var in struct {
		FCMToken   string `json:"fcm_token"`
		DeviceInfo string `json:"device_info"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	if err := h.svc.Users.RegisterDevice(c.Request.Context(), middleware.UserID(c), in.FCMToken, in.DeviceInfo); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã đăng ký thiết bị nhận thông báo", nil)
}

func (h *Handler) UnregisterDevice(c *gin.Context) {
	var in struct {
		FCMToken string `json:"fcm_token"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	if err := h.svc.Users.UnregisterDevice(c.Request.Context(), middleware.UserID(c), in.FCMToken); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã huỷ nhận thông báo trên thiết bị", nil)
}
