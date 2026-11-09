// Lệnh gửi thử một thông báo FCM tới một máy, dùng để kiểm tra cấu hình Firebase.
//
//	go run ./cmd/testpush -token <fcm_token>
//	go run ./cmd/testpush -token <fcm_token> -creds serviceAccountKey.json -title "Xin chào" -body "Test"
package main

import (
	"context"
	"flag"
	"log"
	"time"

	"firebase.google.com/go/v4/messaging"

	"timetribe-backend/internal/config"
	"timetribe-backend/internal/services"
)

func main() {
	cfg := config.Load()
	token := flag.String("token", "", "FCM registration token của máy cần gửi")
	creds := flag.String("creds", cfg.FirebaseCredsFile, "file service account của Firebase")
	title := flag.String("title", "TimeTribe test", "tiêu đề")
	body := flag.String("body", "Gửi lúc "+time.Now().Format("15:04:05"), "nội dung")
	flag.Parse()
	if *token == "" {
		log.Fatal("thiếu -token")
	}
	fb := services.NewFirebaseService(*creds)
	if !fb.PushEnabled() {
		log.Fatal("không khởi tạo được Firebase Messaging, kiểm tra file -creds")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	id, err := fb.Messaging.Send(ctx, &messaging.Message{
		Token:        *token,
		Notification: &messaging.Notification{Title: *title, Body: *body},
		Data:         map[string]string{"kind": "test", "type": "system"},
		Android:      services.AndroidPush(),
	})
	if err != nil {
		log.Fatalf("gửi lỗi: %v", err)
	}
	log.Printf("đã gửi, message id: %s", id)
}
