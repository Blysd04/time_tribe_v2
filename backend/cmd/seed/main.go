// Lệnh seed xoá sạch 11 collection rồi nạp dữ liệu mẫu để test.
// Dữ liệu lấy theo dữ liệu giả lập trong front-end (tribe_mock_data.dart, template_viewmodel.dart...),
// ngày giờ tính tương đối so với lúc chạy để lúc nào test cũng có lịch hôm nay, ngày mai.
// ID sinh cố định theo tên (UUID v5) nên chạy lại bao nhiêu lần ID cũng không đổi.
//
// Chạy: go run ./cmd/seed
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	_ "time/tzdata"

	"timetribe-backend/internal/config"
	"timetribe-backend/internal/database"
	"timetribe-backend/internal/models"
	"timetribe-backend/internal/repository"
	"timetribe-backend/internal/utils"
)

const seedPassword = "123456"

var ns = uuid.MustParse("6f1c2a3e-5b7d-4e8f-9a0b-1c2d3e4f5a6b")

func id(kind, key string) string { return uuid.NewSHA1(ns, []byte(kind+":"+key)).String() }

type seedUser struct {
	key, nick, email, tz, role, provider string
	banned                               bool
}

var users = []seedUser{
	{"admin", "admin", "admin@timetribe.com", "Asia/Ho_Chi_Minh", models.RoleAdmin, models.ProviderLocal, false},
	{"nga", "Tuyết Nga", "tuyetnga@timetribe.app", "Asia/Ho_Chi_Minh", models.RoleCustomer, models.ProviderLocal, false},
	{"minh", "Minh Trần", "minh.tran@timetribe.app", "Asia/Ho_Chi_Minh", models.RoleCustomer, models.ProviderLocal, false},
	{"linh", "Linh Phạm", "linh.pham@timetribe.app", "Asia/Ho_Chi_Minh", models.RoleCustomer, models.ProviderLocal, false},
	{"hana", "Hana Sato", "hana.sato@timetribe.app", "Asia/Tokyo", models.RoleCustomer, models.ProviderLocal, false},
	{"david", "David Nguyen", "david.nguyen@timetribe.app", "America/Vancouver", models.RoleCustomer, models.ProviderLocal, false},
	{"an", "An Lê", "an.le@timetribe.app", "Asia/Ho_Chi_Minh", models.RoleCustomer, models.ProviderLocal, false},
	{"khoa", "Khoa Đỗ", "khoa.do@timetribe.app", "Europe/London", models.RoleCustomer, models.ProviderLocal, false},
	{"mai", "Mai Võ", "mai.vo@timetribe.app", "Asia/Ho_Chi_Minh", models.RoleCustomer, models.ProviderLocal, false},
	{"tuan", "Tuấn Hồ", "tuan.ho@timetribe.app", "Asia/Ho_Chi_Minh", models.RoleCustomer, models.ProviderLocal, false},
	{"vy", "Vy Ngô", "vy.ngo@timetribe.app", "Australia/Sydney", models.RoleCustomer, models.ProviderLocal, false},
	{"phuc", "Phúc Lâm", "phuc.lam@timetribe.app", "Asia/Ho_Chi_Minh", models.RoleCustomer, models.ProviderLocal, false},
	{"ngoc", "Bảo Ngọc", "baongoc.gg@gmail.com", "Asia/Ho_Chi_Minh", models.RoleCustomer, models.ProviderGoogle, false},
	{"spam", "spam.bot", "spam.bot@timetribe.app", "Asia/Ho_Chi_Minh", models.RoleCustomer, models.ProviderLocal, true},
}

// Lịch cá nhân lặp theo thứ (1 = thứ Hai), theo giờ địa phương của từng người.
type slot struct {
	task       string
	start, end string
	color      string
}

var weekly = map[string]map[int][]slot{
	"minh": {
		1: {{"Làm việc ở công ty", "08:00", "12:00", "#3A86FF"}, {"Làm việc ở công ty", "13:30", "17:30", "#3A86FF"}},
		2: {{"Làm việc ở công ty", "08:00", "12:00", "#3A86FF"}, {"Làm việc ở công ty", "13:30", "17:30", "#3A86FF"}},
		3: {{"Làm việc ở công ty", "08:00", "12:00", "#3A86FF"}, {"Làm việc ở công ty", "13:30", "17:30", "#3A86FF"}},
		4: {{"Làm việc ở công ty", "08:00", "12:00", "#3A86FF"}, {"Làm việc ở công ty", "13:30", "17:30", "#3A86FF"}},
		5: {{"Làm việc ở công ty", "08:00", "12:00", "#3A86FF"}, {"Họp tổng kết tuần", "13:30", "16:00", "#9B5DE5"}},
		6: {{"Đá bóng với bạn", "09:00", "11:00", "#00B894"}},
	},
	"linh": {
		1: {{"Học trên trường", "07:30", "11:30", "#FFB703"}, {"Làm đồ án", "14:00", "18:00", "#FF7F50"}},
		2: {{"Học trên trường", "07:30", "11:30", "#FFB703"}, {"Dạy kèm Tiếng Anh", "19:00", "21:00", "#00B894"}},
		3: {{"Học trên trường", "07:30", "11:30", "#FFB703"}, {"Làm đồ án", "14:00", "18:00", "#FF7F50"}},
		4: {{"Học trên trường", "07:30", "11:30", "#FFB703"}, {"Dạy kèm Tiếng Anh", "19:00", "21:00", "#00B894"}},
		5: {{"Học trên trường", "07:30", "11:30", "#FFB703"}, {"Làm đồ án", "14:00", "17:00", "#FF7F50"}},
	},
	"hana": {
		1: {{"Work at office", "09:00", "18:00", "#0FA3B1"}}, 2: {{"Work at office", "09:00", "18:00", "#0FA3B1"}},
		3: {{"Work at office", "09:00", "18:00", "#0FA3B1"}}, 4: {{"Work at office", "09:00", "18:00", "#0FA3B1"}},
		5: {{"Work at office", "09:00", "17:00", "#0FA3B1"}}, 6: {{"Japanese tea class", "10:00", "12:00", "#FF007F"}},
	},
	"david": {
		1: {{"Ca làm ở cửa hàng", "09:00", "17:00", "#6C757D"}}, 2: {{"Ca làm ở cửa hàng", "09:00", "17:00", "#6C757D"}},
		3: {{"Ca làm ở cửa hàng", "09:00", "17:00", "#6C757D"}},
		5: {{"Ca làm ở cửa hàng", "09:00", "12:00", "#6C757D"}, {"Học tiếng Pháp", "18:00", "21:00", "#9B5DE5"}},
		6: {{"Học tiếng Pháp", "18:00", "21:00", "#9B5DE5"}},
	},
	"nga": {
		1: {{"Học UI/UX", "08:00", "11:30", "#3A86FF"}},
		2: {{"Tập Gym", "17:30", "19:00", "#FF007F"}},
		3: {{"Làm part-time", "13:00", "17:00", "#FFB703"}},
		4: {{"Tập Gym", "17:30", "19:00", "#FF007F"}},
		5: {{"Học UI/UX", "08:00", "11:30", "#3A86FF"}, {"Đi siêu thị", "18:00", "19:00", "#00B894"}},
		6: {{"Cà phê với bạn", "09:00", "10:30", "#9B5DE5"}},
	},
}

func main() {
	cfg := config.Load()
	client, db, err := database.Connect(cfg.MongoURI, cfg.DBName)
	if err != nil {
		log.Fatal(err)
	}
	defer client.Disconnect(context.Background())
	ctx := context.Background()

	for _, c := range []string{
		models.CollUsers, models.CollUserSecurities, models.CollUserTokens, models.CollTimeblocks,
		models.CollTemplates, models.CollTemplateBlocks, models.CollTribes, models.CollTribeAttendees,
		models.CollTribeBlocks, models.CollTribeBlockAttendance, models.CollNotifications,
	} {
		if err := db.Collection(c).Drop(ctx); err != nil {
			log.Fatal(err)
		}
	}
	if err := database.EnsureIndexes(db); err != nil {
		log.Fatal(err)
	}
	s := repository.NewStore(db)
	now := time.Now().UTC()

	// ---------------- users + user_securities ----------------
	hash, _ := bcrypt.GenerateFromPassword([]byte(seedPassword), bcrypt.DefaultCost)
	tz := map[string]string{}
	for i, u := range users {
		tz[u.key] = u.tz
		created := now.AddDate(0, 0, -30+i) // ngày tạo tài khoản rải trong tháng trước
		must(s.Users.InsertOne(ctx, models.User{
			ID: id("user", u.key), Email: u.email, NickName: u.nick, Timezone: u.tz, CreatedAt: created, UpdatedAt: created,
		}))
		sec := models.UserSecurity{UserID: id("user", u.key), Role: u.role, AuthProvider: u.provider, IsBanned: u.banned}
		if u.provider == models.ProviderLocal {
			sec.PasswordHash = utils.Ptr(string(hash))
			sec.PasswordChangedAt = &created
		} else {
			sec.GoogleID = utils.Ptr("104857392018475920384")
		}
		if u.banned {
			sec.BanReason = utils.Ptr("Gửi lời mời nhóm hàng loạt, có dấu hiệu spam")
		}
		must(s.UserSecurities.InsertOne(ctx, sec))
	}

	// ---------------- timeblocks: 7 ngày trước tới 14 ngày sau ----------------
	tbCount := 0
	for key, pattern := range weekly {
		loc := utils.LoadLocation(tz[key])
		today := time.Now().In(loc)
		for d := -7; d <= 14; d++ {
			day := time.Date(today.Year(), today.Month(), today.Day()+d, 0, 0, 0, 0, loc)
			wd := int(day.Weekday())
			if wd == 0 {
				wd = 7
			}
			for i, sl := range pattern[wd] {
				date := day.Format(utils.DateLayout)
				must(s.Timeblocks.InsertOne(ctx, models.Timeblock{
					ID: id("timeblock", fmt.Sprintf("%s-%s-%d", key, date, i)), UserID: id("user", key), Task: sl.task,
					Date: date, StartTime: sl.start + ":00", EndTime: sl.end + ":00", ColorCode: sl.color,
					Remind: 15, CreatedAt: now.AddDate(0, 0, -8),
				}))
				tbCount++
			}
		}
	}
	// Một lịch có nhân bản sang ngày khác để xem cột repeating_dates
	ngaLoc := utils.LoadLocation(tz["nga"])
	ngaToday := utils.TodayIn(ngaLoc)
	copies := []string{utils.AddDays(ngaToday, 3), utils.AddDays(ngaToday, 10)}
	must(s.Timeblocks.InsertOne(ctx, models.Timeblock{
		ID: id("timeblock", "nga-reading"), UserID: id("user", "nga"), Task: "Đọc sách 30 phút",
		Description: utils.Ptr("Đang đọc Atomic Habits"), Date: ngaToday, StartTime: "21:30:00", EndTime: "22:00:00",
		ColorCode: "#0FA3B1", RepeatingDates: copies, Remind: 5, CreatedAt: now,
	}))
	for i, d := range copies {
		must(s.Timeblocks.InsertOne(ctx, models.Timeblock{
			ID: id("timeblock", fmt.Sprintf("nga-reading-copy-%d", i)), UserID: id("user", "nga"), Task: "Đọc sách 30 phút",
			Description: utils.Ptr("Đang đọc Atomic Habits"), Date: d, StartTime: "21:30:00", EndTime: "22:00:00",
			ColorCode: "#0FA3B1", Remind: 5, CreatedAt: now,
		}))
	}
	tbCount += 3

	// ---------------- templates + template_blocks ----------------
	type tb struct {
		day                    int
		title, start, end, col string
		desc                   string
	}
	addTemplate := func(key, owner, name string, share *string, original *string, blocks []tb) {
		tid := id("template", key)
		must(s.Templates.InsertOne(ctx, models.Template{
			ID: tid, UserID: id("user", owner), OriginalTemplateID: original, TemplateName: name, ShareToken: share,
			DateModified: now.AddDate(0, 0, -2), CreatedAt: now.AddDate(0, 0, -5),
		}))
		for i, b := range blocks {
			must(s.TemplateBlocks.InsertOne(ctx, models.TemplateBlock{
				ID: id("template_block", fmt.Sprintf("%s-%d", key, i)), TemplateID: tid, DayIndex: b.day, Title: b.title,
				Description: utils.TrimPtr(&b.desc), StartTime: b.start + ":00", EndTime: b.end + ":00", ColorCode: b.col, Remind: 15,
			}))
		}
	}
	addTemplate("nga-nic", "nga", "Tuần học NIC & Đi làm", nil, nil, []tb{
		{1, "Học UI/UX", "08:00", "11:30", "#3A86FF", "Phòng Lab 3"},
		{3, "Làm part-time", "13:00", "17:00", "#FFB703", ""},
		{5, "Học UI/UX", "08:00", "11:30", "#3A86FF", "Phòng Lab 3"},
	})
	addTemplate("nga-gym", "nga", "Quy trình tập Gym 4 ngày", utils.Ptr("gym4day"), nil, []tb{
		{1, "Push Day", "17:30", "19:00", "#FF007F", "Ngực, Vai, Tay sau"},
		{2, "Pull Day", "17:30", "19:00", "#9B5DE5", "Lưng, Tay trước"},
		{4, "Leg Day", "17:30", "19:00", "#00B894", "Đùi, Mông, Bắp chân"},
		{6, "Cardio nhẹ", "07:00", "08:00", "#0FA3B1", "Chạy bộ công viên"},
	})
	addTemplate("linh-exam", "linh", "Tuần ôn thi cuối kỳ", utils.Ptr("study-week"), nil, []tb{
		{1, "Ôn Toán", "19:00", "21:00", "#3A86FF", ""},
		{3, "Ôn Tiếng Anh", "19:00", "21:00", "#00F5D4", ""},
		{5, "Làm đề thi thử", "19:00", "21:30", "#FF7F50", "Bấm giờ như thi thật"},
	})
	// Minh đã nhập mẫu Gym của Nga trước đó
	addTemplate("minh-gym", "minh", "Quy trình tập Gym 4 ngày", nil, utils.Ptr(id("template", "nga-gym")), []tb{
		{1, "Push Day", "17:30", "19:00", "#FF007F", "Ngực, Vai, Tay sau"},
		{2, "Pull Day", "17:30", "19:00", "#9B5DE5", "Lưng, Tay trước"},
	})

	// ---------------- tribes + tribe_attendees ----------------
	type member struct{ key, role string }
	addTribe := func(key, name, owner, code, color string, created time.Time, members []member) {
		must(s.Tribes.InsertOne(ctx, models.Tribe{
			ID: id("tribe", key), Name: name, CreatedBy: id("user", owner), InviteLink: code,
			BackgroundColor: utils.Ptr(color), CreatedAt: created,
		}))
		for i, m := range members {
			must(s.TribeAttendees.InsertOne(ctx, models.TribeAttendee{
				ID: id("attendee", key+"-"+m.key), TribeID: id("tribe", key), UserID: id("user", m.key),
				Role: m.role, JoinedAt: created.Add(time.Duration(i) * time.Hour),
			}))
		}
	}
	L, V, M := models.TribeRoleLeader, models.TribeRoleViceLeader, models.TribeRoleMember
	addTribe("nic", "Đồ án NIC", "nga", "NIC2026", "#3A86FF", now.AddDate(0, 0, -20), []member{
		{"nga", L}, {"minh", V}, {"linh", M}, {"hana", M}, {"david", M}, {"an", M},
	})
	addTribe("badminton", "CLB Cầu lông Q7", "mai", "CAULONGQ7", "#00B894", now.AddDate(0, 0, -18), []member{
		{"mai", L}, {"minh", V}, {"nga", M}, {"an", M},
	})
	addTribe("marketing", "Team Marketing Global", "linh", "MKTGLOBAL", "#9B5DE5", now.AddDate(0, 0, -15), []member{
		{"linh", L}, {"nga", V}, {"hana", V}, {"david", M}, {"khoa", M}, {"an", M}, {"mai", M}, {"minh", M},
	})
	addTribe("gamedev", "Hội Game Dev", "tuan", "GAMEDEV26", "#FF7F50", now.AddDate(0, 0, -10), []member{
		{"tuan", L}, {"vy", V}, {"khoa", M},
	})
	addTribe("full", "Nhóm đã đủ người", "tuan", "FULLHOUSE", "#6C757D", now.AddDate(0, 0, -9), []member{
		{"tuan", L}, {"vy", M}, {"khoa", M}, {"mai", M}, {"an", M}, {"minh", M}, {"linh", M}, {"hana", M}, {"david", M}, {"phuc", M},
	})

	// ---------------- tribe_blocks + tribe_block_attendance ----------------
	// Giờ viết theo giờ Việt Nam cho dễ hình dung, lưu xuống thì đổi ra UTC
	vnLoc := utils.LoadLocation("Asia/Ho_Chi_Minh")
	vnToday := utils.TodayIn(vnLoc)
	A, D, P := models.AttendanceAccepted, models.AttendanceDeclined, models.AttendancePending
	addBlock := func(key, tribe, creator, task, desc string, dayOffset int, start, end, color string, att map[string]string) {
		date := utils.AddDays(vnToday, dayOffset)
		st := utils.At(date, start+":00", vnLoc).UTC()
		en := utils.At(date, end+":00", vnLoc).UTC()
		bid := id("tribe_block", key)
		must(s.TribeBlocks.InsertOne(ctx, models.TribeBlock{
			ID: bid, TribeID: id("tribe", tribe), CreatedBy: id("user", creator), Task: task, Description: utils.TrimPtr(&desc),
			Date: st.Format(utils.DateLayout), StartTime: st.Format(utils.ClockLayout), EndTime: en.Format(utils.ClockLayout),
			ColorCode: color, Remind: models.TribeBlockRemind, CreatedAt: now.Add(-3 * time.Hour),
		}))
		for u, status := range att {
			must(s.TribeBlockAttendance.InsertOne(ctx, models.TribeBlockAttendance{
				ID: id("attendance", key+"-"+u), TribeBlockID: bid, UserID: id("user", u), Status: status, UpdatedAt: now.Add(-time.Hour),
			}))
		}
	}
	addBlock("nic-1", "nic", "nga", "Họp chốt tiến độ", "Mọi người cập nhật phần việc của mình trước buổi họp nhé.", 0, "20:00", "21:00", "#3A86FF",
		map[string]string{"nga": A, "minh": A, "linh": A, "hana": P, "david": D, "an": P})
	addBlock("nic-2", "nic", "minh", "Code review sprint 3", "", 2, "21:00", "22:30", "#FFB703",
		map[string]string{"nga": A, "minh": A, "linh": P, "hana": A, "david": P, "an": P})
	addBlock("nic-3", "nic", "nga", "Demo với giảng viên", "Chuẩn bị slide và bản build APK", 5, "09:00", "10:30", "#3A86FF",
		map[string]string{"nga": A, "minh": P, "linh": P, "hana": P, "david": P, "an": P})
	addBlock("bad-1", "badminton", "mai", "Đánh cầu tối", "Sân Phú Mỹ, nhớ mang vợt nha.", 1, "18:30", "20:30", "#00B894",
		map[string]string{"mai": A, "minh": A, "nga": P, "an": D})
	addBlock("mkt-1", "marketing", "linh", "Họp tuần Marketing", "", 0, "15:00", "16:00", "#9B5DE5",
		map[string]string{"linh": A, "nga": A, "hana": A, "david": P, "khoa": A, "an": P, "mai": D, "minh": A})
	addBlock("mkt-2", "marketing", "linh", "Lên kế hoạch chiến dịch Tết", "Mỗi người mang 3 ý tưởng", 3, "16:00", "17:30", "#9B5DE5",
		map[string]string{"linh": A, "nga": P, "hana": P, "david": P, "khoa": P, "an": P, "mai": P, "minh": P})
	addBlock("game-1", "gamedev", "tuan", "Game jam cuối tuần", "", 4, "19:00", "22:00", "#FF7F50",
		map[string]string{"tuan": A, "vy": A, "khoa": P})

	// ---------------- notifications ----------------
	addNoti := func(key, to string, from *string, kind, typ string, args map[string]string, refID, refType *string, ago time.Duration, read bool) {
		content, _ := json.Marshal(args)
		var uid *string
		if to != "" {
			uid = utils.Ptr(id("user", to))
		}
		must(s.Notifications.InsertOne(ctx, models.Notification{
			ID: id("notification", key), UserID: uid, CreatedBy: from, Title: kind, Content: string(content), Type: typ,
			ReferenceID: refID, ReferenceType: refType, IsRead: read, CreatedAt: now.Add(-ago),
		}))
	}
	u := func(k string) *string { return utils.Ptr(id("user", k)) }
	ref := func(kind, k string) *string { return utils.Ptr(id(kind, k)) }
	addNoti("n1", "nga", u("mai"), models.KindTribeNewBlock, models.NotiGroupSchedule,
		map[string]string{"actor": "Mai Võ", "tribe": "CLB Cầu lông Q7", "tribe_id": id("tribe", "badminton"), "task": "Đánh cầu tối"},
		ref("tribe_block", "bad-1"), utils.Ptr(models.RefTribeBlock), 3*time.Hour, false)
	addNoti("n2", "nga", u("linh"), models.KindTribeNewBlock, models.NotiGroupSchedule,
		map[string]string{"actor": "Linh Phạm", "tribe": "Team Marketing Global", "tribe_id": id("tribe", "marketing"), "task": "Lên kế hoạch chiến dịch Tết"},
		ref("tribe_block", "mkt-2"), utils.Ptr(models.RefTribeBlock), 2*time.Hour, false)
	addNoti("n3", "nga", u("linh"), models.KindTribeRoleVice, models.NotiTribeRole,
		map[string]string{"actor": "Linh Phạm", "tribe": "Team Marketing Global", "tribe_id": id("tribe", "marketing")},
		ref("tribe", "marketing"), utils.Ptr(models.RefTribe), 48*time.Hour, false)
	addNoti("n4", "nga", u("an"), models.KindTribeMemberJoined, models.NotiTribeJoin,
		map[string]string{"actor": "An Lê", "tribe": "Đồ án NIC", "tribe_id": id("tribe", "nic")},
		ref("tribe", "nic"), utils.Ptr(models.RefTribe), 72*time.Hour, true)
	addNoti("n5", "nga", u("david"), models.KindTribeResponseDeclined, models.NotiGroupSchedule,
		map[string]string{"actor": "David Nguyen", "tribe": "Đồ án NIC", "tribe_id": id("tribe", "nic"), "task": "Họp chốt tiến độ"},
		ref("tribe_block", "nic-1"), utils.Ptr(models.RefTribeBlockResponse), 90*time.Minute, false)
	addNoti("n6", "nga", nil, models.KindPersonalReminder, models.NotiReminder,
		map[string]string{"task": "Tập Gym", "time": "17:30"}, nil, nil, 26*time.Hour, true)
	addNoti("n7", "nga", nil, models.KindPersonalBlockAdded, models.NotiReminder,
		map[string]string{"task": "Họp lớp", "time": "09:00"}, nil, nil, 45*24*time.Hour, true) // quá 30 ngày, không hiện
	addNoti("n8", "minh", u("nga"), models.KindTribeNewBlock, models.NotiGroupSchedule,
		map[string]string{"actor": "Tuyết Nga", "tribe": "Đồ án NIC", "tribe_id": id("tribe", "nic"), "task": "Demo với giảng viên"},
		ref("tribe_block", "nic-3"), utils.Ptr(models.RefTribeBlock), time.Hour, false)
	must(s.Notifications.InsertOne(ctx, models.Notification{
		ID: id("notification", "broadcast-1"), UserID: nil, CreatedBy: u("admin"), Title: "Chào mừng bạn đến với TimeTribe v2",
		Content: "Phiên bản mới hỗ trợ lịch nhóm nhiều múi giờ và lịch mẫu chia sẻ. Cảm ơn bạn đã đồng hành.",
		Type:    models.NotiSystemBroadcast, CreatedAt: now.Add(-24 * time.Hour),
	}))

	fmt.Println("Đã seed xong database", cfg.DBName)
	fmt.Printf("  %d users, %d timeblocks, 4 templates, 5 tribes, 7 tribe_blocks, 9 notifications\n\n", len(users), tbCount)
	fmt.Println("Tài khoản (mật khẩu chung: " + seedPassword + ", trừ tài khoản Google):")
	for _, u := range users {
		note := ""
		if u.banned {
			note = "  (bị khoá)"
		}
		if u.provider == models.ProviderGoogle {
			note = "  (tài khoản Google, không có mật khẩu)"
		}
		fmt.Printf("  %-12s %-28s %s%s\n", u.nick, u.email, id("user", u.key), note)
	}
	fmt.Println("\nNhóm:")
	for _, t := range [][2]string{{"nic", "NIC2026"}, {"badminton", "CAULONGQ7"}, {"marketing", "MKTGLOBAL"}, {"gamedev", "GAMEDEV26"}, {"full", "FULLHOUSE"}} {
		fmt.Printf("  %-10s mã mời %-10s %s\n", t[0], t[1], id("tribe", t[0]))
	}
	fmt.Println("\nHoạt động nhóm:")
	for _, k := range []string{"nic-1", "nic-2", "nic-3", "bad-1", "mkt-1", "mkt-2", "game-1"} {
		fmt.Printf("  %-8s %s\n", k, id("tribe_block", k))
	}
	fmt.Println("\nLịch mẫu:")
	for _, k := range []string{"nga-nic", "nga-gym", "linh-exam", "minh-gym"} {
		fmt.Printf("  %-10s %s\n", k, id("template", k))
	}
}

func must[T any](v T, err error) T {
	if err != nil {
		log.Fatal(err)
	}
	return v
}
