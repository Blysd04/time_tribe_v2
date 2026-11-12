package handlers

import (
	"github.com/gin-gonic/gin"

	"timetribe-backend/internal/middleware"
	"timetribe-backend/internal/services"
	"timetribe-backend/internal/utils"
)

// ListTribes xử lý GET /tribes.
func (h *Handler) ListTribes(c *gin.Context) {
	res, err := h.svc.Tribes.List(c.Request.Context(), middleware.UserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

// GetTribe xử lý GET /tribes/:id.
func (h *Handler) GetTribe(c *gin.Context) {
	res, err := h.svc.Tribes.Get(c.Request.Context(), c.Param("id"), middleware.UserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

// CreateTribe xử lý POST /tribes.
func (h *Handler) CreateTribe(c *gin.Context) {
	var in struct {
		Name string `json:"name"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Tribes.Create(c.Request.Context(), middleware.UserID(c), in.Name)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, "Đã tạo nhóm", res)
}

// JoinTribe xử lý POST /tribes/join, body có invite_code.
func (h *Handler) JoinTribe(c *gin.Context) {
	var in struct {
		InviteCode string `json:"invite_code"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Tribes.Join(c.Request.Context(), middleware.UserID(c), in.InviteCode)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã tham gia nhóm", res)
}

// RenameTribe xử lý PATCH /tribes/:id.
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

// DissolveTribe xử lý DELETE /tribes/:id.
func (h *Handler) DissolveTribe(c *gin.Context) {
	if err := h.svc.Tribes.Dissolve(c.Request.Context(), middleware.UserID(c), c.Param("id")); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã giải tán nhóm", nil)
}

// LeaveTribe xử lý POST /tribes/:id/leave, trưởng nhóm gửi kèm new_leader_id.
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

// TribeInvite xử lý GET /tribes/:id/invite: trả invite_code.
func (h *Handler) TribeInvite(c *gin.Context) {
	res, err := h.svc.Tribes.Invite(c.Request.Context(), middleware.UserID(c), c.Param("id"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

// KickMember xử lý DELETE /tribes/:id/members/:userId.
func (h *Handler) KickMember(c *gin.Context) {
	if err := h.svc.Tribes.Kick(c.Request.Context(), middleware.UserID(c), c.Param("id"), c.Param("userId")); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã mời thành viên rời nhóm", nil)
}

// ChangeMemberRole xử lý PATCH /tribes/:id/members/:userId/role.
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

// ListTribeBlocks xử lý GET /tribes/:id/blocks.
func (h *Handler) ListTribeBlocks(c *gin.Context) {
	res, err := h.svc.Tribes.ListBlocks(c.Request.Context(), middleware.UserID(c), c.Param("id"), c.Query("date"), c.Query("from"), c.Query("to"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

// TribeAvailability xử lý GET /tribes/:id/availability: giờ bận và giờ rảnh chung của một ngày.
func (h *Handler) TribeAvailability(c *gin.Context) {
	res, err := h.svc.Tribes.Availability(c.Request.Context(), middleware.UserID(c), c.Param("id"), c.Query("date"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

// TribeBusy trả giờ bận của các thành viên trong khoảng ngày (from, to).
func (h *Handler) TribeBusy(c *gin.Context) {
	res, err := h.svc.Tribes.Busy(c.Request.Context(), middleware.UserID(c), c.Param("id"), c.Query("from"), c.Query("to"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

// CreateTribeBlock xử lý POST /tribes/:id/blocks.
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

// GetTribeBlock xử lý GET /tribe-blocks/:id.
func (h *Handler) GetTribeBlock(c *gin.Context) {
	res, err := h.svc.Tribes.GetBlock(c.Request.Context(), middleware.UserID(c), c.Param("id"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

// UpdateTribeBlock xử lý PUT /tribe-blocks/:id.
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

// DeleteTribeBlock xử lý DELETE /tribe-blocks/:id.
func (h *Handler) DeleteTribeBlock(c *gin.Context) {
	if err := h.svc.Tribes.DeleteBlock(c.Request.Context(), middleware.UserID(c), c.Param("id")); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã huỷ hoạt động nhóm", nil)
}

// RespondTribeBlock xử lý PUT /tribe-blocks/:id/attendance.
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
