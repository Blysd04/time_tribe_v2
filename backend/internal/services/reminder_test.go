package services

import (
	"testing"
	"time"

	"timetribe-backend/internal/utils"
)

func TestDue(t *testing.T) {
	start := time.Date(2026, 11, 8, 15, 0, 0, 0, time.UTC) // 22:00 giờ VN
	cases := []struct {
		name      string
		remind    int
		from, now time.Time
		want      bool
		late      bool
	}{
		{"đúng phút nhắc", 5, start.Add(-6 * time.Minute), start.Add(-5 * time.Minute), true, false},
		{"chưa tới", 5, start.Add(-7 * time.Minute), start.Add(-6 * time.Minute), false, false},
		{"đã nhắc ở phút trước", 5, start.Add(-5 * time.Minute), start.Add(-4 * time.Minute), false, false},
		{"nhắc lúc bắt đầu", 0, start.Add(-time.Minute), start, true, false},
		{"nhắc bù sau khi server tắt, lịch chưa bắt đầu", 15, start.Add(-time.Hour), start.Add(-2 * time.Minute), true, false},
		{"nhắc bù khi lịch đã bắt đầu: vẫn lưu, không đẩy", 60, start.Add(-3 * time.Hour), start.Add(30 * time.Minute), true, true},
	}
	for _, c := range cases {
		_, got, late := due(start, c.remind, c.from, c.now)
		if got != c.want || (got && late != c.late) {
			t.Errorf("%s: got %v/%v want %v/%v", c.name, got, late, c.want, c.late)
		}
	}
}

// Đúng ca người dùng báo lỗi: lịch cá nhân 19:55 ngày 8/11 giờ Việt Nam, nhắc trước 5 phút
// thì phải nhắc lúc 19:50 giờ Việt Nam (12:50 UTC), không phải lệch 1 tiếng.
func TestPersonalReminderVietnam(t *testing.T) {
	loc := utils.LoadLocation("Asia/Ho_Chi_Minh")
	start := utils.At("2026-11-08", "19:55:00", loc)
	want := time.Date(2026, 11, 8, 12, 50, 0, 0, time.UTC)
	// Bộ nhắc quét đúng đầu phút: phút 12:49 -> 12:50 UTC
	at, ok, late := due(start, 5, want.Add(-time.Minute), want)
	if !ok || late || !at.Equal(want) {
		t.Fatalf("at=%v ok=%v late=%v, muốn %v", at.UTC(), ok, late, want)
	}
	// Tên cũ của múi giờ VN và dạng Etc mà app có thể gửi lên cũng phải ra cùng giờ
	for _, tz := range []string{"Asia/Saigon", "Etc/GMT-7"} {
		if !utils.IsValidTimezone(tz) {
			t.Fatalf("%s phải hợp lệ", tz)
		}
		if s := utils.At("2026-11-08", "19:55:00", utils.LoadLocation(tz)); !s.Equal(start) {
			t.Fatalf("%s: %v khác %v", tz, s.UTC(), start.UTC())
		}
	}
}

// Điện thoại đặt múi giờ Vancouver: lịch 19:55 ngày 8/11, nhắc trước 5 phút -> 02:50 UTC ngày 9/11
// (UTC-7). Dữ liệu múi giờ cũ của Go tính UTC-8 nên từng nhắc trễ 1 tiếng.
func TestPersonalReminderVancouver(t *testing.T) {
	start := utils.At("2026-11-08", "19:55:00", utils.LoadLocation("America/Vancouver"))
	want := time.Date(2026, 11, 9, 2, 50, 0, 0, time.UTC)
	at, ok, late := due(start, 5, want.Add(-time.Minute), want)
	if !ok || late || !at.Equal(want) {
		t.Fatalf("at=%v ok=%v late=%v, muốn %v", at.UTC(), ok, late, want)
	}
}

func TestShiftKeepsInstant(t *testing.T) {
	from := utils.LoadLocation("America/Vancouver")
	to := utils.LoadLocation("Asia/Ho_Chi_Minh")
	r := utils.LocalRange("2026-11-10", "17:01:00", "18:55:00", from)
	st := r.Start.In(to)
	if got := st.Format("2006-01-02 15:04"); got != "2026-11-11 07:01" {
		t.Fatalf("đổi múi giờ sai: %s", got)
	}
	if dayDiff("2026-11-10", "2026-11-11") != 1 || dayDiff("2026-11-11", "2026-11-10") != -1 {
		t.Fatal("dayDiff sai")
	}
}
