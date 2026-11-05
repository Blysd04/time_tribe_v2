package handlers

import (
	"github.com/gin-gonic/gin"

	"timetribe-backend/internal/middleware"
	"timetribe-backend/internal/services"
	"timetribe-backend/internal/utils"
)

func (h *Handler) ListTemplates(c *gin.Context) {
	res, err := h.svc.Templates.List(c.Request.Context(), middleware.UserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

func (h *Handler) GetTemplate(c *gin.Context) {
	res, err := h.svc.Templates.Get(c.Request.Context(), middleware.UserID(c), c.Param("id"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

func (h *Handler) CreateTemplate(c *gin.Context) {
	var in services.TemplateInput
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Templates.Create(c.Request.Context(), middleware.UserID(c), in)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, "Đã lưu lịch mẫu", res)
}

func (h *Handler) UpdateTemplate(c *gin.Context) {
	var in services.TemplateInput
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Templates.Update(c.Request.Context(), middleware.UserID(c), c.Param("id"), in)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã lưu lịch mẫu", res)
}

func (h *Handler) DeleteTemplate(c *gin.Context) {
	if err := h.svc.Templates.Delete(c.Request.Context(), middleware.UserID(c), c.Param("id")); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã xoá lịch mẫu", nil)
}

func (h *Handler) ShareTemplate(c *gin.Context) {
	res, err := h.svc.Templates.Share(c.Request.Context(), middleware.UserID(c), c.Param("id"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

func (h *Handler) GetSharedTemplate(c *gin.Context) {
	res, err := h.svc.Templates.GetShared(c.Request.Context(), c.Param("token"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

func (h *Handler) ImportTemplate(c *gin.Context) {
	var in struct {
		Link string `json:"link"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Templates.Import(c.Request.Context(), middleware.UserID(c), in.Link)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, "Đã nhập lịch mẫu", res)
}

func (h *Handler) ApplyTemplate(c *gin.Context) {
	var in services.ApplyInput
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Templates.Apply(c.Request.Context(), middleware.UserID(c), c.Param("id"), in)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	msg := "Đã áp dụng lịch mẫu"
	if in.DryRun {
		msg = "Xem trước kết quả áp dụng"
	}
	utils.OK(c, msg, res)
}
