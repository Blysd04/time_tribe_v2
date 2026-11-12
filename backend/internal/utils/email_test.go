package utils

import "testing"

func TestIsEmail(t *testing.T) {
	ok := []string{"a@b.co", "nga.tran+1@gmail.com", "x_y@fpt.edu.vn"}
	bad := []string{"abc@gmail", "abc@gmail.c", "a b@x.com", "a..b@x.com", ".a@x.com", "a@x..com", "a@-x.com", "abc", "abc@.com"}
	for _, e := range ok {
		if !IsEmail(e) {
			t.Errorf("%s phải hợp lệ", e)
		}
	}
	for _, e := range bad {
		if IsEmail(e) {
			t.Errorf("%s phải bị từ chối", e)
		}
	}
}

func TestEmailTypo(t *testing.T) {
	for in, want := range map[string]string{"nga@gmial.com": "nga@gmail.com", "nga@gmail.con": "nga@gmail.com", "a@yahooo.com": "a@yahoo.com"} {
		code, s := CheckEmailDomain(in)
		if code != EmailTypo || s != want {
			t.Errorf("%s: %s %s", in, code, s)
		}
	}
	for _, e := range []string{"a@gmail.com", "a@mail.com", "a@gmx.com"} {
		if code, _ := CheckEmailDomain(e); code != "" {
			t.Errorf("%s không phải lỗi gõ: %s", e, code)
		}
	}
	if levenshtein("gmaill.co", "gmail.com") != 2 {
		t.Error("levenshtein sai")
	}
}
