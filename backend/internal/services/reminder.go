package services

import (
	"context"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"

	"timetribe-backend/internal/models"
	"timetribe-backend/internal/repository"
	"timetribe-backend/internal/utils"
)

// ReminderWorker mỗi phút quét lịch cá nhân và lịch nhóm, đến mốc "nhắc trước X phút"
// thì tạo thông báo loại reminder và gửi FCM.
// Trạng thái chỉ giữ trong bộ nhớ, server tắt trong lúc tới giờ nhắc thì lần nhắc đó bị bỏ qua.
type ReminderWorker struct {
	store    *repository.Store
	notifier *NotificationService
	last     time.Time
}

func NewReminderWorker(store *repository.Store, n *NotificationService) *ReminderWorker {
	return &ReminderWorker{store: store, notifier: n}
}

func (w *ReminderWorker) Start(ctx context.Context) {
	w.last = time.Now().UTC()
	ticker := time.NewTicker(time.Minute)
	go func() {
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case now := <-ticker.C:
				w.tick(ctx, now.UTC())
			}
		}
	}()
	log.Println("đã bật bộ nhắc lịch, quét mỗi phút")
}

func (w *ReminderWorker) tick(ctx context.Context, now time.Time) {
	from := w.last
	w.last = now
	ctx, cancel := context.WithTimeout(ctx, 50*time.Second)
	defer cancel()
	if err := w.personal(ctx, from, now); err != nil {
		log.Printf("nhắc lịch cá nhân lỗi: %v", err)
	}
	if err := w.group(ctx, from, now); err != nil {
		log.Printf("nhắc lịch nhóm lỗi: %v", err)
	}
}

// due kiểm tra mốc nhắc có rơi vào khoảng (from, now] hay không.
func due(start time.Time, remind int, from, now time.Time) bool {
	at := start.Add(-time.Duration(remind) * time.Minute)
	return at.After(from) && !at.After(now)
}

func (w *ReminderWorker) personal(ctx context.Context, from, now time.Time) error {
	// Mọi múi giờ đều nằm trong khoảng hôm qua tới ngày mai so với UTC
	list, err := repository.FindMany[models.Timeblock](ctx, w.store.Timeblocks, bson.M{"date": bson.M{
		"$gte": now.AddDate(0, 0, -1).Format(utils.DateLayout), "$lte": now.AddDate(0, 0, 2).Format(utils.DateLayout),
	}})
	if err != nil || len(list) == 0 {
		return err
	}
	ids := make([]string, 0, len(list))
	for _, t := range list {
		ids = append(ids, t.UserID)
	}
	users, err := w.store.UsersByIDs(ctx, ids)
	if err != nil {
		return err
	}
	for _, t := range list {
		u, ok := users[t.UserID]
		if !ok {
			continue
		}
		loc := utils.LoadLocation(u.Timezone)
		start := utils.At(t.Date, t.StartTime, loc)
		if !due(start, t.Remind, from, now) {
			continue
		}
		w.notifier.Notify(ctx, NotifyInput{
			Recipients: []string{t.UserID}, Kind: models.KindPersonalReminder, Type: models.NotiReminder,
			Args:        map[string]string{"task": t.Task, "time": start.Format("15:04"), "date": t.Date},
			ReferenceID: utils.Ptr(t.ID), ReferenceType: utils.Ptr(models.RefTimeblock),
		})
	}
	return nil
}

func (w *ReminderWorker) group(ctx context.Context, from, now time.Time) error {
	list, err := repository.FindMany[models.TribeBlock](ctx, w.store.TribeBlocks, bson.M{"date": bson.M{
		"$gte": now.AddDate(0, 0, -1).Format(utils.DateLayout), "$lte": now.AddDate(0, 0, 1).Format(utils.DateLayout),
	}})
	if err != nil {
		return err
	}
	for _, b := range list {
		r := utils.UTCRange(b.Date, b.StartTime, b.EndTime)
		if !due(r.Start, b.Remind, from, now) {
			continue
		}
		tribe, err := repository.FindOne[models.Tribe](ctx, w.store.Tribes, bson.M{"_id": b.TribeID, "deleted_at": nil})
		if err != nil || tribe == nil {
			continue
		}
		// Ai đã từ chối thì không nhắc
		rows, err := repository.FindMany[models.TribeBlockAttendance](ctx, w.store.TribeBlockAttendance, bson.M{
			"tribe_block_id": b.ID, "status": bson.M{"$ne": models.AttendanceDeclined},
		})
		if err != nil {
			continue
		}
		users := make([]string, 0, len(rows))
		for _, r := range rows {
			users = append(users, r.UserID)
		}
		profiles, _ := w.store.UsersByIDs(ctx, users)
		// Giờ hiển thị trong nội dung phải theo múi giờ của từng người nên gửi riêng từng người
		for _, uid := range users {
			loc := utils.LoadLocation(profiles[uid].Timezone)
			w.notifier.Notify(ctx, NotifyInput{
				Recipients: []string{uid}, Kind: models.KindTribeReminder, Type: models.NotiReminder,
				Args: map[string]string{
					"task": b.Task, "tribe": tribe.Name, "tribe_id": tribe.ID, "time": r.Start.In(loc).Format("15:04"),
				},
				ReferenceID: utils.Ptr(b.ID), ReferenceType: utils.Ptr(models.RefTribeBlock),
			})
		}
	}
	return nil
}
