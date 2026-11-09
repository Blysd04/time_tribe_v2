package handlers

import (
	_ "embed"
	"net/http"

	"github.com/gin-gonic/gin"
)

// landing.html là trang giới thiệu + nút tải APK (cùng nội dung với trang đã publish).
// File chỉ có phần thân trang nên khi phục vụ thì bọc thêm khung HTML.
//
//go:embed web/landing.html
var landingBody string

var landingPage = []byte(`<!doctype html><html lang="vi"><head><meta charset="utf-8">` +
	`<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">` +
	`<style>body{margin:0}img{max-width:100%}[hidden]{display:none!important}</style></head><body>` +
	landingBody + `</body></html>`)

// Landing xử lý GET /: trang tải ứng dụng.
func Landing(c *gin.Context) {
	c.Data(http.StatusOK, "text/html; charset=utf-8", landingPage)
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
