package services

import (
	"testing"
	"time"
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
