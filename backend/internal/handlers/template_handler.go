package handlers

import (
	"github.com/gin-gonic/gin"

	"timetribe-backend/internal/middleware"
	"timetribe-backend/internal/services"
	"timetribe-backend/internal/utils"
)

// ListTemplates xử lý GET /templates.
func (h *Handler) ListTemplates(c *gin.Context) {
	res, err := h.svc.Templates.List(c.Request.Context(), middleware.UserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

// GetTemplate xử lý GET /templates/:id.
func (h *Handler) GetTemplate(c *gin.Context) {
	res, err := h.svc.Templates.Get(c.Request.Context(), middleware.UserID(c), c.Param("id"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

// CreateTemplate xử lý POST /templates.
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

// UpdateTemplate xử lý PUT /templates/:id: đổi tên và/hoặc thay toàn bộ khối.
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

// DeleteTemplate xử lý DELETE /templates/:id.
func (h *Handler) DeleteTemplate(c *gin.Context) {
	if err := h.svc.Templates.Delete(c.Request.Context(), middleware.UserID(c), c.Param("id")); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã xoá lịch mẫu", nil)
}

// ShareTemplate xử lý POST /templates/:id/share: trả share_code.
func (h *Handler) ShareTemplate(c *gin.Context) {
	res, err := h.svc.Templates.Share(c.Request.Context(), middleware.UserID(c), c.Param("id"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

// GetSharedTemplate xử lý GET /templates/shared/:code: xem trước lịch mẫu từ mã chia sẻ.
func (h *Handler) GetSharedTemplate(c *gin.Context) {
	res, err := h.svc.Templates.GetShared(c.Request.Context(), c.Param("code"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

// ImportTemplate xử lý POST /templates/import, body có share_code.
func (h *Handler) ImportTemplate(c *gin.Context) {
	var in struct {
		ShareCode string `json:"share_code"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	res, err := h.svc.Templates.Import(c.Request.Context(), middleware.UserID(c), in.ShareCode)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, "Đã nhập lịch mẫu", res)
}

// ApplyTemplate xử lý POST /templates/:id/apply.
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
