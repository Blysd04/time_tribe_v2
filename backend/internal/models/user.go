package models

import "time"

// Tên collection trong MongoDB, giữ đúng tên bảng trong thiết kế CSDL.
const (
	CollUsers                = "users"
	CollUserSecurities       = "user_securities"
	CollUserTokens           = "user_tokens"
	CollTimeblocks           = "timeblocks"
	CollTemplates            = "templates"
	CollTemplateBlocks       = "template_blocks"
	CollTribes               = "tribes"
	CollTribeAttendees       = "tribe_attendees"
	CollTribeBlocks          = "tribe_blocks"
	CollTribeBlockAttendance = "tribe_block_attendance"
	CollNotifications        = "notifications"
)

const DefaultTimezone = "Asia/Ho_Chi_Minh"

// Bảng users: thông tin công khai của người dùng.
type User struct {
	ID        string    `bson:"_id" json:"id"`
	Email     string    `bson:"email" json:"email"`
	NickName  string    `bson:"nick_name" json:"nick_name"`
	AvatarURL *string   `bson:"avatar_url" json:"avatar_url"`
	Timezone  string    `bson:"timezone" json:"timezone"`
	CreatedAt time.Time `bson:"created_at" json:"created_at"`
	UpdatedAt time.Time `bson:"updated_at" json:"updated_at"`
}

// AppUser là bản rút gọn để hiển thị trong danh sách thành viên, người tham gia...
// (không lộ email của người khác).
type AppUser struct {
	ID        string  `json:"id"`
	NickName  string  `json:"nick_name"`
	AvatarURL *string `json:"avatar_url"`
	Timezone  string  `json:"timezone"`
}

func (u *User) Short() AppUser {
	return AppUser{ID: u.ID, NickName: u.NickName, AvatarURL: u.AvatarURL, Timezone: u.Timezone}
}

// Giá trị enum của user_securities.
const (
	RoleCustomer = "customer"
	RoleAdmin    = "admin"

	ProviderLocal  = "local"
	ProviderGoogle = "google"
)

// Bảng user_securities: quan hệ 1-1 với users, khoá chính chính là user_id.
type UserSecurity struct {
	UserID            string     `bson:"_id" json:"user_id"`
	Role              string     `bson:"role" json:"role"`
	AuthProvider      string     `bson:"auth_provider" json:"auth_provider"`
	GoogleID          *string    `bson:"google_id,omitempty" json:"google_id"`
	PasswordHash      *string    `bson:"password_hash" json:"-"`
	PasswordChangedAt *time.Time `bson:"password_changed_at" json:"password_changed_at"`
	IsBanned          bool       `bson:"is_banned" json:"is_banned"`
	BanReason         *string    `bson:"ban_reason" json:"ban_reason"`
	DeleteAt          *time.Time `bson:"delete_at" json:"delete_at"`
	DeleteReason      *string    `bson:"delete_reason" json:"delete_reason"`
}

// Giá trị enum của user_tokens.token_type.
// fcm là giá trị bổ sung để lưu mã thiết bị nhận thông báo đẩy của Firebase.
const (
	TokenRefresh       = "refresh"
	TokenResetPassword = "reset_password"
	TokenFCM           = "fcm"
)

// Bảng user_tokens.
// Với refresh và reset_password, cột token lưu chuỗi băm SHA-256 chứ không lưu bản gốc,
// lỡ lộ database thì cũng không dùng lại được. Riêng fcm phải lưu bản gốc để gửi thông báo.
type UserToken struct {
	ID         string    `bson:"_id" json:"id"`
	UserID     string    `bson:"user_id" json:"user_id"`
	Token      string    `bson:"token" json:"-"`
	TokenType  string    `bson:"token_type" json:"token_type"`
	DeviceInfo *string   `bson:"device_info" json:"device_info"`
	ExpiresAt  time.Time `bson:"expires_at" json:"expires_at"`
	CreatedAt  time.Time `bson:"created_at" json:"created_at"`
}
