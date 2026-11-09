package services

import (
	"context"
	"fmt"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"timetribe-backend/internal/models"
	"timetribe-backend/internal/repository"
	"timetribe-backend/internal/utils"
)

const (
	// maxCatchUp: server tắt/ngủ lâu hơn mức này thì không nhắc bù phần cũ hơn nữa.
	maxCatchUp = 24 * time.Hour
	// lateGrace: nhắc bù khi hoạt động đã bắt đầu quá mức này thì chỉ ghi vào danh sách
	// thông báo, không gửi thông báo đẩy nữa (đẩy "sắp tới giờ" lúc đã qua giờ thì vô nghĩa).
	lateGrace = 5 * time.Minute
	// workerStateID là _id của bản ghi lưu mốc quét cuối trong worker_state.
	workerStateID = "reminder"
)

// ReminderWorker quét lịch cá nhân và lịch nhóm đúng giây :00 mỗi phút, đến mốc
// "nhắc trước X phút" thì tạo thông báo loại reminder và gửi FCM.
//
// Mốc quét cuối được lưu ở collection worker_state, nên server tắt rồi bật lại (trong vòng
// maxCatchUp) vẫn nhắc bù: thông báo luôn có trong danh sách, chỉ không đẩy FCM nếu
// hoạt động đã bắt đầu. Mỗi lần nhắc được ghi vào
// reminder_logs với khoá duy nhất, nên quét chồng lên nhau hay chạy nhiều server cũng
// không gửi trùng.
type ReminderWorker struct {
	store    *repository.Store
	notifier *NotificationService
	last     time.Time
}

// NewReminderWorker tạo bộ nhắc lịch.
func NewReminderWorker(store *repository.Store, n *NotificationService) *ReminderWorker {
	return &ReminderWorker{store: store, notifier: n}
}

func (w *ReminderWorker) stateColl() *mongo.Collection {
	return w.store.DB.Collection(models.CollWorkerState)
}

func (w *ReminderWorker) logColl() *mongo.Collection {
	return w.store.DB.Collection(models.CollReminderLogs)
}

// loadCursor đọc mốc quét cuối đã lưu, không có hoặc quá cũ thì lấy giới hạn nhắc bù.
func (w *ReminderWorker) loadCursor(ctx context.Context, now time.Time) time.Time {
	floor := now.Add(-maxCatchUp)
	var st struct {
		Last time.Time `bson:"last"`
	}
	if err := w.stateColl().FindOne(ctx, bson.M{"_id": workerStateID}).Decode(&st); err != nil {
		// Chưa có mốc (lần đầu chạy bản này): quét lùi hết khoảng nhắc bù,
		// những lần đã nhắc từ trước được alreadyNotified chặn lại
		return floor
	}
	if st.Last.Before(floor) {
		return floor
	}
	if st.Last.After(now) {
		return now
	}
	return st.Last.UTC()
}

func (w *ReminderWorker) saveCursor(ctx context.Context, t time.Time) {
	_, err := w.stateColl().UpdateOne(ctx, bson.M{"_id": workerStateID},
		bson.M{"$set": bson.M{"last": t}}, options.UpdateOne().SetUpsert(true))
	if err != nil {
		log.Printf("lưu mốc quét nhắc lịch lỗi: %v", err)
	}
}

// Start chạy vòng quét ở goroutine riêng cho tới khi server tắt.
// Lần quét đầu nhắc bù từ mốc đã lưu, sau đó canh đúng đầu mỗi phút (hh:mm:00).
func (w *ReminderWorker) Start(ctx context.Context) {
	now := time.Now().UTC()
	initCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	w.last = w.loadCursor(initCtx, now)
	cancel()
	go func() {
		w.tick(ctx, time.Now().UTC())
		for {
			// Ngủ tới đúng đầu phút kế tiếp, tránh trễ tới 59 giây như ticker thường
			next := time.Now().Truncate(time.Minute).Add(time.Minute)
			timer := time.NewTimer(time.Until(next))
			select {
			case <-ctx.Done():
				timer.Stop()
				return
			case t := <-timer.C:
				w.tick(ctx, t.UTC())
			}
		}
	}()
	log.Println("đã bật bộ nhắc lịch, quét đầu mỗi phút")
}

// tick là một lần quét: tìm lịch cá nhân và lịch nhóm có mốc nhắc trong (last, now].
func (w *ReminderWorker) tick(ctx context.Context, now time.Time) {
	if !now.After(w.last) {
		return
	}
	from := w.last
	ctx, cancel := context.WithTimeout(ctx, 50*time.Second)
	defer cancel()
	okP := w.personal(ctx, from, now)
	if okP != nil {
		log.Printf("nhắc lịch cá nhân lỗi: %v", okP)
	}
	okG := w.group(ctx, from, now)
	if okG != nil {
		log.Printf("nhắc lịch nhóm lỗi: %v", okG)
	}
	// Lỗi (VD mất kết nối DB) thì giữ mốc cũ để lần sau quét lại, đã nhắc rồi thì reminder_logs chặn trùng
	if okP == nil && okG == nil {
		w.last = now
		w.saveCursor(ctx, now)
	}
}

// due kiểm tra mốc nhắc có rơi vào khoảng (from, now] hay không.
// late = true khi đây là nhắc bù mà hoạt động đã bắt đầu quá lateGrace (server tắt lúc tới giờ nhắc).
func due(start time.Time, remind int, from, now time.Time) (at time.Time, ok, late bool) {
	at = start.Add(-time.Duration(remind) * time.Minute)
	ok = at.After(from) && !at.After(now)
	late = !now.Before(start.Add(lateGrace))
	return at, ok, late
}

// alreadyNotified: người này đã có thông báo nhắc cho lịch này từ mốc nhắc trở về sau chưa
// (chặn trùng với những lần nhắc tạo ra trước khi có reminder_logs).
func (w *ReminderWorker) alreadyNotified(ctx context.Context, refID, userID string, at time.Time) bool {
	n, err := w.store.Notifications.CountDocuments(ctx, bson.M{
		"user_id": userID, "reference_id": refID, "type": models.NotiReminder,
		"created_at": bson.M{"$gte": at.Add(-time.Minute)},
	})
	return err == nil && n > 0
}

// claim ghi lại lần nhắc (khoá = lịch + người nhận + mốc nhắc). Trả false nếu đã nhắc rồi.
// Đổi giờ của lịch thì mốc nhắc đổi theo, nên vẫn được nhắc lại theo giờ mới.
func (w *ReminderWorker) claim(ctx context.Context, refID, userID string, at time.Time) bool {
	if w.alreadyNotified(ctx, refID, userID, at) {
		return false
	}
	key := fmt.Sprintf("%s|%s|%d", refID, userID, at.Unix())
	_, err := w.logColl().InsertOne(ctx, bson.M{"_id": key, "created_at": time.Now().UTC()})
	if err == nil {
		return true
	}
	if !repository.IsDuplicateKey(err) {
		log.Printf("ghi reminder_logs lỗi: %v", err)
		// Không ghi được thì vẫn nhắc, thà trùng còn hơn bỏ sót
		return true
	}
	return false
}

// personal gửi nhắc cho lịch cá nhân, giờ tính theo múi giờ của từng người.
func (w *ReminderWorker) personal(ctx context.Context, from, now time.Time) error {
	// Mọi múi giờ đều nằm trong khoảng hôm qua tới ngày mai so với UTC
	list, err := repository.FindMany[models.Timeblock](ctx, w.store.Timeblocks, bson.M{"date": bson.M{
		"$gte": from.AddDate(0, 0, -1).Format(utils.DateLayout), "$lte": now.AddDate(0, 0, 2).Format(utils.DateLayout),
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
		at, ok, late := due(start, t.Remind, from, now)
		if !ok || !w.claim(ctx, t.ID, t.UserID, at) {
			continue
		}
		log.Printf("nhắc lịch cá nhân %q của %s: bắt đầu %s (múi giờ %s), nhắc bù muộn=%v",
			t.Task, u.NickName, start.Format("2006-01-02 15:04 -07:00"), loc, late)
		w.notifier.Notify(ctx, NotifyInput{
			Recipients: []string{t.UserID}, Kind: models.KindPersonalReminder, Type: models.NotiReminder,
			Args: map[string]string{
				"task": t.Task, "time": start.Format("15:04"), "date": t.Date,
				"start_at": start.UTC().Format(time.RFC3339),
			},
			ReferenceID: utils.Ptr(t.ID), ReferenceType: utils.Ptr(models.RefTimeblock),
			SkipPush: late, At: utils.Ptr(at),
		})
	}
	return nil
}

// group gửi nhắc cho hoạt động nhóm, bỏ qua người đã từ chối tham gia.
func (w *ReminderWorker) group(ctx context.Context, from, now time.Time) error {
	list, err := repository.FindMany[models.TribeBlock](ctx, w.store.TribeBlocks, bson.M{"date": bson.M{
		"$gte": from.AddDate(0, 0, -1).Format(utils.DateLayout), "$lte": now.AddDate(0, 0, 1).Format(utils.DateLayout),
	}})
	if err != nil {
		return err
	}
	for _, b := range list {
		r := utils.UTCRange(b.Date, b.StartTime, b.EndTime)
		at, ok, late := due(r.Start, b.Remind, from, now)
		if !ok {
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
			if !w.claim(ctx, b.ID, uid, at) {
				continue
			}
			loc := utils.LoadLocation(profiles[uid].Timezone)
			log.Printf("nhắc hoạt động nhóm %q cho %s: bắt đầu %s (múi giờ %s), nhắc bù muộn=%v",
				b.Task, profiles[uid].NickName, r.Start.In(loc).Format("2006-01-02 15:04 -07:00"), loc, late)
			w.notifier.Notify(ctx, NotifyInput{
				Recipients: []string{uid}, Kind: models.KindTribeReminder, Type: models.NotiReminder,
				Args: map[string]string{
					"task": b.Task, "tribe": tribe.Name, "tribe_id": tribe.ID, "time": r.Start.In(loc).Format("15:04"),
					// App đổi mốc UTC này ra giờ của máy, không phụ thuộc múi giờ lưu trên server
					"start_at": r.Start.UTC().Format(time.RFC3339),
				},
				ReferenceID: utils.Ptr(b.ID), ReferenceType: utils.Ptr(models.RefTribeBlock),
				SkipPush: late, At: utils.Ptr(at),
			})
		}
	}
	return nil
}
