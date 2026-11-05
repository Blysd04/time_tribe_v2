package utils

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Mọi response đều có dạng:
// thành công: {"success": true, "message": "...", "data": ...}
// thất bại:   {"success": false, "error": {"code": "...", "message": "...", "details": ...}}

func OK(c *gin.Context, message string, data any) {
	c.JSON(http.StatusOK, gin.H{"success": true, "message": message, "data": data})
}

func Created(c *gin.Context, message string, data any) {
	c.JSON(http.StatusCreated, gin.H{"success": true, "message": message, "data": data})
}

func Fail(c *gin.Context, err error) {
	if ae, ok := AsAppError(err); ok {
		c.AbortWithStatusJSON(ae.Status, gin.H{"success": false, "error": ae})
		return
	}
	log.Printf("lỗi không mong đợi tại %s %s: %v", c.Request.Method, c.Request.URL.Path, err)
	c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
		"success": false,
		"error":   Internal("Máy chủ đang gặp sự cố, vui lòng thử lại sau"),
	})
}

// BindJSON đọc body JSON, lỗi thì trả 400 luôn. Trả về false khi đã trả lỗi.
func BindJSON(c *gin.Context, dst any) bool {
	if err := c.ShouldBindJSON(dst); err != nil {
		Fail(c, BadRequest("invalid_body", "Dữ liệu gửi lên không đúng định dạng JSON: "+err.Error()))
		return false
	}
	return true
}
