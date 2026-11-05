package utils

import (
	"errors"
	"net/http"
)

// AppError là lỗi nghiệp vụ, mang sẵn mã HTTP và mã lỗi để app hiển thị đúng câu thông báo.
// Code nên khớp với các enum kết quả ở front-end (tribe_limit, already_member, overlap...).
type AppError struct {
	Status  int    `json:"-"`
	Code    string `json:"code"`
	Message string `json:"message"`
	Details any    `json:"details,omitempty"`
}

func (e *AppError) Error() string { return e.Message }

func (e *AppError) WithDetails(d any) *AppError {
	cp := *e
	cp.Details = d
	return &cp
}

func NewError(status int, code, message string) *AppError {
	return &AppError{Status: status, Code: code, Message: message}
}

func BadRequest(code, message string) *AppError {
	return NewError(http.StatusBadRequest, code, message)
}

func Unauthorized(code, message string) *AppError {
	return NewError(http.StatusUnauthorized, code, message)
}

func Forbidden(code, message string) *AppError {
	return NewError(http.StatusForbidden, code, message)
}

func NotFound(code, message string) *AppError {
	return NewError(http.StatusNotFound, code, message)
}

func Conflict(code, message string) *AppError {
	return NewError(http.StatusConflict, code, message)
}

func Internal(message string) *AppError {
	return NewError(http.StatusInternalServerError, "internal_error", message)
}

// Các lỗi dùng lại nhiều lần.
var (
	ErrNotAllowed   = Forbidden("not_allowed", "Bạn không có quyền thực hiện thao tác này")
	ErrTribeMissing = NotFound("not_found_item", "Không tìm thấy nhóm hoặc bạn không còn ở trong nhóm")
)

func AsAppError(err error) (*AppError, bool) {
	var ae *AppError
	if errors.As(err, &ae) {
		return ae, true
	}
	return nil, false
}
