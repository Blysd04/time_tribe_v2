package services

import (
	"context"
	"encoding/base64"
	"log"
	"os"
	"strings"
	"time"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

// TopicAllUsers là topic FCM mà mọi thiết bị đều đăng ký, dùng cho thông báo hệ thống.
const TopicAllUsers = "all_users"

// AndroidChannelID là kênh thông báo mức ưu tiên cao mà app tạo sẵn (MainActivity.kt).
// Không chỉ định kênh thì Android dùng kênh mặc định "Miscellaneous" mức thấp: khi app chạy nền
// thông báo chỉ nằm im trong thanh thông báo, không hiện nổi, không chuông (nhất là máy Xiaomi).
const AndroidChannelID = "timetribe_alerts"

// AndroidPush là cấu hình Android dùng chung cho mọi thông báo đẩy: ưu tiên cao để máy đang
// tiết kiệm pin (Doze, MIUI...) vẫn nhận ngay, hiện nổi + chuông + rung qua kênh timetribe_alerts.
func AndroidPush() *messaging.AndroidConfig {
	return &messaging.AndroidConfig{
		Priority: "high",
		TTL:      ptrDuration(24 * time.Hour),
		Notification: &messaging.AndroidNotification{
			ChannelID:             AndroidChannelID,
			Priority:              messaging.PriorityHigh,
			DefaultSound:          true,
			DefaultVibrateTimings: true,
			Visibility:            messaging.VisibilityPublic,
			Icon:                  "ic_stat_notification",
			Color:                 "#3A86FF",
		},
	}
}

func ptrDuration(d time.Duration) *time.Duration { return &d }

// FirebaseService bọc Firebase Admin SDK: xác thực ID token đăng nhập Google và gửi FCM.
// Thiếu file serviceAccountKey.json thì server vẫn chạy, chỉ tắt hai chức năng này.
type FirebaseService struct {
	Auth      *auth.Client
	Messaging *messaging.Client
}

// NewFirebaseService khởi tạo Firebase Admin SDK. Ưu tiên credsJSON (biến FIREBASE_CREDENTIALS_JSON,
// JSON thô hoặc base64, tiện khi deploy), không có thì đọc file credsFile.
// Không có cả hai thì server vẫn chạy, chỉ tắt đăng nhập Google và FCM.
func NewFirebaseService(credsFile, credsJSON string) *FirebaseService {
	var opt option.ClientOption
	if raw := strings.TrimSpace(credsJSON); raw != "" {
		if !strings.HasPrefix(raw, "{") {
			dec, err := base64.StdEncoding.DecodeString(raw)
			if err != nil {
				log.Printf("FIREBASE_CREDENTIALS_JSON không phải JSON hay base64 hợp lệ: %v", err)
				return &FirebaseService{}
			}
			raw = string(dec)
		}
		opt = option.WithCredentialsJSON([]byte(raw))
	} else {
		if _, err := os.Stat(credsFile); err != nil {
			log.Printf("không thấy file %s, tắt đăng nhập Google và thông báo đẩy", credsFile)
			return &FirebaseService{}
		}
		opt = option.WithCredentialsFile(credsFile)
	}
	ctx := context.Background()
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		log.Printf("khởi tạo Firebase lỗi: %v", err)
		return &FirebaseService{}
	}
	fs := &FirebaseService{}
	if fs.Auth, err = app.Auth(ctx); err != nil {
		log.Printf("không lấy được Firebase Auth: %v", err)
	}
	if fs.Messaging, err = app.Messaging(ctx); err != nil {
		log.Printf("không lấy được Firebase Messaging: %v", err)
	}
	log.Println("đã kết nối Firebase")
	return fs
}

// AuthEnabled cho biết có xác thực được token đăng nhập Google không.
func (f *FirebaseService) AuthEnabled() bool { return f.Auth != nil }

// PushEnabled cho biết có gửi được thông báo đẩy FCM không.
func (f *FirebaseService) PushEnabled() bool { return f.Messaging != nil }
