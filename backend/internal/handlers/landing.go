package handlers

import (
	_ "embed"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
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
	apkPath = findAPK(apkPath)
	logAPK(apkPath, apkURL)
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

// findAPK tìm file APK khi APK_PATH là đường dẫn tương đối. Thư mục chạy server tuỳ cách deploy:
// Docker chạy ở /app; Render chạy Go trực tiếp có thể đứng ở gốc repo, ở backend/ hay ở backend/cmd/server.
// Vì vậy đi ngược lên từ thư mục hiện tại và thư mục chứa file chạy, ở mỗi cấp thử <cấp>/p và <cấp>/backend/p.
func findAPK(p string) string {
	if p == "" || filepath.IsAbs(p) {
		return p
	}
	var starts []string
	if wd, err := os.Getwd(); err == nil {
		starts = append(starts, wd)
	}
	if exe, err := os.Executable(); err == nil {
		starts = append(starts, filepath.Dir(exe))
	}
	for _, dir := range starts {
		for {
			for _, c := range []string{filepath.Join(dir, p), filepath.Join(dir, "backend", p)} {
				if st, err := os.Stat(c); err == nil && !st.IsDir() {
					return c
				}
			}
			parent := filepath.Dir(dir)
			if parent == dir {
				break
			}
			dir = parent
		}
	}
	return p
}

// logAPK ghi ra log lúc khởi động server đang lấy APK từ đâu, để biết vì sao /download báo thiếu file.
func logAPK(apkPath, apkURL string) {
	abs, _ := filepath.Abs(apkPath)
	if st, err := os.Stat(apkPath); err == nil && !st.IsDir() {
		log.Printf("APK: %s (%.1f MB)", abs, float64(st.Size())/(1<<20))
		return
	}
	if apkURL != "" {
		log.Printf("APK: không thấy %s, tải qua APK_URL", abs)
		return
	}
	log.Printf("APK: không thấy %s và APK_URL trống, /download sẽ báo chưa có file", abs)
}
