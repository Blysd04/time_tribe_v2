package handlers

import (
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

// ClearFCMToken xử lý DELETE /users/me/fcm-token.
func (h *Handler) ClearFCMToken(c *gin.Context) {
	if err := h.svc.Users.ClearFCMToken(c.Request.Context(), middleware.UserID(c)); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã xoá fcm_token", nil)
}
