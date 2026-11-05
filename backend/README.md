# TimeTribe backend

Backend cho ứng dụng TimeTribe v2, viết bằng Go (Gin) và MongoDB.
Đăng nhập Google và thông báo đẩy dùng Firebase Admin SDK, ảnh lưu trên Cloudinary.

## Cấu trúc thư mục

```
backend/
├── cmd/
│   ├── server/        # điểm chạy API
│   └── seed/          # nạp dữ liệu mẫu để test
├── internal/
│   ├── config/        # đọc .env
│   ├── database/      # kết nối MongoDB, tạo index
│   ├── models/        # 11 struct ứng với 11 bảng trong thiết kế CSDL
│   ├── repository/    # handle tới các collection + hàm truy vấn dùng chung
│   ├── services/      # nghiệp vụ: auth, user, timeblock, template, tribe, notification, reminder
│   ├── handlers/      # nhận request, gọi service, trả JSON; routes.go liệt kê mọi API
│   ├── middleware/    # JWT, quyền admin, CORS
│   └── utils/         # lỗi, response, xử lý ngày giờ, kiểm tra dữ liệu
├── postman/           # collection để import vào Postman
├── API_TESTING.md     # danh sách API và cách test
└── .env.example
```

Luồng xử lý: Handler -> Service -> Repository (MongoDB driver) -> MongoDB.

## Quy ước đặt tên

Theo sheet "Ánh xạ CSDL & Models (11 Bảng)":

- Tên collection và tên field trong MongoDB, JSON key: snake_case, giống hệt cột MySQL (`nick_name`, `avatar_url`, `template_name`...).
- Struct Go: PascalCase (`NickName`, `AvatarURL`, `TemplateName`...).
- Khoá chính lưu ở `_id` trong MongoDB nhưng trả ra JSON là `id` (riêng `user_securities` trả ra `user_id`).
- `date` lưu chuỗi `YYYY-MM-DD`, `start_time`/`end_time` lưu chuỗi `HH:mm:ss`.
  Lịch cá nhân tính theo múi giờ của chủ lịch, lịch nhóm tính theo UTC.

## Chạy lần đầu

Cần Go 1.23 trở lên và MongoDB đang chạy ở `mongodb://localhost:27017`.

1. Tạo file cấu hình:

```bash
cp .env.example .env
```

   Điền `CLOUDINARY_URL`, đổi `JWT_SECRET`, đặt file `serviceAccountKey.json` cạnh file `.env`
   (gói gửi kèm đã có sẵn `.env` và `serviceAccountKey.json`).

2. Tải thư viện:

```bash
go mod download
```

3. Nạp dữ liệu mẫu (xoá sạch database `timetribe` rồi nạp lại):

```bash
go run ./cmd/seed
```

4. Chạy server:

```bash
go run ./cmd/server
```

   Mở `http://localhost:8080/health`, thấy `"status":"ok"` là được.
   `firebase_auth` và `firebase_push` bằng `true` nghĩa là đã đọc được file service account.

Build ra file chạy:

```bash
go build -o bin/timetribe ./cmd/server
```

## Ghi chú

- Không dùng transaction vì MongoDB chạy đơn lẻ (không phải replica set) không hỗ trợ.
  Những chỗ ghi nhiều collection thì ghi lần lượt, lỗi giữa chừng sẽ tự dọn bản ghi vừa tạo.
- Bộ nhắc lịch (`ENABLE_REMINDER=true`) quét mỗi phút, tới mốc "nhắc trước X phút" thì tạo
  thông báo loại `reminder` và gửi FCM.
- Refresh token và token đặt lại mật khẩu chỉ lưu bản băm SHA-256 trong `user_tokens`.
- Đổi hoặc đặt lại mật khẩu thì mọi access token cấp trước đó đều bị từ chối.
- `.env` và `serviceAccountKey.json` đã nằm trong `.gitignore`, đừng commit hai file này.
