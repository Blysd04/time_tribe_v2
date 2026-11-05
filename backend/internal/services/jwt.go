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

func init() {
	// Ghi iat chính xác tới mili giây để so với password_changed_at,
	// tránh trường hợp đổi mật khẩu cùng một giây với lúc cấp token mà token cũ vẫn dùng được
	jwt.TimePrecision = time.Millisecond
}

type JWTManager struct {
	secret []byte
	ttl    time.Duration
}

func NewJWTManager(secret string, ttl time.Duration) *JWTManager {
	return &JWTManager{secret: []byte(secret), ttl: ttl}
}

func (m *JWTManager) TTL() time.Duration { return m.ttl }

func (m *JWTManager) Issue(userID, role string) (string, error) {
	now := time.Now()
	claims := AccessClaims{
		Role: role,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID,
			Issuer:    "timetribe",
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(m.ttl)),
		},
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(m.secret)
}

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
