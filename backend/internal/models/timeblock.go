package models

import "time"

// Bảng timeblocks: lịch cá nhân.
// date (YYYY-MM-DD), start_time, end_time (HH:mm:ss) tính theo múi giờ của chính chủ lịch.
type Timeblock struct {
	ID             string    `bson:"_id" json:"id"`
	UserID         string    `bson:"user_id" json:"user_id"`
	Task           string    `bson:"task" json:"task"`
	Description    *string   `bson:"description" json:"description"`
	Date           string    `bson:"date" json:"date"`
	StartTime      string    `bson:"start_time" json:"start_time"`
	EndTime        string    `bson:"end_time" json:"end_time"`
	ColorCode      string    `bson:"color_code" json:"color_code"`
	RepeatingDates []string  `bson:"repeating_dates" json:"repeating_dates"`
	Remind         int       `bson:"remind" json:"remind"`
	CreatedAt      time.Time `bson:"created_at" json:"created_at"`
}

// Các mốc nhắc trước cho phép chọn trên giao diện (phút).
var RemindOptions = []int{0, 5, 10, 15, 30, 60}
