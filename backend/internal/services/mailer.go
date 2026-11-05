package services

import (
	"fmt"
	"log"
	"net/smtp"
	"strings"
)

// Mailer gửi email qua SMTP. Chưa cấu hình SMTP thì chỉ in nội dung ra log để dev test.
type Mailer struct {
	host, port, user, pass, from string
}

func NewMailer(host, port, user, pass, from string) *Mailer {
	if from == "" {
		from = user
	}
	return &Mailer{host: host, port: port, user: user, pass: pass, from: from}
}

func (m *Mailer) Enabled() bool { return m.host != "" && m.user != "" }

func (m *Mailer) Send(to, subject, body string) error {
	if !m.Enabled() {
		log.Printf("chưa cấu hình SMTP, email gửi tới %s:\n%s\n%s", to, subject, body)
		return nil
	}
	msg := strings.Join([]string{
		"From: TimeTribe <" + m.from + ">",
		"To: " + to,
		"Subject: " + subject,
		"MIME-Version: 1.0",
		"Content-Type: text/plain; charset=UTF-8",
		"",
		body,
	}, "\r\n")
	auth := smtp.PlainAuth("", m.user, m.pass, m.host)
	if err := smtp.SendMail(m.host+":"+m.port, auth, m.from, []string{to}, []byte(msg)); err != nil {
		return fmt.Errorf("gửi email thất bại: %w", err)
	}
	return nil
}
