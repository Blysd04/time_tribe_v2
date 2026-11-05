package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"timetribe-backend/internal/middleware"
	"timetribe-backend/internal/services"
)

// Routes khai báo toàn bộ API, tiền tố chung là /api/v1.
func Routes(svc *services.Services) *gin.Engine {
	r := gin.New()
	r.Use(gin.Logger(), gin.Recovery(), middleware.CORS())
	r.MaxMultipartMemory = 8 << 20

	h := New(svc)
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status": "ok", "time": time.Now().UTC(),
			"firebase_auth": svc.Firebase.AuthEnabled(), "firebase_push": svc.Firebase.PushEnabled(),
		})
	})

	api := r.Group("/api/v1")

	// Không cần đăng nhập
	auth := api.Group("/auth")
	auth.POST("/register", h.Register)
	auth.POST("/login", h.Login)
	auth.POST("/google", h.GoogleLogin)
	auth.POST("/refresh", h.Refresh)
	auth.POST("/forgot-password", h.ForgotPassword)
	auth.POST("/reset-password", h.ResetPassword)

	// Cần access token
	p := api.Group("", middleware.Auth(svc))
	p.POST("/auth/logout", h.Logout)
	p.PUT("/auth/change-password", h.ChangePassword)

	p.GET("/users/me", h.GetMe)
	p.PATCH("/users/me", h.UpdateMe)
	p.POST("/users/me/avatar", h.UploadAvatar)
	p.GET("/users/me/delete-preview", h.DeletePlan)
	p.DELETE("/users/me", h.DeleteMe)
	p.POST("/users/me/devices", h.RegisterDevice)
	p.DELETE("/users/me/devices", h.UnregisterDevice)

	p.GET("/schedule", h.Schedule)
	p.GET("/schedule/counts", h.ScheduleCounts)
	p.GET("/timeblocks", h.ListTimeblocks)
	p.POST("/timeblocks", h.CreateTimeblock)
	p.GET("/timeblocks/:id", h.GetTimeblock)
	p.PUT("/timeblocks/:id", h.UpdateTimeblock)
	p.DELETE("/timeblocks/:id", h.DeleteTimeblock)

	p.GET("/templates", h.ListTemplates)
	p.POST("/templates", h.CreateTemplate)
	p.POST("/templates/import", h.ImportTemplate)
	p.GET("/templates/shared/:token", h.GetSharedTemplate)
	p.GET("/templates/:id", h.GetTemplate)
	p.PUT("/templates/:id", h.UpdateTemplate)
	p.DELETE("/templates/:id", h.DeleteTemplate)
	p.POST("/templates/:id/share", h.ShareTemplate)
	p.POST("/templates/:id/apply", h.ApplyTemplate)

	p.GET("/tribes", h.ListTribes)
	p.POST("/tribes", h.CreateTribe)
	p.POST("/tribes/join", h.JoinTribe)
	p.GET("/tribes/:id", h.GetTribe)
	p.PATCH("/tribes/:id", h.RenameTribe)
	p.PATCH("/tribes/:id/appearance", h.UpdateTribeAppearance)
	p.DELETE("/tribes/:id", h.DissolveTribe)
	p.POST("/tribes/:id/leave", h.LeaveTribe)
	p.GET("/tribes/:id/invite", h.TribeInvite)
	p.DELETE("/tribes/:id/members/:userId", h.KickMember)
	p.PATCH("/tribes/:id/members/:userId/role", h.ChangeMemberRole)
	p.GET("/tribes/:id/blocks", h.ListTribeBlocks)
	p.POST("/tribes/:id/blocks", h.CreateTribeBlock)
	p.GET("/tribes/:id/availability", h.TribeAvailability)

	p.GET("/tribe-blocks/:id", h.GetTribeBlock)
	p.PUT("/tribe-blocks/:id", h.UpdateTribeBlock)
	p.DELETE("/tribe-blocks/:id", h.DeleteTribeBlock)
	p.PUT("/tribe-blocks/:id/attendance", h.RespondTribeBlock)

	p.GET("/notifications", h.ListNotifications)
	p.GET("/notifications/unread-count", h.UnreadCount)
	p.PATCH("/notifications/read-all", h.MarkAllRead)
	p.PATCH("/notifications/:id/read", h.MarkRead)

	admin := p.Group("/admin", middleware.AdminOnly())
	admin.POST("/notifications/broadcast", h.Broadcast)
	admin.PATCH("/users/:id/ban", h.BanUser)

	return r
}
