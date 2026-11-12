package services

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"mime"
	"net"
	"net/http"
	"net/smtp"
	"strings"
	"time"
)

// Mailer gửi email theo thứ tự ưu tiên:
//  1. Brevo HTTP API (BREVO_API_KEY): gửi qua HTTPS cổng 443. Dùng khi chạy trên Render gói Free,
//     vì gói này chặn các cổng SMTP (25, 465, 587) nên gửi bằng SMTP sẽ bị treo rồi lỗi.
//  2. SMTP (SMTP_HOST, SMTP_USER, SMTP_PASS): cổng 465 dùng TLS trực tiếp, cổng khác dùng STARTTLS.
//  3. Chưa cấu hình gì: chỉ in nội dung email ra log để dev test.
type Mailer struct {
	host, port, user, pass, from string
	brevoKey, fromName           string
	client                       *http.Client
}

// NewMailer tạo bộ gửi email, không có địa chỉ gửi riêng thì dùng tài khoản SMTP.
func NewMailer(host, port, user, pass, from, brevoKey, fromName string) *Mailer {
	if from == "" {
		from = user
	}
	if fromName == "" {
		fromName = "TimeTribe"
	}
	return &Mailer{host: host, port: port, user: user, pass: pass, from: from,
		brevoKey: brevoKey, fromName: fromName, client: &http.Client{Timeout: 15 * time.Second}}
}

// Enabled cho biết đã cấu hình cách gửi email thật chưa.
func (m *Mailer) Enabled() bool {
	return (m.brevoKey != "" && m.from != "") || (m.host != "" && m.user != "")
}

// Describe mô tả cách gửi email đang dùng, in ra log lúc khởi động để dễ kiểm tra cấu hình.
func (m *Mailer) Describe() string {
	switch {
	case m.brevoKey != "" && m.from != "":
		return "Brevo API, người gửi " + m.from
	case m.brevoKey != "":
		return "chưa gửi được: có BREVO_API_KEY nhưng thiếu SMTP_FROM (email người gửi đã xác minh trên Brevo)"
	case m.host != "" && m.user != "":
		return "SMTP " + m.host + ":" + m.port + ", người gửi " + m.from
	}
	return "chưa cấu hình, email chỉ in ra log"
}

// Send gửi một email chữ thường.
func (m *Mailer) Send(to, subject, body string) error {
	switch {
	case m.brevoKey != "" && m.from != "":
		return m.sendBrevo(to, subject, body)
	case m.host != "" && m.user != "":
		return m.sendSMTP(to, subject, body)
	}
	log.Printf("chưa cấu hình gửi email, email gửi tới %s:\n%s\n%s", to, subject, body)
	return nil
}

// sendBrevo gọi https://api.brevo.com/v3/smtp/email.
func (m *Mailer) sendBrevo(to, subject, body string) error {
	payload, _ := json.Marshal(map[string]any{
		"sender":      map[string]string{"name": m.fromName, "email": m.from},
		"to":          []map[string]string{{"email": to}},
		"subject":     subject,
		"textContent": body,
	})
	req, err := http.NewRequest(http.MethodPost, "https://api.brevo.com/v3/smtp/email", bytes.NewReader(payload))
	if err != nil {
		return err
	}
	req.Header.Set("api-key", m.brevoKey)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	res, err := m.client.Do(req)
	if err != nil {
		return fmt.Errorf("gửi email qua Brevo thất bại: %w", err)
	}
	defer res.Body.Close()
	if res.StatusCode >= 300 {
		msg, _ := io.ReadAll(io.LimitReader(res.Body, 500))
		return fmt.Errorf("Brevo từ chối email tới %s (HTTP %d): %s", to, res.StatusCode, msg)
	}
	log.Printf("đã gửi email %q tới %s qua Brevo", subject, to)
	return nil
}

// sendSMTP gửi qua máy chủ SMTP, có giới hạn thời gian để không treo request của người dùng.
func (m *Mailer) sendSMTP(to, subject, body string) error {
	msg := []byte(strings.Join([]string{
		"From: " + mime.QEncoding.Encode("utf-8", m.fromName) + " <" + m.from + ">",
		"To: " + to,
		"Subject: " + mime.QEncoding.Encode("utf-8", subject),
		"MIME-Version: 1.0",
		"Content-Type: text/plain; charset=UTF-8",
		"Date: " + time.Now().Format(time.RFC1123Z),
		"",
		body,
	}, "\r\n"))
	addr := net.JoinHostPort(m.host, m.port)
	dialer := &net.Dialer{Timeout: 10 * time.Second}
	var conn net.Conn
	var err error
	if m.port == "465" {
		conn, err = tls.DialWithDialer(dialer, "tcp", addr, &tls.Config{ServerName: m.host})
	} else {
		conn, err = dialer.Dial("tcp", addr)
	}
	if err != nil {
		return fmt.Errorf("không kết nối được SMTP %s (máy chủ có chặn cổng SMTP không?): %w", addr, err)
	}
	_ = conn.SetDeadline(time.Now().Add(30 * time.Second))
	c, err := smtp.NewClient(conn, m.host)
	if err != nil {
		conn.Close()
		return fmt.Errorf("gửi email thất bại: %w", err)
	}
	defer c.Close()
	if m.port != "465" {
		if ok, _ := c.Extension("STARTTLS"); ok {
			if err := c.StartTLS(&tls.Config{ServerName: m.host}); err != nil {
				return fmt.Errorf("gửi email thất bại (STARTTLS): %w", err)
			}
		}
	}
	if err := c.Auth(smtp.PlainAuth("", m.user, m.pass, m.host)); err != nil {
		return fmt.Errorf("đăng nhập SMTP thất bại, kiểm tra SMTP_USER/SMTP_PASS (Gmail cần mật khẩu ứng dụng): %w", err)
	}
	if err := c.Mail(m.from); err != nil {
		return fmt.Errorf("gửi email thất bại: %w", err)
	}
	if err := c.Rcpt(to); err != nil {
		return fmt.Errorf("gửi email thất bại (người nhận %s): %w", to, err)
	}
	w, err := c.Data()
	if err != nil {
		return fmt.Errorf("gửi email thất bại: %w", err)
	}
	if _, err := w.Write(msg); err != nil {
		return fmt.Errorf("gửi email thất bại: %w", err)
	}
	if err := w.Close(); err != nil {
		return fmt.Errorf("gửi email thất bại: %w", err)
	}
	log.Printf("đã gửi email %q tới %s qua SMTP", subject, to)
	return c.Quit()
}
