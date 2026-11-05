package models

import "time"

// Giá trị enum của notifications.type.
const (
	NotiTribeJoin            = "tribe_join"
	NotiGroupSchedule        = "group_schedule"
	NotiReminder             = "reminder"
	NotiTribeRole            = "tribe_role"
	NotiSubscriptionReminder = "subscription_reminder"
	NotiSystemBroadcast      = "system_broadcast"
)

// Loại nội dung thông báo, trùng tên với enum NotificationKind ở front-end.
// Server lưu tên này vào cột title, còn content là chuỗi JSON chứa tham số
// (actor, tribe, task...) để app tự dựng câu chữ theo ngôn ngữ người dùng đang chọn.
const (
	KindTribeNewBlock         = "tribeNewBlock"
	KindTribeBlockUpdated     = "tribeBlockUpdated"
	KindTribeBlockRescheduled = "tribeBlockRescheduled"
	KindTribeBlockCancelled   = "tribeBlockCancelled"
	KindTribeResponseAccepted = "tribeResponseAccepted"
	KindTribeResponseDeclined = "tribeResponseDeclined"
	KindTribeMemberJoined     = "tribeMemberJoined"
	KindTribeMemberLeft       = "tribeMemberLeft"
	KindTribeKickedYou        = "tribeKickedYou"
	KindTribeRenamed          = "tribeRenamed"
	KindTribeDissolved        = "tribeDissolved"
	KindTribeRoleVice         = "tribeRoleVice"
	KindTribeRoleViceRemoved  = "tribeRoleViceRemoved"
	KindTribeRoleLeader       = "tribeRoleLeader"
	KindPersonalBlockAdded    = "personalBlockAdded"
	// Hai loại dưới đây front-end chưa có, cần bổ sung vào NotificationKind
	KindPersonalReminder = "personalReminder"
	KindTribeReminder    = "tribeReminder"
)

// Giá trị cột reference_type.
const (
	RefTribe              = "tribe"
	RefTribeBlock         = "tribe_block"
	RefTribeBlockResponse = "tribe_block_response"
	RefTimeblock          = "timeblock"
)

// Thông báo chỉ giữ hiển thị trong 30 ngày gần nhất.
const NotificationRetentionDays = 30

// Bảng notifications. user_id = null nghĩa là admin gửi cho toàn bộ người dùng.
type Notification struct {
	ID            string    `bson:"_id" json:"id"`
	UserID        *string   `bson:"user_id" json:"user_id"`
	CreatedBy     *string   `bson:"created_by" json:"created_by"`
	Title         string    `bson:"title" json:"title"`
	Content       string    `bson:"content" json:"content"`
	Type          string    `bson:"type" json:"type"`
	ReferenceID   *string   `bson:"reference_id" json:"reference_id"`
	ReferenceType *string   `bson:"reference_type" json:"reference_type"`
	IsRead        bool      `bson:"is_read" json:"is_read"`
	CreatedAt     time.Time `bson:"created_at" json:"created_at"`
}
