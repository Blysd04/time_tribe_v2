package handlers

import (
	"github.com/gin-gonic/gin"

	"timetribe-backend/internal/middleware"
	"timetribe-backend/internal/services"
	"timetribe-backend/internal/utils"
)

func (h *Handler) Schedule(c *gin.Context) {
	res, err := h.svc.Timeblocks.Schedule(c.Request.Context(), middleware.UserID(c), c.Query("date"), c.Query("filter"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

func (h *Handler) ScheduleCounts(c *gin.Context) {
	res, err := h.svc.Timeblocks.CountByDay(c.Request.Context(), middleware.UserID(c), c.Query("from"), c.Query("to"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

func (h *Handler) ListTimeblocks(c *gin.Context) {
	list, err := h.svc.Timeblocks.List(c.Request.Context(), middleware.UserID(c), c.Query("date"), c.Query("from"), c.Query("to"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", list)
}

func (h *Handler) GetTimeblock(c *gin.Context) {
	t, err := h.svc.Timeblocks.Get(c.Request.Context(), middleware.UserID(c), c.Param("id"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", t)
}

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

func (h *Handler) DeleteTimeblock(c *gin.Context) {
	if err := h.svc.Timeblocks.Delete(c.Request.Context(), middleware.UserID(c), c.Param("id")); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã xoá hoạt động", nil)
}
