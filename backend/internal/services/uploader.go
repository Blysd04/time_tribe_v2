package services

import (
	"context"
	"log"
	"mime/multipart"
	"net/http"
	"strings"

	"github.com/cloudinary/cloudinary-go/v2"
	"github.com/cloudinary/cloudinary-go/v2/api"
	"github.com/cloudinary/cloudinary-go/v2/api/uploader"

	"timetribe-backend/internal/utils"
)

const maxImageSize = 5 << 20 // 5MB

// Uploader đẩy ảnh lên Cloudinary (ảnh đại diện, ảnh nền nhóm).
type Uploader struct {
	cld *cloudinary.Cloudinary
}

func NewUploader(cloudinaryURL string) *Uploader {
	if cloudinaryURL == "" {
		log.Println("chưa cấu hình CLOUDINARY_URL, tắt chức năng tải ảnh")
		return &Uploader{}
	}
	cld, err := cloudinary.NewFromURL(cloudinaryURL)
	if err != nil {
		log.Printf("CLOUDINARY_URL không hợp lệ: %v", err)
		return &Uploader{}
	}
	cld.Config.URL.Secure = true
	log.Println("đã cấu hình Cloudinary")
	return &Uploader{cld: cld}
}

// UploadImage kiểm tra file là ảnh, tối đa 5MB, rồi tải lên thư mục cho trước.
// publicID cố định theo user/nhóm nên ảnh mới sẽ ghi đè ảnh cũ, không để rác trên Cloudinary.
func (u *Uploader) UploadImage(ctx context.Context, fh *multipart.FileHeader, folder, publicID string, square bool) (string, error) {
	if u.cld == nil {
		return "", utils.NewError(http.StatusServiceUnavailable, "upload_disabled", "Máy chủ chưa cấu hình Cloudinary")
	}
	if fh.Size > maxImageSize {
		return "", utils.BadRequest("file_too_large", "Ảnh tối đa 5MB")
	}
	file, err := fh.Open()
	if err != nil {
		return "", utils.BadRequest("invalid_file", "Không đọc được file ảnh")
	}
	defer file.Close()

	// Đọc 512 byte đầu để đoán loại file thật, không tin vào đuôi file
	head := make([]byte, 512)
	n, _ := file.Read(head)
	if !strings.HasPrefix(http.DetectContentType(head[:n]), "image/") {
		return "", utils.BadRequest("invalid_file", "File gửi lên không phải ảnh")
	}
	if _, err := file.Seek(0, 0); err != nil {
		return "", err
	}

	params := uploader.UploadParams{
		Folder:         folder,
		PublicID:       publicID,
		Overwrite:      api.Bool(true),
		Invalidate:     api.Bool(true),
		UniqueFilename: api.Bool(false),
	}
	if square {
		params.Transformation = "c_fill,g_face,w_512,h_512,q_auto,f_auto"
	} else {
		params.Transformation = "c_limit,w_1280,h_1280,q_auto,f_auto"
	}
	res, err := u.cld.Upload.Upload(ctx, file, params)
	if err != nil {
		log.Printf("tải ảnh lên Cloudinary lỗi: %v", err)
		return "", utils.NewError(http.StatusBadGateway, "upload_failed", "Không tải được ảnh lên Cloudinary, vui lòng thử lại")
	}
	if res.Error.Message != "" {
		return "", utils.NewError(http.StatusBadGateway, "upload_failed", "Cloudinary báo lỗi: "+res.Error.Message)
	}
	return res.SecureURL, nil
}
