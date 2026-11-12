package services

import (
	"context"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"

	"timetribe-backend/internal/models"
	"timetribe-backend/internal/repository"
	"timetribe-backend/internal/utils"
)

// shiftTimeblocks đổi lịch cá nhân của người dùng sang múi giờ mới mà vẫn giữ đúng thời điểm thực.
//
// Lịch cá nhân lưu ngày + giờ theo múi giờ của chủ lịch. Nếu chỉ đổi múi giờ mà giữ nguyên giờ ghi,
// "Học lúc 17:00 giờ Vancouver" sẽ thành 17:00 giờ Los Angeles, lệch 1 tiếng so với hoạt động nhóm
// (lưu theo UTC nên tự đổi đúng) và các khối trên lịch bị xáo trộn. Vì vậy khi múi giờ đổi,
// mỗi lịch được tính lại ngày + giờ ở múi giờ mới cho cùng một thời điểm (giống Google Calendar).
func (s *UserService) shiftTimeblocks(ctx context.Context, userID string, from, to *time.Location) {
	if from.String() == to.String() {
		return
	}
	list, err := repository.FindMany[models.Timeblock](ctx, s.store.Timeblocks, bson.M{"user_id": userID})
	if err != nil {
		log.Printf("đổi múi giờ lịch cá nhân lỗi: %v", err)
		return
	}
	writes := make([]mongo.WriteModel, 0, len(list))
	for _, t := range list {
		r := utils.LocalRange(t.Date, t.StartTime, t.EndTime, from)
		st, en := r.Start.In(to), r.End.In(to)
		date := st.Format(utils.DateLayout)
		set := bson.M{
			"date":       date,
			"start_time": st.Format(utils.ClockLayout),
			"end_time":   en.Format(utils.ClockLayout),
		}
		// Ngày của các bản nhân bản ghi kèm cũng lùi/tiến theo cùng số ngày
		if len(t.RepeatingDates) > 0 && date != t.Date {
			delta := dayDiff(t.Date, date)
			shifted := make([]string, len(t.RepeatingDates))
			for i, d := range t.RepeatingDates {
				shifted[i] = utils.AddDays(d, delta)
			}
			set["repeating_dates"] = shifted
		}
		writes = append(writes, mongo.NewUpdateOneModel().
			SetFilter(bson.M{"_id": t.ID}).SetUpdate(bson.M{"$set": set}))
	}
	if len(writes) == 0 {
		return
	}
	if _, err := s.store.Timeblocks.BulkWrite(ctx, writes); err != nil {
		log.Printf("đổi múi giờ lịch cá nhân lỗi: %v", err)
		return
	}
	log.Printf("đã đổi %d lịch cá nhân của %s từ %s sang %s", len(writes), userID, from, to)
}

// dayDiff trả số ngày từ a tới b (YYYY-MM-DD).
func dayDiff(a, b string) int {
	da, _ := utils.ParseDate(a)
	db, _ := utils.ParseDate(b)
	return int(db.Sub(da).Hours() / 24)
}
