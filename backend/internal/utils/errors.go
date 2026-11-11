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

// Error trả câu báo lỗi để AppError dùng được như error thường.
func (e *AppError) Error() string { return e.Message }

// WithDetails tạo bản sao của lỗi kèm thêm thông tin chi tiết (lỗi từng ô, danh sách trùng...).
func (e *AppError) WithDetails(d any) *AppError {
	cp := *e
	cp.Details = d
	return &cp
}

// NewError tạo lỗi nghiệp vụ với mã HTTP và mã lỗi tuỳ ý.
func NewError(status int, code, message string) *AppError {
	return &AppError{Status: status, Code: code, Message: message}
}

// BadRequest tạo lỗi 400 (dữ liệu gửi lên sai).
func BadRequest(code, message string) *AppError {
	return NewError(http.StatusBadRequest, code, message)
}

// Unauthorized tạo lỗi 401 (chưa đăng nhập hoặc phiên hết hạn).
func Unauthorized(code, message string) *AppError {
	return NewError(http.StatusUnauthorized, code, message)
}

// Forbidden tạo lỗi 403 (không đủ quyền).
func Forbidden(code, message string) *AppError {
	return NewError(http.StatusForbidden, code, message)
}

// NotFound tạo lỗi 404 (không tìm thấy).
func NotFound(code, message string) *AppError {
	return NewError(http.StatusNotFound, code, message)
}

// Conflict tạo lỗi 409 (trùng hoặc vi phạm luật như giới hạn số nhóm).
func Conflict(code, message string) *AppError {
	return NewError(http.StatusConflict, code, message)
}

// Internal tạo lỗi 500.
func Internal(message string) *AppError {
	return NewError(http.StatusInternalServerError, "internal_error", message)
}

// Các lỗi dùng lại nhiều lần.
var (
	ErrNotAllowed   = Forbidden("not_allowed", "Bạn không có quyền thực hiện thao tác này")
	ErrTribeMissing = NotFound("not_found_item", "Không tìm thấy nhóm hoặc bạn không còn ở trong nhóm")
)

// AsAppError kiểm tra một error có phải AppError không, có thì lấy ra.
func AsAppError(err error) (*AppError, bool) {
	var ae *AppError
	if errors.As(err, &ae) {
		return ae, true
	}
	return nil, false
}
