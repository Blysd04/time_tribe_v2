package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	// Nhúng dữ liệu múi giờ IANA vào file chạy, máy chủ không cài tzdata vẫn đổi giờ được
	_ "time/tzdata"

	"timetribe-backend/internal/config"
	"timetribe-backend/internal/database"
	"timetribe-backend/internal/handlers"
	"timetribe-backend/internal/repository"
	"timetribe-backend/internal/services"
)

// main đọc cấu hình, kết nối MongoDB, tạo index, bật bộ nhắc lịch rồi chạy HTTP server. Bấm Ctrl+C thì tắt server nhẹ nhàng.
func main() {
	cfg := config.Load()
	if !cfg.IsDev() {
		gin.SetMode(gin.ReleaseMode)
	}

	client, db, err := database.Connect(cfg.MongoURI, cfg.DBName)
	if err != nil {
		log.Fatal(err)
	}
	defer client.Disconnect(context.Background())
	if err := database.EnsureIndexes(db); err != nil {
		log.Fatal(err)
	}

	svc := services.New(cfg, repository.NewStore(db))
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	if cfg.EnableReminder {
		svc.Reminder.Start(ctx)
	}

	srv := &http.Server{Addr: ":" + cfg.Port, Handler: handlers.Routes(svc), ReadHeaderTimeout: 10 * time.Second}
	go func() {
		log.Printf("TimeTribe API đang chạy tại %s (db: %s)", cfg.BaseURL, cfg.DBName)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal(err)
		}
	}()

	<-ctx.Done()
	log.Println("đang tắt server...")
	shutdown, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_ = srv.Shutdown(shutdown)
}
