package handlers

import (
	"github.com/gin-gonic/gin"

	"timetribe-backend/internal/middleware"
	"timetribe-backend/internal/services"
	"timetribe-backend/internal/utils"
)

func (h *Handler) ListTribes(c *gin.Context) {
	res, err := h.svc.Tribes.List(c.Request.Context(), middleware.UserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

func (h *Handler) GetTribe(c *gin.Context) {
	res, err := h.svc.Tribes.Get(c.Request.Context(), c.Param("id"), middleware.UserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

func (h *Handler) CreateTribe(c *gin.Context) {
	var in struct {
		Name            string  `json:"name"`
		BackgroundColor *string `json:"background_color"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Tribes.Create(c.Request.Context(), middleware.UserID(c), in.Name, in.BackgroundColor)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, "Đã tạo nhóm", res)
}

func (h *Handler) JoinTribe(c *gin.Context) {
	var in struct {
		InviteLink string `json:"invite_link"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Tribes.Join(c.Request.Context(), middleware.UserID(c), in.InviteLink)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã tham gia nhóm", res)
}

func (h *Handler) RenameTribe(c *gin.Context) {
	var in struct {
		Name string `json:"name"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Tribes.Rename(c.Request.Context(), middleware.UserID(c), c.Param("id"), in.Name)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã đổi tên nhóm", res)
}

// UpdateTribeAppearance nhận multipart/form-data: background_color (tuỳ chọn),
// background_image (file, tuỳ chọn), remove_image=true để bỏ ảnh nền.
// Gửi JSON {"background_color": "#..."} cũng được nếu chỉ đổi màu.
func (h *Handler) UpdateTribeAppearance(c *gin.Context) {
	var color *string
	removeImage := false
	if c.ContentType() == "application/json" {
		var in struct {
			BackgroundColor *string `json:"background_color"`
			RemoveImage     bool    `json:"remove_image"`
		}
		if !utils.BindJSON(c, &in) {
			return
		}
		color, removeImage = in.BackgroundColor, in.RemoveImage
	} else {
		if v := c.PostForm("background_color"); v != "" {
			color = &v
		}
		removeImage = c.PostForm("remove_image") == "true"
	}
	fh, _ := c.FormFile("background_image")
	res, err := h.svc.Tribes.UpdateAppearance(c.Request.Context(), middleware.UserID(c), c.Param("id"), color, fh, removeImage)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã cập nhật giao diện nhóm", res)
}

func (h *Handler) DissolveTribe(c *gin.Context) {
	if err := h.svc.Tribes.Dissolve(c.Request.Context(), middleware.UserID(c), c.Param("id")); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã giải tán nhóm", nil)
}

func (h *Handler) LeaveTribe(c *gin.Context) {
	var in struct {
		NewLeaderID string `json:"new_leader_id"`
	}
	// Body có thể để trống
	_ = c.ShouldBindJSON(&in)
	res, err := h.svc.Tribes.Leave(c.Request.Context(), middleware.UserID(c), c.Param("id"), in.NewLeaderID)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã rời nhóm", res)
}

func (h *Handler) TribeInvite(c *gin.Context) {
	res, err := h.svc.Tribes.Invite(c.Request.Context(), middleware.UserID(c), c.Param("id"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

func (h *Handler) KickMember(c *gin.Context) {
	if err := h.svc.Tribes.Kick(c.Request.Context(), middleware.UserID(c), c.Param("id"), c.Param("userId")); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã mời thành viên rời nhóm", nil)
}

func (h *Handler) ChangeMemberRole(c *gin.Context) {
	var in struct {
		Role string `json:"role"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Tribes.ChangeRole(c.Request.Context(), middleware.UserID(c), c.Param("id"), c.Param("userId"), in.Role)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã cập nhật chức vụ", res)
}

func (h *Handler) ListTribeBlocks(c *gin.Context) {
	res, err := h.svc.Tribes.ListBlocks(c.Request.Context(), middleware.UserID(c), c.Param("id"), c.Query("date"), c.Query("from"), c.Query("to"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

func (h *Handler) TribeAvailability(c *gin.Context) {
	res, err := h.svc.Tribes.Availability(c.Request.Context(), middleware.UserID(c), c.Param("id"), c.Query("date"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

func (h *Handler) CreateTribeBlock(c *gin.Context) {
	var in services.TribeBlockInput
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Tribes.CreateBlock(c.Request.Context(), middleware.UserID(c), c.Param("id"), in)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, "Đã tạo hoạt động nhóm", res)
}

func (h *Handler) GetTribeBlock(c *gin.Context) {
	res, err := h.svc.Tribes.GetBlock(c.Request.Context(), middleware.UserID(c), c.Param("id"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

func (h *Handler) UpdateTribeBlock(c *gin.Context) {
	var in services.TribeBlockInput
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Tribes.UpdateBlock(c.Request.Context(), middleware.UserID(c), c.Param("id"), in)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã cập nhật hoạt động nhóm", res)
}

func (h *Handler) DeleteTribeBlock(c *gin.Context) {
	if err := h.svc.Tribes.DeleteBlock(c.Request.Context(), middleware.UserID(c), c.Param("id")); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã huỷ hoạt động nhóm", nil)
}

func (h *Handler) RespondTribeBlock(c *gin.Context) {
	var in struct {
		Status string `json:"status"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Tribes.Respond(c.Request.Context(), middleware.UserID(c), c.Param("id"), in.Status)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã ghi nhận phản hồi", res)
}
