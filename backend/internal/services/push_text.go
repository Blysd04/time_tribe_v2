package services

import (
	"fmt"

	"timetribe-backend/internal/models"
)

// PushText dựng tiêu đề và nội dung tiếng Việt cho thông báo đẩy (hiện trên khay hệ thống).
// Trong app, danh sách thông báo vẫn tự dịch lại theo ngôn ngữ đang chọn dựa vào kind + args.
// Câu chữ chép theo lib/l10n/app_vi.arb để hai bên giống nhau.
func PushText(kind string, a map[string]string) (string, string) {
	actor, tribe, task := a["actor"], a["tribe"], a["task"]
	switch kind {
	case models.KindTribeNewBlock:
		return "Hoạt động mới: " + task, fmt.Sprintf("%s vừa thêm hoạt động vào %s. Bạn có tham gia không?", actor, tribe)
	case models.KindTribeBlockUpdated:
		return "Đã cập nhật: " + task, actor + " đã cập nhật thông tin hoạt động."
	case models.KindTribeBlockRescheduled:
		return "Đổi giờ: " + task, actor + " đã đổi giờ, cần xác nhận lại."
	case models.KindTribeBlockCancelled:
		return "Hoạt động đã bị huỷ", fmt.Sprintf("%s đã huỷ \"%s\" của nhóm %s.", actor, task, tribe)
	case models.KindTribeResponseAccepted:
		return "Có người tham gia", fmt.Sprintf("%s sẽ tham gia \"%s\".", actor, task)
	case models.KindTribeResponseDeclined:
		return "Có người không tham gia", fmt.Sprintf("%s không tham gia \"%s\".", actor, task)
	case models.KindTribeMemberJoined:
		return "Thành viên mới", fmt.Sprintf("%s vừa tham gia %s.", actor, tribe)
	case models.KindTribeMemberLeft:
		return "Thành viên rời nhóm", fmt.Sprintf("%s không còn ở trong %s.", actor, tribe)
	case models.KindTribeKickedYou:
		return "Bạn đã được mời rời nhóm", fmt.Sprintf("%s đã mời bạn rời nhóm %s.", actor, tribe)
	case models.KindTribeRenamed:
		return "Nhóm đã đổi tên", fmt.Sprintf("%s đã đổi tên nhóm \"%s\" thành \"%s\".", actor, a["old"], a["new"])
	case models.KindTribeDissolved:
		return "Nhóm đã giải tán", fmt.Sprintf("%s đã giải tán nhóm %s.", actor, tribe)
	case models.KindTribeRoleVice:
		return "Thay đổi chức vụ", "Bạn đã được bổ nhiệm làm phó nhóm " + tribe + "."
	case models.KindTribeRoleViceRemoved:
		return "Thay đổi chức vụ", "Bạn không còn là phó nhóm " + tribe + "."
	case models.KindTribeRoleLeader:
		return "Thay đổi chức vụ", "Bạn đã được bổ nhiệm làm trưởng nhóm " + tribe + "."
	case models.KindPersonalBlockAdded:
		return "Lịch cá nhân mới", fmt.Sprintf("Bạn đã thêm \"%s\" lúc %s.", task, a["time"])
	case models.KindPersonalReminder:
		return "Sắp tới giờ: " + task, fmt.Sprintf("\"%s\" bắt đầu lúc %s.", task, a["time"])
	case models.KindTribeReminder:
		return "Sắp tới giờ: " + task, fmt.Sprintf("Hoạt động của nhóm %s bắt đầu lúc %s.", tribe, a["time"])
	}
	return "TimeTribe", "Bạn có thông báo mới"
}
