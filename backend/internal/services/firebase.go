package services

import (
	"context"
	"log"
	"os"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

// TopicAllUsers là topic FCM mà mọi thiết bị đều đăng ký, dùng cho thông báo hệ thống.
const TopicAllUsers = "all_users"

// FirebaseService bọc Firebase Admin SDK: xác thực ID token đăng nhập Google và gửi FCM.
// Thiếu file serviceAccountKey.json thì server vẫn chạy, chỉ tắt hai chức năng này.
type FirebaseService struct {
	Auth      *auth.Client
	Messaging *messaging.Client
}

func NewFirebaseService(credsFile string) *FirebaseService {
	if _, err := os.Stat(credsFile); err != nil {
		log.Printf("không thấy file %s, tắt đăng nhập Google và thông báo đẩy", credsFile)
		return &FirebaseService{}
	}
	ctx := context.Background()
	app, err := firebase.NewApp(ctx, nil, option.WithCredentialsFile(credsFile))
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

func (f *FirebaseService) AuthEnabled() bool { return f.Auth != nil }
func (f *FirebaseService) PushEnabled() bool { return f.Messaging != nil }
