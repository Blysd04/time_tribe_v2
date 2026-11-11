package services

import (
	"strings"
	"testing"
)

func TestMailTextByLanguage(t *testing.T) {
	vars := map[string]string{"name": "Nga", "link": "https://x/r?token=a", "minutes": "30", "email": "a@b.co", "time": "10:00"}
	for _, kind := range []string{mailResetPassword, mailConfirmEmail, mailEmailChangeReq, mailPasswordChange} {
		for _, lang := range []string{LangVI, LangEN, LangFR} {
			subject, body := MailText(lang, kind, vars)
			if subject == "" || body == "" || strings.Contains(body, "{") {
				t.Errorf("%s/%s thiếu nội dung hoặc còn chỗ trống: %q", lang, kind, body)
			}
		}
	}
	if s, _ := MailText("en", mailResetPassword, vars); s != "Reset your TimeTribe password" {
		t.Errorf("tiêu đề tiếng Anh sai: %s", s)
	}
	if s, _ := MailText("xx", mailResetPassword, vars); s != "Đặt lại mật khẩu TimeTribe" {
		t.Errorf("ngôn ngữ lạ phải dùng tiếng Việt: %s", s)
	}
	if withLang("https://x/r?token=a", "fr") != "https://x/r?token=a&lang=fr" || withLang("https://x/r", "en") != "https://x/r?lang=en" {
		t.Error("withLang sai")
	}
}
