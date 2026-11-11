package utils

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"math/big"
	"net/url"
	"regexp"
	"strings"
	"unicode/utf8"
)

var hexColor = regexp.MustCompile(`^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$`)

// IsHexColor kiểm tra mã màu dạng #RRGGBB hoặc #AARRGGBB.
func IsHexColor(s string) bool { return hexColor.MatchString(s) }

// Len đếm số ký tự (không phải số byte) để tiếng Việt có dấu tính đúng.
func Len(s string) int { return utf8.RuneCountInString(s) }

// TrimPtr cắt khoảng trắng, chuỗi rỗng thì trả về nil.
func TrimPtr(s *string) *string {
	if s == nil {
		return nil
	}
	v := strings.TrimSpace(*s)
	if v == "" {
		return nil
	}
	return &v
}

// Ptr lấy con trỏ của một giá trị (Go không cho viết &"abc" trực tiếp).
func Ptr[T any](v T) *T { return &v }

// RandomToken sinh chuỗi ngẫu nhiên dạng hex (n byte ngẫu nhiên).
func RandomToken(n int) string {
	b := make([]byte, n)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

// RandomCode sinh mã từ bảng ký tự cho trước (dùng cho mã mời nhóm, mã chia sẻ).
func RandomCode(n int, alphabet string) string {
	out := make([]byte, n)
	max := big.NewInt(int64(len(alphabet)))
	for i := range out {
		k, _ := rand.Int(rand.Reader, max)
		out[i] = alphabet[k.Int64()]
	}
	return string(out)
}

// HashToken băm SHA-256 chuỗi token để lưu vào database thay cho bản gốc.
func HashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

// LastPathSegment lấy phần cuối của đường dẫn, ví dụ
// https://timetribe.app/tribe/NIC2026 -> NIC2026, hoặc người dùng chỉ dán "NIC2026".
func LastPathSegment(link string) string {
	link = strings.TrimSpace(link)
	if link == "" {
		return ""
	}
	if u, err := url.Parse(link); err == nil {
		parts := strings.Split(strings.Trim(u.Path, "/"), "/")
		for i := len(parts) - 1; i >= 0; i-- {
			if parts[i] != "" {
				return parts[i]
			}
		}
	}
	return ""
}

// ContainsInt kiểm tra số v có trong danh sách không.
func ContainsInt(list []int, v int) bool {
	for _, x := range list {
		if x == v {
			return true
		}
	}
	return false
}
