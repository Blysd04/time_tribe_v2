package models

import "time"

const MaxTemplates = 10

// Bảng templates. share_code là mã chia sẻ lịch mẫu, ví dụ GYM4DAY, chưa chia sẻ thì để null.
type Template struct {
	ID                 string    `bson:"_id" json:"id"`
	UserID             string    `bson:"user_id" json:"user_id"`
	OriginalTemplateID *string   `bson:"original_template_id" json:"original_template_id"`
	TemplateName       string    `bson:"template_name" json:"template_name"`
	ShareCode          *string   `bson:"share_code,omitempty" json:"share_code"`
	DateModified       time.Time `bson:"date_modified" json:"date_modified"`
	CreatedAt          time.Time `bson:"created_at" json:"created_at"`
}

// Bảng template_blocks. day_index: 1 là thứ Hai, 7 là Chủ nhật.
type TemplateBlock struct {
	ID          string  `bson:"_id" json:"id"`
	TemplateID  string  `bson:"template_id" json:"template_id"`
	DayIndex    int     `bson:"day_index" json:"day_index"`
	Title       string  `bson:"title" json:"title"`
	Description *string `bson:"description" json:"description"`
	StartTime   string  `bson:"start_time" json:"start_time"`
	EndTime     string  `bson:"end_time" json:"end_time"`
	ColorCode   string  `bson:"color_code" json:"color_code"`
	Remind      int     `bson:"remind" json:"remind"`
}
