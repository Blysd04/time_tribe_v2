package handlers

import (
	_ "embed"
	"net/http"

	"github.com/gin-gonic/gin"
)

// landing.html là trang giới thiệu + nút tải APK, một file HTML đầy đủ (mở thẳng bằng trình duyệt
// hay Live Server cũng chạy), có sẵn 3 ngôn ngữ vi/en/fr.
//
//go:embed web/landing.html
var landingPage []byte

//go:embed web/reset.html
var resetPage []byte

//go:embed web/logo.png
var logoPNG []byte

//go:embed web/favicon.png
var faviconPNG []byte

// Landing xử lý GET /: trang tải ứng dụng.
func Landing(c *gin.Context) {
	c.Data(http.StatusOK, "text/html; charset=utf-8", landingPage)
}

// ResetPasswordPage xử lý GET /reset-password?token=...: link trong email quên mật khẩu mở trang này,
// trang gọi POST /api/v1/auth/reset-password để lưu mật khẩu mới.
func ResetPasswordPage(c *gin.Context) {
	c.Header("Cache-Control", "no-store")
	c.Header("Referrer-Policy", "no-referrer") // không để lộ token trong Referer
	c.Data(http.StatusOK, "text/html; charset=utf-8", resetPage)
}

// Logo và Favicon phục vụ ảnh mà trang tải dùng (đường dẫn tương đối logo.png, favicon.png).
func Logo(c *gin.Context) {
	c.Header("Cache-Control", "public, max-age=86400")
	c.Data(http.StatusOK, "image/png", logoPNG)
}

func Favicon(c *gin.Context) {
	c.Header("Cache-Control", "public, max-age=86400")
	c.Data(http.StatusOK, "image/png", faviconPNG)
}

// Download xử lý GET /download: chuyển tới file APK mới nhất (biến APK_URL),
// đổi chỗ lưu APK chỉ cần sửa biến môi trường, không phải sửa trang.
func Download(apkURL string) gin.HandlerFunc {
	return func(c *gin.Context) {
		if apkURL == "" {
			c.String(http.StatusServiceUnavailable, "Chưa có file APK, vui lòng quay lại sau.")
			return
		}
		c.Redirect(http.StatusFound, apkURL)
	}
}
