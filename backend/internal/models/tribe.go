package models

import "time"

// Giới hạn của nhóm, khớp TribeLimits ở front-end.
const (
	MaxTribesPerUser   = 5
	MaxMembersPerTribe = 10
	MaxViceLeaders     = 3
	MaxTribeNameLength = 255
	TribeBlockRemind   = 60
)

// Giá trị enum của tribe_attendees.role.
const (
	TribeRoleLeader     = "leader"
	TribeRoleViceLeader = "vice_leader"
	TribeRoleMember     = "member"
)

// Giá trị enum của tribe_block_attendance.status.
const (
	AttendancePending  = "pending"
	AttendanceAccepted = "accepted"
	AttendanceDeclined = "declined"
)

// Bảng tribes. invite_link lưu mã mời (ví dụ NIC2026), đường dẫn đầy đủ được dựng khi trả về.
// background_color và background_image_url là hai cột có trong sheet ánh xạ.
type Tribe struct {
	ID                 string     `bson:"_id" json:"id"`
	Name               string     `bson:"name" json:"name"`
	CreatedBy          string     `bson:"created_by" json:"created_by"`
	InviteLink         string     `bson:"invite_link" json:"invite_link"`
	BackgroundColor    *string    `bson:"background_color" json:"background_color"`
	BackgroundImageURL *string    `bson:"background_image_url" json:"background_image_url"`
	CreatedAt          time.Time  `bson:"created_at" json:"created_at"`
	DeletedAt          *time.Time `bson:"deleted_at" json:"deleted_at"`
}

// Bảng tribe_attendees.
type TribeAttendee struct {
	ID       string    `bson:"_id" json:"id"`
	TribeID  string    `bson:"tribe_id" json:"tribe_id"`
	UserID   string    `bson:"user_id" json:"user_id"`
	Role     string    `bson:"role" json:"role"`
	JoinedAt time.Time `bson:"joined_at" json:"joined_at"`
}

// RoleRank dùng để sắp xếp: trưởng nhóm, phó nhóm, rồi thành viên.
func RoleRank(role string) int {
	switch role {
	case TribeRoleLeader:
		return 0
	case TribeRoleViceLeader:
		return 1
	default:
		return 2
	}
}

// Bảng tribe_blocks. date, start_time, end_time lưu theo giờ UTC vì thành viên ở nhiều múi giờ.
// Nếu end_time <= start_time thì hoạt động kết thúc vào ngày hôm sau (qua nửa đêm UTC).
type TribeBlock struct {
	ID          string    `bson:"_id" json:"id"`
	TribeID     string    `bson:"tribe_id" json:"tribe_id"`
	CreatedBy   string    `bson:"created_by" json:"created_by"`
	Task        string    `bson:"task" json:"task"`
	Description *string   `bson:"description" json:"description"`
	Date        string    `bson:"date" json:"date"`
	StartTime   string    `bson:"start_time" json:"start_time"`
	EndTime     string    `bson:"end_time" json:"end_time"`
	ColorCode   string    `bson:"color_code" json:"color_code"`
	Remind      int       `bson:"remind" json:"remind"`
	CreatedAt   time.Time `bson:"created_at" json:"created_at"`
}

// Bảng tribe_block_attendance.
type TribeBlockAttendance struct {
	ID           string    `bson:"_id" json:"id"`
	TribeBlockID string    `bson:"tribe_block_id" json:"tribe_block_id"`
	UserID       string    `bson:"user_id" json:"user_id"`
	Status       string    `bson:"status" json:"status"`
	UpdatedAt    time.Time `bson:"updated_at" json:"updated_at"`
}
