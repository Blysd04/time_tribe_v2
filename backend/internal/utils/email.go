package utils

import (
	"context"
	"errors"
	"net"
	"regexp"
	"strings"
	"time"
)

// emailRe: phần trước @ gồm chữ, số và . _ % + -; tên miền có ít nhất một dấu chấm,
// đuôi cuối (com, vn, edu...) từ 2 chữ cái trở lên. Chặn được "abc@gmail", "abc@gmail.c", "a b@x.com".
var emailRe = regexp.MustCompile(`^[a-z0-9._%+\-]+@[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?)*\.[a-z]{2,}$`)

// popularDomains: nhà cung cấp email phổ biến, dùng để đoán lỗi gõ nhầm tên miền.
var popularDomains = []string{
	"gmail.com", "yahoo.com", "yahoo.com.vn", "hotmail.com", "outlook.com", "icloud.com", "live.com",
	"protonmail.com", "fpt.edu.vn", "fpt.com.vn", "vnu.edu.vn", "hcmut.edu.vn",
}

// realDomains: tên miền thật dù gần giống tên miền phổ biến, không được coi là gõ nhầm.
var realDomains = map[string]bool{
	"mail.com": true, "gmx.com": true, "ymail.com": true, "me.com": true, "mac.com": true,
	"msn.com": true, "aol.com": true, "live.vn": true, "outlook.com.vn": true, "hotmail.com.vn": true,
	"googlemail.com": true, "proton.me": true, "zoho.com": true, "yandex.com": true,
}

// commonTypos: lỗi gõ hay gặp, tên miền dạng này thường vẫn có máy chủ thư (của kẻ chiếm tên miền)
// nên không phát hiện được bằng tra DNS.
var commonTypos = map[string]string{
	"gmial.com": "gmail.com", "gmai.com": "gmail.com", "gamil.com": "gmail.com", "gnail.com": "gmail.com",
	"gmal.com": "gmail.com", "gmaill.com": "gmail.com", "gmail.co": "gmail.com", "gmail.con": "gmail.com",
	"gmail.cm": "gmail.com", "gmail.om": "gmail.com", "gmail.cmo": "gmail.com", "gmail.vn": "gmail.com",
	"gmail.com.vn": "gmail.com", "gmali.com": "gmail.com", "gmaik.com": "gmail.com", "gmeil.com": "gmail.com",
	"yaho.com": "yahoo.com", "yahooo.com": "yahoo.com", "yahoo.co": "yahoo.com", "yhoo.com": "yahoo.com",
	"hotmial.com": "hotmail.com", "hotmai.com": "hotmail.com", "hotmail.co": "hotmail.com", "hotmal.com": "hotmail.com",
	"outlok.com": "outlook.com", "outllok.com": "outlook.com", "outlook.co": "outlook.com",
	"iclod.com": "icloud.com", "icloud.co": "icloud.com", "icoud.com": "icloud.com",
}

// IsEmail kiểm tra chuỗi (đã viết thường) có đúng dạng email không.
func IsEmail(s string) bool {
	if len(s) > 254 || !emailRe.MatchString(s) {
		return false
	}
	local := s[:strings.LastIndex(s, "@")]
	return len(local) <= 64 && !strings.HasPrefix(local, ".") && !strings.HasSuffix(local, ".") && !strings.Contains(s, "..")
}

// Các mã lỗi kiểm tra email, app dịch ra câu thông báo.
const (
	EmailTypo          = "email_typo"           // gõ nhầm tên miền, kèm gợi ý email đúng
	EmailDomainInvalid = "email_domain_invalid" // tên miền không nhận thư được
)

// CheckEmailDomain bắt lỗi chính tả ở tên miền email (đã đúng dạng):
//   - tên miền nằm trong danh sách lỗi gõ hay gặp (gmial.com, gmail.con...) -> email_typo + gợi ý
//   - tên miền không có máy chủ nhận thư (tra DNS) -> gần giống tên miền phổ biến thì email_typo + gợi ý,
//     không thì email_domain_invalid
//
// Tra DNS lỗi mạng (không phải "không có tên miền") thì cho qua, tránh chặn nhầm người dùng.
func CheckEmailDomain(email string) (code, suggestion string) {
	at := strings.LastIndex(email, "@")
	if at < 0 {
		return "", ""
	}
	local, domain := email[:at], email[at+1:]
	if fix, ok := commonTypos[domain]; ok {
		return EmailTypo, local + "@" + fix
	}
	if realDomains[domain] {
		return "", ""
	}
	for _, d := range popularDomains {
		if d == domain {
			return "", ""
		}
	}
	if domainReceivesMail(domain) {
		return "", ""
	}
	if near := nearestPopular(domain); near != "" {
		return EmailTypo, local + "@" + near
	}
	return EmailDomainInvalid, ""
}

// domainReceivesMail tra bản ghi MX (hoặc A/AAAA) của tên miền, tối đa 3 giây.
func domainReceivesMail(domain string) bool {
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	mx, err := net.DefaultResolver.LookupMX(ctx, domain)
	if err == nil && len(mx) > 0 {
		return true
	}
	if err != nil && !isNotFound(err) {
		return true // lỗi mạng, không kết luận được
	}
	hosts, err := net.DefaultResolver.LookupHost(ctx, domain)
	if err != nil && !isNotFound(err) {
		return true
	}
	return len(hosts) > 0
}

func isNotFound(err error) bool {
	var dnsErr *net.DNSError
	return errors.As(err, &dnsErr) && dnsErr.IsNotFound
}

// nearestPopular trả tên miền phổ biến cách domain tối đa 2 ký tự sửa, không có thì "".
func nearestPopular(domain string) string {
	best, bestDist := "", 3
	for _, d := range popularDomains {
		if dist := levenshtein(domain, d); dist < bestDist {
			best, bestDist = d, dist
		}
	}
	return best
}

// levenshtein đếm số lần thêm/xoá/thay ký tự ít nhất để biến a thành b.
func levenshtein(a, b string) int {
	ra, rb := []rune(a), []rune(b)
	prev := make([]int, len(rb)+1)
	cur := make([]int, len(rb)+1)
	for j := range prev {
		prev[j] = j
	}
	for i := 1; i <= len(ra); i++ {
		cur[0] = i
		for j := 1; j <= len(rb); j++ {
			cost := 1
			if ra[i-1] == rb[j-1] {
				cost = 0
			}
			cur[j] = min(prev[j]+1, cur[j-1]+1, prev[j-1]+cost)
		}
		prev, cur = cur, prev
	}
	return prev[len(rb)]
}
