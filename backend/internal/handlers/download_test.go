package handlers

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/gin-gonic/gin"
)

func serve(h gin.HandlerFunc, hdr map[string]string) *httptest.ResponseRecorder {
	gin.SetMode(gin.TestMode)
	r := gin.New()
	r.GET("/download", h)
	req := httptest.NewRequest(http.MethodGet, "/download", nil)
	for k, v := range hdr {
		req.Header.Set(k, v)
	}
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	return w
}

func TestDownloadServesFile(t *testing.T) {
	p := filepath.Join(t.TempDir(), "a.apk")
	os.WriteFile(p, []byte("PK-fake-apk"), 0o644)

	w := serve(Download(p, ""), nil)
	if w.Code != 200 || w.Body.String() != "PK-fake-apk" {
		t.Fatalf("code %d body %q", w.Code, w.Body.String())
	}
	if w.Header().Get("Content-Type") != apkMime || w.Header().Get("Content-Disposition") == "" {
		t.Fatalf("headers %v", w.Header())
	}
	if w.Header().Get("Location") != "" {
		t.Fatal("không được redirect")
	}
	// Tải tiếp từ byte 3
	w = serve(Download(p, ""), map[string]string{"Range": "bytes=3-"})
	if w.Code != http.StatusPartialContent || w.Body.String() != "fake-apk" {
		t.Fatalf("range: code %d body %q", w.Code, w.Body.String())
	}
}

func TestDownloadProxiesURL(t *testing.T) {
	src := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("remote-apk"))
	}))
	defer src.Close()

	w := serve(Download("/khong/co/file.apk", src.URL), nil)
	if w.Code != 200 || w.Body.String() != "remote-apk" || w.Header().Get("Location") != "" {
		t.Fatalf("code %d body %q", w.Code, w.Body.String())
	}
}

func TestDownloadMissing(t *testing.T) {
	w := serve(Download("/khong/co/file.apk", ""), nil)
	if w.Code != http.StatusServiceUnavailable || w.Header().Get("Content-Disposition") != "" {
		t.Fatalf("code %d headers %v", w.Code, w.Header())
	}
}

func TestFindAPKFromSubdirs(t *testing.T) {
	root, _ := filepath.EvalSymlinks(t.TempDir())
	want := filepath.Join(root, "backend", "public", "timetribe.apk")
	os.MkdirAll(filepath.Dir(want), 0o755)
	os.MkdirAll(filepath.Join(root, "backend", "cmd", "server"), 0o755)
	os.WriteFile(want, []byte("x"), 0o644)
	wd, _ := os.Getwd()
	defer os.Chdir(wd)

	// Gốc repo, backend/, backend/cmd/server (Render chạy Go trực tiếp)
	for _, dir := range []string{root, filepath.Join(root, "backend"), filepath.Join(root, "backend", "cmd", "server")} {
		os.Chdir(dir)
		if got := findAPK("public/timetribe.apk"); got != want {
			t.Fatalf("chạy ở %s: got %q", dir, got)
		}
	}
}
