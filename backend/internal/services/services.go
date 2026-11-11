package services

import (
	"log"
	"timetribe-backend/internal/config"
	"timetribe-backend/internal/repository"
)

// Services gom mọi service để truyền cho handler.
type Services struct {
	Cfg           *config.Config
	Store         *repository.Store
	JWT           *JWTManager
	Firebase      *FirebaseService
	Uploader      *Uploader
	Notifications *NotificationService
	Auth          *AuthService
	Users         *UserService
	Tribes        *TribeService
	Timeblocks    *TimeblockService
	Templates     *TemplateService
	Reminder      *ReminderWorker
}

// New tạo tất cả service theo đúng thứ tự phụ thuộc.
func New(cfg *config.Config, store *repository.Store) *Services {
	s := &Services{Cfg: cfg, Store: store}
	s.JWT = NewJWTManager(cfg.JWTSecret, cfg.AccessTokenTTL)
	s.Firebase = NewFirebaseService(cfg.FirebaseCredsFile, cfg.FirebaseCredsJSON)
	s.Uploader = NewUploader(cfg.CloudinaryURL)
	mailer := NewMailer(cfg.SMTPHost, cfg.SMTPPort, cfg.SMTPUser, cfg.SMTPPass, cfg.SMTPFrom, cfg.BrevoAPIKey, cfg.MailFromName)
	log.Println("gửi email:", mailer.Describe())
	s.Notifications = NewNotificationService(store, s.Firebase)
	s.Auth = NewAuthService(cfg, store, s.JWT, s.Firebase, mailer, s.Notifications)
	s.Tribes = NewTribeService(cfg, store, s.Notifications)
	s.Users = NewUserService(store, s.Auth, s.Tribes, s.Uploader, s.Notifications)
	s.Timeblocks = NewTimeblockService(store, s.Tribes)
	s.Templates = NewTemplateService(cfg, store, s.Timeblocks)
	s.Reminder = NewReminderWorker(store, s.Notifications)
	return s
}
