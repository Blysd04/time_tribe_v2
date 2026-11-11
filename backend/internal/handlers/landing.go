package handlers

import (
	_ "embed"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

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

// Download xử lý GET /download: trả thẳng file APK trong response, không chuyển hướng.
//   - Có file ở apkPath (mặc định public/timetribe.apk, chép vào image lúc build) thì gửi file đó.
//     http.ServeContent lo Content-Length, Range (tải tiếp khi rớt mạng) và If-Modified-Since.
//   - Không có file mà có apkURL thì server tải từ link đó rồi chuyển tiếp từng phần cho người dùng,
//     địa chỉ thật của file không lộ ra trình duyệt.
func Download(apkPath, apkURL string) gin.HandlerFunc {
	client := &http.Client{Timeout: 10 * time.Minute}
	return func(c *gin.Context) {
		c.Header("Content-Type", apkMime)
		c.Header("Content-Disposition", `attachment; filename="`+apkName+`"`)
		c.Header("Cache-Control", "no-cache") // bản mới thay file là người dùng tải được ngay

		if f, err := os.Open(apkPath); err == nil {
			defer f.Close()
			if st, err := f.Stat(); err == nil && !st.IsDir() {
				http.ServeContent(c.Writer, c.Request, apkName, st.ModTime(), f)
				return
			}
		}
		if apkURL == "" {
			noAPK(c)
			return
		}

		req, err := http.NewRequestWithContext(c.Request.Context(), http.MethodGet, apkURL, nil)
		if err != nil {
			noAPK(c)
			return
		}
		resp, err := client.Do(req) // tự đi theo redirect của GitHub Releases / Google Drive
		if err != nil {
			log.Printf("download apk: %v", err)
			noAPK(c)
			return
		}
		defer resp.Body.Close()
		if resp.StatusCode != http.StatusOK {
			log.Printf("download apk: %s trả về %d", apkURL, resp.StatusCode)
			noAPK(c)
			return
		}
		if resp.ContentLength > 0 {
			c.Header("Content-Length", strconv.FormatInt(resp.ContentLength, 10))
		}
		c.Status(http.StatusOK)
		if _, err := io.Copy(c.Writer, resp.Body); err != nil {
			log.Printf("download apk: ngắt giữa chừng: %v", err)
		}
	}
}

const (
	apkName = "timetribe.apk"
	apkMime = "application/vnd.android.package-archive"
)

func noAPK(c *gin.Context) {
	c.Header("Content-Type", "text/plain; charset=utf-8")
	c.Header("Content-Disposition", "")
	c.String(http.StatusServiceUnavailable, "Chưa có file APK, vui lòng quay lại sau.")
}
