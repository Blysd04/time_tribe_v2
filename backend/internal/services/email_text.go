package services

import "strings"

// Các loại email hệ thống gửi.
const (
	mailResetPassword  = "reset_password"  // quên mật khẩu: link đặt lại
	mailConfirmEmail   = "confirm_email"   // đổi email: link xác nhận gửi tới email mới
	mailEmailChangeReq = "email_change"    // đổi email: báo cho email cũ
	mailPasswordChange = "password_change" // đã đổi mật khẩu
)

// mailTemplates: tiêu đề + nội dung email theo ngôn ngữ của tài khoản (users.language).
// Chỗ trống: {name} {link} {minutes} {email} {time}.
var mailTemplates = map[string]map[string][2]string{
	LangVI: {
		mailResetPassword: {"Đặt lại mật khẩu TimeTribe",
			"Chào {name},\n\nBạn vừa yêu cầu đặt lại mật khẩu TimeTribe. Mở đường dẫn sau trong vòng {minutes} phút để đặt mật khẩu mới:\n{link}\n\nNếu không phải bạn yêu cầu, hãy bỏ qua email này.\n\nTimeTribe"},
		mailConfirmEmail: {"Xác nhận email mới cho TimeTribe",
			"Chào {name},\n\nBạn vừa yêu cầu đổi email đăng nhập TimeTribe sang địa chỉ này.\nMở đường dẫn sau trong vòng 24 giờ để xác nhận:\n{link}\n\nNếu không phải bạn yêu cầu, hãy bỏ qua email này, email của tài khoản sẽ không thay đổi.\n\nTimeTribe"},
		mailEmailChangeReq: {"Yêu cầu đổi email TimeTribe",
			"Chào {name},\n\nCó yêu cầu đổi email đăng nhập TimeTribe của bạn sang {email}.\nEmail chỉ thay đổi khi địa chỉ mới bấm link xác nhận.\nNếu không phải bạn, hãy đổi mật khẩu ngay.\n\nTimeTribe"},
		mailPasswordChange: {"Mật khẩu TimeTribe đã thay đổi",
			"Chào {name},\n\nMật khẩu tài khoản TimeTribe của bạn vừa được thay đổi lúc {time} (UTC).\nMọi thiết bị đã được đăng xuất, yêu cầu đổi email đang chờ (nếu có) đã bị huỷ.\n\nNếu không phải bạn, hãy dùng chức năng Quên mật khẩu để lấy lại tài khoản ngay.\n\nTimeTribe"},
	},
	LangEN: {
		mailResetPassword: {"Reset your TimeTribe password",
			"Hi {name},\n\nYou asked to reset your TimeTribe password. Open this link within {minutes} minutes to set a new password:\n{link}\n\nIf you didn't ask for this, you can ignore this email.\n\nTimeTribe"},
		mailConfirmEmail: {"Confirm your new TimeTribe email",
			"Hi {name},\n\nYou asked to change your TimeTribe sign-in email to this address.\nOpen this link within 24 hours to confirm:\n{link}\n\nIf you didn't ask for this, ignore this email and your account email stays the same.\n\nTimeTribe"},
		mailEmailChangeReq: {"TimeTribe email change requested",
			"Hi {name},\n\nSomeone asked to change your TimeTribe sign-in email to {email}.\nThe email only changes once the new address opens the confirmation link.\nIf this wasn't you, change your password now.\n\nTimeTribe"},
		mailPasswordChange: {"Your TimeTribe password was changed",
			"Hi {name},\n\nThe password of your TimeTribe account was changed at {time} (UTC).\nEvery device has been signed out and any pending email change was cancelled.\n\nIf this wasn't you, use Forgot password to recover your account right away.\n\nTimeTribe"},
	},
	LangFR: {
		mailResetPassword: {"Réinitialiser votre mot de passe TimeTribe",
			"Bonjour {name},\n\nVous avez demandé à réinitialiser votre mot de passe TimeTribe. Ouvrez ce lien dans les {minutes} minutes pour choisir un nouveau mot de passe :\n{link}\n\nSi vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail.\n\nTimeTribe"},
		mailConfirmEmail: {"Confirmez votre nouvel e-mail TimeTribe",
			"Bonjour {name},\n\nVous avez demandé à remplacer l'e-mail de connexion TimeTribe par cette adresse.\nOuvrez ce lien dans les 24 heures pour confirmer :\n{link}\n\nSi vous n'êtes pas à l'origine de cette demande, ignorez cet e-mail : l'e-mail du compte ne changera pas.\n\nTimeTribe"},
		mailEmailChangeReq: {"Demande de changement d'e-mail TimeTribe",
			"Bonjour {name},\n\nUne demande a été faite pour remplacer votre e-mail de connexion TimeTribe par {email}.\nL'e-mail ne change que lorsque la nouvelle adresse ouvre le lien de confirmation.\nSi ce n'est pas vous, changez votre mot de passe tout de suite.\n\nTimeTribe"},
		mailPasswordChange: {"Votre mot de passe TimeTribe a été modifié",
			"Bonjour {name},\n\nLe mot de passe de votre compte TimeTribe a été modifié à {time} (UTC).\nTous les appareils ont été déconnectés et la demande de changement d'e-mail en attente (le cas échéant) a été annulée.\n\nSi ce n'est pas vous, utilisez « Mot de passe oublié » pour récupérer votre compte immédiatement.\n\nTimeTribe"},
	},
}

// MailText dựng tiêu đề và nội dung email theo ngôn ngữ, vars thay vào các chỗ trống {tên}.
func MailText(lang, kind string, vars map[string]string) (string, string) {
	t := mailTemplates[NormalizeLang(lang)][kind]
	pairs := make([]string, 0, len(vars)*2)
	for k, v := range vars {
		pairs = append(pairs, "{"+k+"}", v)
	}
	r := strings.NewReplacer(pairs...)
	return r.Replace(t[0]), r.Replace(t[1])
}

// withLang gắn ?lang= / &lang= vào link trong email để trang mở ra hiện đúng ngôn ngữ.
func withLang(link, lang string) string {
	sep := "?"
	if strings.Contains(link, "?") {
		sep = "&"
	}
	return link + sep + "lang=" + NormalizeLang(lang)
}
