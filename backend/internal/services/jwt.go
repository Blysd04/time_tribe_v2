package services

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// AccessClaims là nội dung JWT access token.
type AccessClaims struct {
	Role string `json:"role"`
	jwt.RegisteredClaims
}

// init đặt độ chính xác của iat trong JWT tới mili giây.
func init() {
	// Ghi iat chính xác tới mili giây để so với password_changed_at,
	// tránh trường hợp đổi mật khẩu cùng một giây với lúc cấp token mà token cũ vẫn dùng được
	jwt.TimePrecision = time.Millisecond
}

type JWTManager struct {
	secret []byte
	ttl    time.Duration
}

// NewJWTManager tạo bộ ký và đọc access token.
func NewJWTManager(secret string, ttl time.Duration) *JWTManager {
	return &JWTManager{secret: []byte(secret), ttl: ttl}
}

// TTL là thời gian sống của access token.
func (m *JWTManager) TTL() time.Duration { return m.ttl }

// Issue tạo access token cho user. sessionID là id của dòng refresh token trong user_tokens,
// được ghi vào claim jti để middleware biết token này thuộc phiên đăng nhập nào.
func (m *JWTManager) Issue(userID, role, sessionID string) (string, error) {
	now := time.Now()
	claims := AccessClaims{
		Role: role,
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        sessionID,
			Subject:   userID,
			Issuer:    "timetribe",
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(m.ttl)),
		},
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(m.secret)
}

// Parse kiểm tra chữ ký và hạn của access token rồi trả về nội dung bên trong.
func (m *JWTManager) Parse(token string) (*AccessClaims, error) {
	claims := &AccessClaims{}
	parsed, err := jwt.ParseWithClaims(token, claims, func(t *jwt.Token) (any, error) {
		if t.Method != jwt.SigningMethodHS256 {
			return nil, errors.New("sai thuật toán ký")
		}
		return m.secret, nil
	})
	if err != nil || !parsed.Valid {
		return nil, errors.New("token không hợp lệ hoặc đã hết hạn")
	}
	return claims, nil
}
