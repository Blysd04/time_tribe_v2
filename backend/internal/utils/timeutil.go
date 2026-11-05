package utils

import (
	"fmt"
	"strings"
	"time"
)

const (
	DateLayout  = "2006-01-02"
	ClockLayout = "15:04:05"
)

// LoadLocation trả về múi giờ IANA, sai tên thì dùng giờ Việt Nam.
func LoadLocation(tz string) *time.Location {
	loc, err := time.LoadLocation(tz)
	if err != nil || tz == "" {
		loc, _ = time.LoadLocation("Asia/Ho_Chi_Minh")
	}
	return loc
}

func IsValidTimezone(tz string) bool {
	if tz == "" || tz == "Local" {
		return false
	}
	_, err := time.LoadLocation(tz)
	return err == nil
}

// ParseDate kiểm tra chuỗi YYYY-MM-DD.
func ParseDate(s string) (time.Time, error) {
	return time.Parse(DateLayout, strings.TrimSpace(s))
}

// NormalizeClock nhận "HH:mm" hoặc "HH:mm:ss", trả về dạng "HH:mm:ss".
func NormalizeClock(s string) (string, error) {
	s = strings.TrimSpace(s)
	for _, layout := range []string{ClockLayout, "15:04"} {
		if t, err := time.Parse(layout, s); err == nil {
			return t.Format(ClockLayout), nil
		}
	}
	return "", fmt.Errorf("giờ không hợp lệ: %q", s)
}

// ClockMinutes đổi "HH:mm:ss" ra số phút tính từ 0 giờ.
func ClockMinutes(s string) int {
	t, err := time.Parse(ClockLayout, s)
	if err != nil {
		return 0
	}
	return t.Hour()*60 + t.Minute()
}

// At ghép ngày + giờ trong một múi giờ cụ thể.
func At(date, clock string, loc *time.Location) time.Time {
	d, _ := time.Parse(DateLayout, date)
	m := ClockMinutes(clock)
	return time.Date(d.Year(), d.Month(), d.Day(), m/60, m%60, 0, 0, loc)
}

// TodayIn trả về ngày hôm nay (YYYY-MM-DD) theo múi giờ.
func TodayIn(loc *time.Location) string {
	return time.Now().In(loc).Format(DateLayout)
}

// AddDays cộng ngày cho chuỗi YYYY-MM-DD.
func AddDays(date string, n int) string {
	d, _ := time.Parse(DateLayout, date)
	return d.AddDate(0, 0, n).Format(DateLayout)
}

// TimeRange là một khoảng thời gian tuyệt đối, dùng so lịch giữa các múi giờ.
type TimeRange struct {
	Start time.Time `json:"start"`
	End   time.Time `json:"end"`
}

func (r TimeRange) Overlaps(o TimeRange) bool {
	return r.Start.Before(o.End) && r.End.After(o.Start)
}

// Clip cắt khoảng theo cửa sổ, không giao nhau thì trả về false.
func (r TimeRange) Clip(w TimeRange) (TimeRange, bool) {
	s, e := r.Start, r.End
	if w.Start.After(s) {
		s = w.Start
	}
	if w.End.Before(e) {
		e = w.End
	}
	if !e.After(s) {
		return TimeRange{}, false
	}
	return TimeRange{Start: s.UTC(), End: e.UTC()}, true
}

// DayWindow là khoảng 0h hôm đó tới 0h hôm sau theo múi giờ, đổi ra UTC.
func DayWindow(date string, loc *time.Location) TimeRange {
	start := At(date, "00:00:00", loc)
	end := At(AddDays(date, 1), "00:00:00", loc)
	return TimeRange{Start: start.UTC(), End: end.UTC()}
}

// UTCRange tính khoảng thời gian của hoạt động nhóm (lưu theo UTC).
// end_time <= start_time nghĩa là kết thúc vào ngày hôm sau.
func UTCRange(date, start, end string) TimeRange {
	s := At(date, start, time.UTC)
	e := At(date, end, time.UTC)
	if !e.After(s) {
		e = e.Add(24 * time.Hour)
	}
	return TimeRange{Start: s, End: e}
}

// LocalRange tính khoảng thời gian của lịch cá nhân theo múi giờ chủ lịch.
func LocalRange(date, start, end string, loc *time.Location) TimeRange {
	s := At(date, start, loc)
	e := At(date, end, loc)
	if !e.After(s) {
		e = e.Add(24 * time.Hour)
	}
	return TimeRange{Start: s.UTC(), End: e.UTC()}
}
