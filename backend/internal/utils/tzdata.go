package utils

import (
	"archive/zip"
	"bytes"
	_ "embed"
	"io"
	"sync"
	"time"
)

// Dữ liệu múi giờ IANA bản mới (xem tzdata/VERSION), nhúng thẳng vào file chạy.
//
// Không dùng dữ liệu đi kèm Go hay của máy chủ vì có thể đã cũ. Ví dụ dữ liệu của Go 1.23/1.24
// vẫn tính America/Vancouver tháng 11/2026 là UTC-8, trong khi British Columbia đã giữ cố định
// UTC-7 (Android và các bản IANA mới đều đúng). Server tính lệch thì nhắc lịch trễ 1 tiếng và
// hiện sai giờ. Muốn cập nhật: thay tzdata/zoneinfo.zip bằng bản mới (mỗi file trong zip là một
// file TZif đặt theo tên múi giờ, VD "America/Vancouver").
//
//go:embed tzdata/zoneinfo.zip
var zoneinfoZip []byte

var (
	tzOnce  sync.Once
	tzFiles map[string]*zip.File
	tzCache sync.Map // tên múi giờ -> *time.Location
)

// loadZone đọc múi giờ từ dữ liệu nhúng, không có thì dùng time.LoadLocation của Go.
func loadZone(name string) (*time.Location, error) {
	if name == "UTC" || name == "" {
		return time.UTC, nil
	}
	if v, ok := tzCache.Load(name); ok {
		return v.(*time.Location), nil
	}
	tzOnce.Do(func() {
		tzFiles = map[string]*zip.File{}
		r, err := zip.NewReader(bytes.NewReader(zoneinfoZip), int64(len(zoneinfoZip)))
		if err != nil {
			return
		}
		for _, f := range r.File {
			tzFiles[f.Name] = f
		}
	})
	if f, ok := tzFiles[name]; ok {
		if rc, err := f.Open(); err == nil {
			data, err := io.ReadAll(rc)
			rc.Close()
			if err == nil {
				if loc, err := time.LoadLocationFromTZData(name, data); err == nil {
					tzCache.Store(name, loc)
					return loc, nil
				}
			}
		}
	}
	return time.LoadLocation(name)
}
