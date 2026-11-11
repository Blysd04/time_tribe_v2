package utils

import (
	"testing"
	"time"
)

// Server phải tính giờ giống điện thoại (dữ liệu IANA mới), không theo dữ liệu cũ của Go.
func TestEmbeddedTimezones(t *testing.T) {
	at := time.Date(2026, 11, 8, 12, 0, 0, 0, time.UTC)
	cases := map[string]int{
		"America/Vancouver": -7 * 3600, // British Columbia giữ cố định UTC-7
		"Asia/Ho_Chi_Minh":  7 * 3600,
		"Asia/Saigon":       7 * 3600,
		"Etc/GMT-7":         7 * 3600,
		"Asia/Tokyo":        9 * 3600,
		"Europe/London":     0,
	}
	for tz, want := range cases {
		if !IsValidTimezone(tz) {
			t.Fatalf("%s phải hợp lệ", tz)
		}
		if _, off := at.In(LoadLocation(tz)).Zone(); off != want {
			t.Errorf("%s: lệch %d giây, muốn %d", tz, off, want)
		}
	}
	if _, ok := tzFiles["America/Vancouver"]; !ok {
		t.Fatal("dữ liệu múi giờ nhúng không đọc được")
	}
	if IsValidTimezone("GMT+08:00") || IsValidTimezone("Mars/Base") {
		t.Error("tên múi giờ sai phải bị từ chối")
	}
	// Lịch 19:55 ngày 8/11 ở Vancouver = 02:55 UTC ngày 9/11
	if got := At("2026-11-08", "19:55:00", LoadLocation("America/Vancouver")).UTC(); !got.Equal(time.Date(2026, 11, 9, 2, 55, 0, 0, time.UTC)) {
		t.Errorf("Vancouver 19:55 = %v", got)
	}
}
