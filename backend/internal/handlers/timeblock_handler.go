package handlers

import (
	"github.com/gin-gonic/gin"

	"timetribe-backend/internal/middleware"
	"timetribe-backend/internal/services"
	"timetribe-backend/internal/utils"
)

// Schedule xử lý GET /schedule: lịch trang chủ của một ngày (cá nhân + nhóm).
func (h *Handler) Schedule(c *gin.Context) {
	res, err := h.svc.Timeblocks.Schedule(c.Request.Context(), middleware.UserID(c), c.Query("date"), c.Query("filter"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

// ScheduleCounts xử lý GET /schedule/counts: đếm số hoạt động mỗi ngày để hiện huy hiệu.
func (h *Handler) ScheduleCounts(c *gin.Context) {
	res, err := h.svc.Timeblocks.CountByDay(c.Request.Context(), middleware.UserID(c), c.Query("from"), c.Query("to"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

// ListTimeblocks xử lý GET /timeblocks: lịch cá nhân theo ngày hoặc khoảng ngày.
func (h *Handler) ListTimeblocks(c *gin.Context) {
	list, err := h.svc.Timeblocks.List(c.Request.Context(), middleware.UserID(c), c.Query("date"), c.Query("from"), c.Query("to"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", list)
}

// GetTimeblock xử lý GET /timeblocks/:id.
func (h *Handler) GetTimeblock(c *gin.Context) {
	t, err := h.svc.Timeblocks.Get(c.Request.Context(), middleware.UserID(c), c.Param("id"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", t)
}

// CreateTimeblock xử lý POST /timeblocks: tạo hoạt động cá nhân, có thể kèm ngày nhân bản.
func (h *Handler) CreateTimeblock(c *gin.Context) {
	var in services.TimeblockInput
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Timeblocks.Create(c.Request.Context(), middleware.UserID(c), in)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, "Đã lưu hoạt động", res)
}

// UpdateTimeblock xử lý PUT /timeblocks/:id.
func (h *Handler) UpdateTimeblock(c *gin.Context) {
	var in services.TimeblockInput
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Timeblocks.Update(c.Request.Context(), middleware.UserID(c), c.Param("id"), in)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã lưu hoạt động", res)
}

// DeleteTimeblock xử lý DELETE /timeblocks/:id.
func (h *Handler) DeleteTimeblock(c *gin.Context) {
	if err := h.svc.Timeblocks.Delete(c.Request.Context(), middleware.UserID(c), c.Param("id")); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã xoá hoạt động", nil)
}
