package handlers

import (
	"strings"

	"github.com/gin-gonic/gin"

	"timetribe-backend/internal/middleware"
	"timetribe-backend/internal/utils"
)

func (h *Handler) ListNotifications(c *gin.Context) {
	res, err := h.svc.Notifications.List(c.Request.Context(), middleware.UserID(c), c.Query("filter"))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

func (h *Handler) UnreadCount(c *gin.Context) {
	res, err := h.svc.Notifications.UnreadSummary(c.Request.Context(), middleware.UserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "", res)
}

func (h *Handler) MarkRead(c *gin.Context) {
	if err := h.svc.Notifications.MarkRead(c.Request.Context(), middleware.UserID(c), c.Param("id")); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã đánh dấu đã đọc", nil)
}

func (h *Handler) MarkAllRead(c *gin.Context) {
	n, err := h.svc.Notifications.MarkAllRead(c.Request.Context(), middleware.UserID(c))
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã đánh dấu đọc tất cả", gin.H{"updated": n})
}

func (h *Handler) Broadcast(c *gin.Context) {
	var in struct {
		Title   string `json:"title"`
		Content string `json:"content"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	in.Title, in.Content = strings.TrimSpace(in.Title), strings.TrimSpace(in.Content)
	if in.Title == "" || in.Content == "" || utils.Len(in.Title) > 255 {
		utils.Fail(c, utils.BadRequest("validation_error", "Cần có title (tối đa 255 ký tự) và content"))
		return
	}
	n, err := h.svc.Notifications.Broadcast(c.Request.Context(), middleware.UserID(c), in.Title, in.Content)
	if err != nil {
		utils.Fail(c, err)
		return
	}
	utils.Created(c, "Đã gửi thông báo cho toàn bộ người dùng", n)
}

func (h *Handler) BanUser(c *gin.Context) {
	var in struct {
		IsBanned  bool    `json:"is_banned"`
		BanReason *string `json:"ban_reason"`
	}
	if !utils.BindJSON(c, &in) {
		return
	}
	if c.Param("id") == middleware.UserID(c) {
		utils.Fail(c, utils.BadRequest("validation_error", "Không thể tự khoá tài khoản của mình"))
		return
	}
	if err := h.svc.Users.SetBan(c.Request.Context(), c.Param("id"), in.IsBanned, in.BanReason); err != nil {
		utils.Fail(c, err)
		return
	}
	utils.OK(c, "Đã cập nhật trạng thái khoá tài khoản", nil)
}
