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
	}{
		{"đúng phút nhắc", 5, start.Add(-6 * time.Minute), start.Add(-5 * time.Minute), true},
		{"chưa tới", 5, start.Add(-7 * time.Minute), start.Add(-6 * time.Minute), false},
		{"đã nhắc ở phút trước", 5, start.Add(-5 * time.Minute), start.Add(-4 * time.Minute), false},
		{"nhắc lúc bắt đầu", 0, start.Add(-time.Minute), start, true},
		{"nhắc bù sau khi server ngủ, lịch chưa bắt đầu", 15, start.Add(-time.Hour), start.Add(-2 * time.Minute), true},
		{"nhắc bù nhưng lịch đã bắt đầu lâu", 15, start.Add(-time.Hour), start.Add(30 * time.Minute), false},
	}
	for _, c := range cases {
		if _, got := due(start, c.remind, c.from, c.now); got != c.want {
			t.Errorf("%s: got %v want %v", c.name, got, c.want)
		}
	}
}
