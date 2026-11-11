package services

import (
	"strings"

	"timetribe-backend/internal/models"
)

// Ngôn ngữ app hỗ trợ, khớp với LocaleProvider ở front-end.
const (
	LangVI = "vi"
	LangEN = "en"
	LangFR = "fr"
)

// NormalizeLang trả mã ngôn ngữ hợp lệ, không nhận ra thì dùng tiếng Việt.
func NormalizeLang(lang string) string {
	switch strings.ToLower(strings.TrimSpace(lang)) {
	case LangEN:
		return LangEN
	case LangFR:
		return LangFR
	}
	return LangVI
}

// pushTemplates: tiêu đề và nội dung thông báo đẩy theo ngôn ngữ, chép theo lib/l10n/app_*.arb
// để thông báo trên khay hệ thống giống hệt danh sách thông báo trong app.
// Chỗ trống: {actor} {tribe} {task} {old} {new} {time}.
var pushTemplates = map[string]map[string][2]string{
	LangVI: {
		models.KindTribeNewBlock:         {"Hoạt động mới: {task}", "{actor} vừa thêm hoạt động vào {tribe}. Bạn có tham gia không?"},
		models.KindTribeBlockUpdated:     {"Đã cập nhật: {task}", "{actor} đã cập nhật thông tin hoạt động."},
		models.KindTribeBlockRescheduled: {"Đổi giờ: {task}", "{actor} đã đổi giờ, cần xác nhận lại."},
		models.KindTribeBlockCancelled:   {"Hoạt động đã bị huỷ", "{actor} đã huỷ \"{task}\" của nhóm {tribe}."},
		models.KindTribeResponseAccepted: {"Có người tham gia", "{actor} sẽ tham gia \"{task}\"."},
		models.KindTribeResponseDeclined: {"Có người không tham gia", "{actor} không tham gia \"{task}\"."},
		models.KindTribeMemberJoined:     {"Thành viên mới", "{actor} vừa tham gia {tribe}."},
		models.KindTribeMemberLeft:       {"Thành viên rời nhóm", "{actor} không còn ở trong {tribe}."},
		models.KindTribeKickedYou:        {"Bạn đã được mời rời nhóm", "{actor} đã mời bạn rời nhóm {tribe}."},
		models.KindTribeRenamed:          {"Nhóm đã đổi tên", "{actor} đã đổi tên nhóm \"{old}\" thành \"{new}\"."},
		models.KindTribeDissolved:        {"Nhóm đã giải tán", "{actor} đã giải tán nhóm {tribe}."},
		models.KindTribeRoleVice:         {"Thay đổi chức vụ", "Bạn đã được bổ nhiệm làm phó nhóm {tribe}."},
		models.KindTribeRoleViceRemoved:  {"Thay đổi chức vụ", "Bạn không còn là phó nhóm {tribe}."},
		models.KindTribeRoleLeader:       {"Thay đổi chức vụ", "Bạn đã được bổ nhiệm làm trưởng nhóm {tribe}."},
		models.KindPersonalBlockAdded:    {"Lịch cá nhân mới", "Bạn đã thêm \"{task}\" lúc {time}."},
		models.KindPersonalReminder:      {"Sắp tới giờ: {task}", "\"{task}\" bắt đầu lúc {time}."},
		models.KindTribeReminder:         {"Sắp tới giờ: {task}", "Hoạt động của nhóm {tribe} bắt đầu lúc {time}."},
		"":                               {"TimeTribe", "Bạn có thông báo mới"},
	},
	LangEN: {
		models.KindTribeNewBlock:         {"New activity: {task}", "{actor} added an activity to {tribe}. Are you joining?"},
		models.KindTribeBlockUpdated:     {"Updated: {task}", "{actor} updated the activity details."},
		models.KindTribeBlockRescheduled: {"Rescheduled: {task}", "{actor} changed the time — please confirm again."},
		models.KindTribeBlockCancelled:   {"Activity cancelled", "{actor} cancelled \"{task}\" in {tribe}."},
		models.KindTribeResponseAccepted: {"Someone is joining", "{actor} is joining \"{task}\"."},
		models.KindTribeResponseDeclined: {"Someone can't join", "{actor} can't join \"{task}\"."},
		models.KindTribeMemberJoined:     {"New member", "{actor} joined {tribe}."},
		models.KindTribeMemberLeft:       {"A member left", "{actor} is no longer in {tribe}."},
		models.KindTribeKickedYou:        {"You were removed from a tribe", "{actor} removed you from {tribe}."},
		models.KindTribeRenamed:          {"Tribe renamed", "{actor} renamed \"{old}\" to \"{new}\"."},
		models.KindTribeDissolved:        {"Tribe dissolved", "{actor} dissolved {tribe}."},
		models.KindTribeRoleVice:         {"Role changed", "You're now a co-leader of {tribe}."},
		models.KindTribeRoleViceRemoved:  {"Role changed", "You're no longer a co-leader of {tribe}."},
		models.KindTribeRoleLeader:       {"Role changed", "You're now the leader of {tribe}."},
		models.KindPersonalBlockAdded:    {"New personal activity", "You added \"{task}\" at {time}."},
		models.KindPersonalReminder:      {"Coming up: {task}", "\"{task}\" starts at {time}."},
		models.KindTribeReminder:         {"Coming up: {task}", "An activity of {tribe} starts at {time}."},
		"":                               {"TimeTribe", "You have a new notification"},
	},
	LangFR: {
		models.KindTribeNewBlock:         {"Nouvelle activité : {task}", "{actor} a ajouté une activité à {tribe}. Vous participez ?"},
		models.KindTribeBlockUpdated:     {"Mise à jour : {task}", "{actor} a mis à jour l'activité."},
		models.KindTribeBlockRescheduled: {"Horaire modifié : {task}", "{actor} a changé l'horaire, merci de reconfirmer."},
		models.KindTribeBlockCancelled:   {"Activité annulée", "{actor} a annulé « {task} » dans {tribe}."},
		models.KindTribeResponseAccepted: {"Quelqu'un participe", "{actor} participe à « {task} »."},
		models.KindTribeResponseDeclined: {"Quelqu'un ne participe pas", "{actor} ne participe pas à « {task} »."},
		models.KindTribeMemberJoined:     {"Nouveau membre", "{actor} a rejoint {tribe}."},
		models.KindTribeMemberLeft:       {"Un membre est parti", "{actor} ne fait plus partie de {tribe}."},
		models.KindTribeKickedYou:        {"Vous avez été retiré(e) d'une tribu", "{actor} vous a retiré(e) de {tribe}."},
		models.KindTribeRenamed:          {"Tribu renommée", "{actor} a renommé « {old} » en « {new} »."},
		models.KindTribeDissolved:        {"Tribu dissoute", "{actor} a dissous {tribe}."},
		models.KindTribeRoleVice:         {"Rôle modifié", "Vous êtes maintenant co-chef de {tribe}."},
		models.KindTribeRoleViceRemoved:  {"Rôle modifié", "Vous n'êtes plus co-chef de {tribe}."},
		models.KindTribeRoleLeader:       {"Rôle modifié", "Vous êtes maintenant chef de {tribe}."},
		models.KindPersonalBlockAdded:    {"Nouvelle activité personnelle", "Vous avez ajouté « {task} » à {time}."},
		models.KindPersonalReminder:      {"Bientôt : {task}", "« {task} » commence à {time}."},
		models.KindTribeReminder:         {"Bientôt : {task}", "Une activité de {tribe} commence à {time}."},
		"":                               {"TimeTribe", "Vous avez une nouvelle notification"},
	},
}

// PushText dựng tiêu đề và nội dung thông báo đẩy (hiện trên khay hệ thống) theo ngôn ngữ người nhận.
func PushText(lang, kind string, a map[string]string) (string, string) {
	table := pushTemplates[NormalizeLang(lang)]
	t, ok := table[kind]
	if !ok {
		t = table[""]
	}
	r := strings.NewReplacer(
		"{actor}", a["actor"], "{tribe}", a["tribe"], "{task}", a["task"],
		"{old}", a["old"], "{new}", a["new"], "{time}", a["time"],
	)
	return r.Replace(t[0]), r.Replace(t[1])
}
