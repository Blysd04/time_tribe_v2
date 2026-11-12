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
	// Hai collection phụ của bộ nhắc lịch
	CollWorkerState  = "worker_state"  // mốc quét cuối, để nhắc bù khi server khởi động lại
	CollReminderLogs = "reminder_logs" // các lần đã nhắc, chống gửi trùng
)

const DefaultTimezone = "Asia/Ho_Chi_Minh"

// Bảng users: thông tin công khai của người dùng.
// fcm_token là mã thiết bị nhận thông báo đẩy, app gửi lên khi đăng nhập Google, không có thì để null.
type User struct {
	ID        string  `bson:"_id" json:"id"`
	Email     string  `bson:"email" json:"email"`
	NickName  string  `bson:"nick_name" json:"nick_name"`
	AvatarURL *string `bson:"avatar_url" json:"avatar_url"`
	Timezone  string  `bson:"timezone" json:"timezone"`
	FCMToken  *string `bson:"fcm_token" json:"fcm_token"`
	// Ngôn ngữ app đang dùng (vi, en, fr): thông báo đẩy và email gửi theo ngôn ngữ này
	Language string `bson:"language,omitempty" json:"language"`
	// NeedsOnboarding = true với tài khoản mới tạo, app hiện màn hình chào mừng + hướng dẫn
	// rồi gửi false lên. Tài khoản cũ không có trường này nên coi như đã xong.
	NeedsOnboarding bool `bson:"needs_onboarding,omitempty" json:"needs_onboarding"`
	// Cách chọn múi giờ, lưu trên server để mọi máy của người dùng hiển thị giống nhau.
	// timezone_auto: nil/true = theo múi giờ của thiết bị, false = người dùng tự chọn thành phố.
	TimezoneAuto    *bool     `bson:"timezone_auto,omitempty" json:"-"`
	TimezoneCity    *string   `bson:"timezone_city,omitempty" json:"timezone_city"`
	TimezoneCountry *string   `bson:"timezone_country,omitempty" json:"timezone_country"`
	CreatedAt       time.Time `bson:"created_at" json:"created_at"`
	UpdatedAt       time.Time `bson:"updated_at" json:"updated_at"`
}

// IsTimezoneAuto: tài khoản cũ chưa có cột timezone_auto thì coi như tự động.
func (u *User) IsTimezoneAuto() bool { return u.TimezoneAuto == nil || *u.TimezoneAuto }

// AppUser là bản rút gọn để hiển thị trong danh sách thành viên, người tham gia...
// (không lộ email của người khác).
type AppUser struct {
	ID        string  `json:"id"`
	NickName  string  `json:"nick_name"`
	AvatarURL *string `json:"avatar_url"`
	Timezone  string  `json:"timezone"`
}

// Short lấy bản rút gọn của người dùng để hiện cho người khác xem (không có email, fcm_token).
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
const (
	TokenRefresh       = "refresh"
	TokenResetPassword = "reset_password"
	TokenChangeEmail   = "change_email" // xác nhận email mới, new_email giữ địa chỉ đang chờ
)

// Bảng user_tokens.
// Cột token lưu chuỗi băm SHA-256 chứ không lưu bản gốc, lỡ lộ database thì cũng không dùng lại được.
type UserToken struct {
	ID         string  `bson:"_id" json:"id"`
	UserID     string  `bson:"user_id" json:"user_id"`
	Token      string  `bson:"token" json:"-"`
	TokenType  string  `bson:"token_type" json:"token_type"`
	DeviceInfo *string `bson:"device_info" json:"device_info"`
	// Chỉ dùng với token_type = change_email: email mới đang chờ xác nhận
	NewEmail  *string   `bson:"new_email,omitempty" json:"-"`
	ExpiresAt time.Time `bson:"expires_at" json:"expires_at"`
	CreatedAt time.Time `bson:"created_at" json:"created_at"`
}
