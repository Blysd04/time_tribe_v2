package config

import (
	"log"
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

// Config gom toàn bộ cấu hình đọc từ biến môi trường (file .env).
type Config struct {
	AppEnv  string
	Port    string
	BaseURL string

	MongoURI string
	DBName   string

	JWTSecret         string
	AccessTokenTTL    time.Duration
	RefreshTokenTTL   time.Duration
	RememberMeTTL     time.Duration
	ResetTokenTTL     time.Duration
	FirebaseCredsFile string
	CloudinaryURL     string

	// Đường dẫn công khai dùng để dựng link chia sẻ lịch mẫu / link mời nhóm
	ShareBaseURL string
	// Link mở trang đặt lại mật khẩu (gắn ?token=...)
	ResetPasswordURL string

	SMTPHost string
	SMTPPort string
	SMTPUser string
	SMTPPass string
	SMTPFrom string

	// Bật bộ quét gửi nhắc lịch mỗi phút
	EnableReminder bool
}

func Load() *Config {
	// Không có file .env thì vẫn chạy được bằng biến môi trường của hệ thống
	if err := godotenv.Load(); err != nil {
		log.Println("không tìm thấy file .env, dùng biến môi trường hệ thống")
	}

	cfg := &Config{
		AppEnv:            get("APP_ENV", "development"),
		Port:              get("PORT", "8080"),
		BaseURL:           get("BASE_URL", "http://localhost:8080"),
		MongoURI:          get("MONGO_URI", "mongodb://localhost:27017"),
		DBName:            get("DB_NAME", "timetribe"),
		JWTSecret:         get("JWT_SECRET", "doi-chuoi-nay-truoc-khi-deploy"),
		AccessTokenTTL:    minutes("ACCESS_TOKEN_TTL_MINUTES", 60),
		RefreshTokenTTL:   days("REFRESH_TOKEN_TTL_DAYS", 7),
		RememberMeTTL:     days("REMEMBER_ME_TTL_DAYS", 30),
		ResetTokenTTL:     minutes("RESET_TOKEN_TTL_MINUTES", 30),
		FirebaseCredsFile: get("FIREBASE_CREDENTIALS", "serviceAccountKey.json"),
		CloudinaryURL:     get("CLOUDINARY_URL", ""),
		ShareBaseURL:      get("SHARE_BASE_URL", "https://timetribe.app"),
		ResetPasswordURL:  get("RESET_PASSWORD_URL", "https://timetribe.app/reset-password"),
		SMTPHost:          get("SMTP_HOST", ""),
		SMTPPort:          get("SMTP_PORT", "587"),
		SMTPUser:          get("SMTP_USER", ""),
		SMTPPass:          get("SMTP_PASS", ""),
		SMTPFrom:          get("SMTP_FROM", ""),
		EnableReminder:    get("ENABLE_REMINDER", "true") == "true",
	}
	return cfg
}

func (c *Config) IsDev() bool { return c.AppEnv != "production" }

func get(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return fallback
}

func minutes(key string, fallback int) time.Duration {
	return time.Duration(intOr(key, fallback)) * time.Minute
}

func days(key string, fallback int) time.Duration {
	return time.Duration(intOr(key, fallback)) * 24 * time.Hour
}

func intOr(key string, fallback int) int {
	v, err := strconv.Atoi(os.Getenv(key))
	if err != nil || v <= 0 {
		return fallback
	}
	return v
}
