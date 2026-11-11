# Hướng dẫn test API TimeTribe trên Postman

## 1. Chuẩn bị

1. Bật MongoDB ở `mongodb://localhost:27017`.
2. Trong thư mục `backend`, nạp dữ liệu mẫu rồi chạy server:

```bash
go run ./cmd/seed
```

```bash
go run ./cmd/server
```

3. Mở Postman, chọn Import, kéo file `postman/TimeTribe.postman_collection.json` vào.
4. Collection đã có sẵn biến (tab Variables của collection):
   - `baseUrl` = `http://localhost:8080/api/v1`
   - `accessToken`, `refreshToken`: tự điền khi chạy request đăng nhập, không cần copy tay.
   - `today`, `tomorrow`, `in2days`...: tự tính theo giờ Việt Nam trước mỗi request.
   - ID của dữ liệu mẫu (`tribeNic`, `userMinh`, `blockBad1`, `tplNgaNic`...) đã điền sẵn.
   - `timeblockId`, `templateId`, `tribeId`, `tribeBlockId`...: tự điền sau request tạo mới.
5. Auth của collection là Bearer Token `{{accessToken}}`, request nào không cần đăng nhập đã đặt No Auth.

Có thể chạy cả collection một lượt bằng Runner (chuột phải vào collection, chọn Run).
Mỗi folder bắt đầu bằng một request đăng nhập nên chạy riêng từng folder cũng được.
Muốn làm lại từ đầu thì chạy lại `go run ./cmd/seed`.

Khi chạy Runner, có vài request sẽ báo đỏ hoặc 400 vì cần dữ liệu thật mà Postman không tự có:
AU-03 Đăng nhập Google (cần `firebaseIdToken`), cập nhật ảnh đại diện (cần chọn file),
cập nhật `fcm_token` (cần `fcmToken`). Cách lấy các giá trị này ở mục 7.

## 2. Dữ liệu mẫu

Mật khẩu chung của mọi tài khoản là `123456`. ID cố định, seed lại bao nhiêu lần cũng không đổi.

| Tên hiển thị | Email | Múi giờ | Ghi chú |
|---|---|---|---|
| admin | admin@timetribe.com | Asia/Ho_Chi_Minh | role admin |
| Tuyết Nga | tuyetnga@timetribe.app | Asia/Ho_Chi_Minh | tài khoản chính để test, trưởng nhóm NIC |
| Minh Trần | minh.tran@timetribe.app | Asia/Ho_Chi_Minh | phó nhóm NIC và Cầu lông |
| Linh Phạm | linh.pham@timetribe.app | Asia/Ho_Chi_Minh | trưởng nhóm Marketing, có lịch mẫu chia sẻ mã `STUDYWEEK` |
| Hana Sato | hana.sato@timetribe.app | Asia/Tokyo | |
| David Nguyen | david.nguyen@timetribe.app | America/Vancouver | |
| An Lê | an.le@timetribe.app | Asia/Ho_Chi_Minh | thành viên thường |
| Khoa Đỗ | khoa.do@timetribe.app | Europe/London | |
| Mai Võ | mai.vo@timetribe.app | Asia/Ho_Chi_Minh | trưởng nhóm Cầu lông |
| Tuấn Hồ | tuan.ho@timetribe.app | Asia/Ho_Chi_Minh | trưởng nhóm Game Dev và nhóm đã đủ người |
| Vy Ngô | vy.ngo@timetribe.app | Australia/Sydney | |
| Phúc Lâm | phuc.lam@timetribe.app | Asia/Ho_Chi_Minh | dùng để thử đổi mật khẩu |
| Bảo Ngọc | baongoc.gg@gmail.com | Asia/Ho_Chi_Minh | tài khoản Google, không có mật khẩu |
| spam.bot | spam.bot@timetribe.app | Asia/Ho_Chi_Minh | bị khoá |

Nhóm:

| Nhóm | invite_code | ID | Thành viên |
|---|---|---|---|
| Đồ án NIC | NIC2026 | 7bc48d74-1b52-5485-ad17-bc82aeda2cf3 | Nga (trưởng), Minh (phó), Linh, Hana, David, An |
| CLB Cầu lông Q7 | CAULONGQ7 | 64f48035-9cc0-59d7-adf1-66ba31c05d2e | Mai (trưởng), Minh (phó), Nga, An |
| Team Marketing Global | MKTGLOBAL | 1ceb057c-e620-5b79-95ea-7e4d063e9dd2 | Linh (trưởng), Nga và Hana (phó), 5 thành viên |
| Hội Game Dev | GAMEDEV26 | a34504f2-16b6-5dcd-9e11-dff438d627e9 | Nga chưa tham gia, dùng để thử tham gia |
| Nhóm đã đủ người | FULLHOUSE | 8fcf8392-3bcd-556e-953b-25ab3d6e64f8 | đủ 10 người, dùng để thử lỗi tribe_full |

Ngoài ra còn có:

- Lịch cá nhân của Nga, Minh, Linh, Hana, David từ 7 ngày trước tới 14 ngày sau (lặp theo thứ trong tuần).
- 7 hoạt động nhóm tính theo hôm nay: "Họp chốt tiến độ" 20:00 hôm nay, "Đánh cầu tối" 18:30 ngày mai (Nga đang chờ trả lời),
  "Lên kế hoạch chiến dịch Tết" sau 3 ngày...
- Lịch mẫu: Nga có "Tuần học NIC & Đi làm" và "Quy trình tập Gym 4 ngày" (share_code `GYM4DAY`),
  Linh có "Tuần ôn thi cuối kỳ" (share_code `STUDYWEEK`).
- `fcm_token` của mọi tài khoản mẫu đều là null.
- Thông báo của Nga trong 30 ngày, một thông báo 45 ngày trước (không được hiện), một thông báo chung của admin.

## 3. Quy ước chung

Header cho request cần đăng nhập:

```
Authorization: Bearer <access_token>
Content-Type: application/json
```

Thành công:

```json
{ "success": true, "message": "Đã lưu hoạt động", "data": { } }
```

Thất bại:

```json
{
  "success": false,
  "error": { "code": "overlap", "message": "Khung giờ này đã có hoạt động khác", "details": [] }
}
```

`code` khớp với enum kết quả ở front-end để app hiện đúng câu thông báo đa ngôn ngữ:

| HTTP | code | Ý nghĩa |
|---|---|---|
| 400 | validation_error | dữ liệu sai, `details` cho biết ô nào lỗi gì |
| 400 | invalid_body | body không phải JSON hợp lệ |
| 400 | past_date, past_time, duration_too_short, invalid_time, invalid_color, invalid_remind | lỗi nhập lịch |
| 400 | empty_name, name_too_long, invalid_code | lỗi tên nhóm, tên lịch mẫu, chưa nhập mã |
| 401 | missing_token, invalid_token, token_revoked | chưa đăng nhập, token hết hạn, đã đổi mật khẩu |
| 401 | wrong_credentials, google_account, invalid_refresh_token, invalid_google_token | lỗi đăng nhập |
| 403 | account_banned, account_deleted | tài khoản bị khoá hoặc đã xoá |
| 403 | not_allowed, admin_only | không đủ quyền |
| 404 | not_found, not_found_item | không tìm thấy |
| 409 | account_exists | trùng email hoặc nick_name |
| 409 | overlap, conflict | trùng giờ |
| 409 | tribe_limit, tribe_full, already_member, vice_limit, need_new_leader | luật của nhóm |
| 409 | limit_exceeded, duplicate | luật của lịch mẫu |
| 502 | upload_failed | Cloudinary lỗi |
| 503 | google_disabled, upload_disabled | thiếu cấu hình Firebase hoặc Cloudinary |

## 4. Danh sách API

Tiền tố chung: `http://localhost:8080/api/v1`. Cột "Token" là có cần đăng nhập hay không.

### Xác thực

| Mã CN | Method | URL | Token | Body |
|---|---|---|---|---|
| AU-01 | POST | /auth/register | không | `nick_name`, `email`, `password`, `confirm_password`, `timezone` (tuỳ chọn) |
| AU-02 | POST | /auth/login | không | `identifier` (email hoặc nick_name), `password`, `remember_me`, `fcm_token` (có thì lưu, không thì để trống), `device_info` |
| AU-03 | POST | /auth/google | không | `id_token` (Firebase ID token), `fcm_token` (có thì lưu, không thì để trống), `device_info`, `timezone` |
| | POST | /auth/refresh | không | `refresh_token` |
| AU-04 | POST | /auth/forgot-password | không | `email` |
| AU-04 | POST | /auth/reset-password | không | `token`, `new_password`, `confirm_password` |
| AU-05 | PUT | /auth/change-password | có | `current_password`, `new_password`, `confirm_password` |
| AU-06 | POST | /auth/logout | có | không cần body, server xoá phiên của access token đang dùng và đặt `fcm_token` về null |

### Hồ sơ, thiết bị, xoá tài khoản

| Mã CN | Method | URL | Body |
|---|---|---|---|
| INFO-01 | GET | /users/me | |
| INFO-01, INFO-04 | PATCH | /users/me | `nick_name`, `email`, `timezone` (gửi trường nào sửa trường đó) |
| INFO-02, INFO-03 | POST | /users/me/avatar | form-data `avatar` (file ảnh, tối đa 5MB) |
| | PUT | /users/me/fcm-token | `fcm_token` (khi Firebase cấp mã mới) |
| | DELETE | /users/me/fcm-token | |
| AU-07 | GET | /users/me/delete-preview | |
| AU-07 | DELETE | /users/me | `reason` (tối đa 255 ký tự) |

### Lịch cá nhân

| Mã CN | Method | URL | Body / Query |
|---|---|---|---|
| PT-03 | GET | /schedule | `?date=YYYY-MM-DD&filter=all\|personal\|group` |
| PT-03 | GET | /schedule/counts | `?from=YYYY-MM-DD&to=YYYY-MM-DD` |
| | GET | /timeblocks | `?date=` hoặc `?from=&to=` |
| | GET | /timeblocks/:id | |
| PT-01 | POST | /timeblocks | `task`, `description`, `date`, `start_time`, `end_time`, `color_code`, `remind`, `repeating_dates` |
| PT-02 | PUT | /timeblocks/:id | như trên |
| PT-04 | DELETE | /timeblocks/:id | |

### Lịch mẫu

| Mã CN | Method | URL | Body |
|---|---|---|---|
| TP-01 | GET | /templates | |
| | GET | /templates/:id | |
| TP-02 | POST | /templates | `template_name`, `blocks[]` |
| TP-04, TP-05, TP-07 | PUT | /templates/:id | `template_name` và/hoặc `blocks[]` (thay toàn bộ) |
| TP-06 | DELETE | /templates/:id | |
| TP-08 | POST | /templates/:id/share | trả `share_code` |
| | GET | /templates/shared/:code | |
| TP-03 | POST | /templates/import | `share_code` (không phân biệt hoa thường) |
| TP-09 | POST | /templates/:id/apply | `day_indexes`, `weeks` (1-12), `replace_conflicts`, `dry_run` |

Mỗi phần tử `blocks[]`: `day_index` (1 thứ Hai ... 7 Chủ nhật), `title`, `description`, `start_time`, `end_time`, `color_code`, `remind`.

### Nhóm

| Mã CN | Method | URL | Body / Query |
|---|---|---|---|
| COM-01 | GET | /tribes | |
| COM-03 | POST | /tribes | `name` |
| COM-11 | POST | /tribes/join | `invite_code` (không phân biệt hoa thường) |
| COM-02 | GET | /tribes/:id | |
| COM-05 | PATCH | /tribes/:id | `name` |
| COM-06 | DELETE | /tribes/:id | |
| COM-12, COM-13 | POST | /tribes/:id/leave | `new_leader_id` (bắt buộc nếu là trưởng nhóm và còn người khác) |
| COM-18 | GET | /tribes/:id/invite | |
| COM-14 | DELETE | /tribes/:id/members/:userId | |
| COM-15, COM-16, COM-17 | PATCH | /tribes/:id/members/:userId/role | `role`: `vice_leader` (bổ nhiệm), `member` (bãi nhiệm), `leader` (chuyển quyền) |
| COM-08 | GET | /tribes/:id/blocks | `?date=` (theo giờ người xem) hoặc `?from=&to=` |
| COM-07, COM-08 | GET | /tribes/:id/availability | `?date=` |
| COM-07, COM-08 | GET | /tribes/:id/busy | `?from=&to=` (tối đa 62 ngày), app dùng để tô màu cả dải ngày |
| COM-07 | POST | /tribes/:id/blocks | `task`, `description`, `color_code` và giờ UTC: `date` + `start_time` + `end_time`, hoặc `start_utc` + `end_utc` |
| | GET | /tribe-blocks/:id | |
| COM-09 | PUT | /tribe-blocks/:id | các trường như khi tạo, gửi trường nào sửa trường đó |
| COM-10 | DELETE | /tribe-blocks/:id | |
| COM-19 | PUT | /tribe-blocks/:id/attendance | `status`: `accepted` hoặc `declined` |

### Thông báo

| Mã CN | Method | URL | Query |
|---|---|---|---|
| NOTI-01 | GET | /notifications | `?filter=all\|personal\|<tribe_id>` |
| | GET | /notifications/unread-count | |
| NOTI-02 | PATCH | /notifications/:id/read | |
| NOTI-02 | PATCH | /notifications/read-all | |

### Admin (đăng nhập admin@timetribe.com)

| Method | URL | Body |
|---|---|---|
| POST | /admin/notifications/broadcast | `title`, `content` |
| PATCH | /admin/users/:id/ban | `is_banned`, `ban_reason` |

Ngoài ra `GET http://localhost:8080/health` để kiểm tra server.

## 5. Ví dụ request và kết quả

### Đăng nhập

```
POST /auth/login
{
  "identifier": "tuyetnga@timetribe.app",
  "password": "123456",
  "remember_me": true,
  "device_info": "Postman"
}
```

```json
{
  "success": true,
  "message": "Đăng nhập thành công",
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "5b0c9f...",
    "token_type": "Bearer",
    "expires_in": 3600,
    "user": {
      "id": "7cd8a455-438d-5402-a4d1-004f816dbeca",
      "email": "tuyetnga@timetribe.app",
      "nick_name": "Tuyết Nga",
      "avatar_url": null,
      "timezone": "Asia/Ho_Chi_Minh",
      "fcm_token": null,
      "role": "customer",
      "auth_provider": "local",
      "has_password": true
    }
  }
}
```

`remember_me = true` thì refresh token sống 30 ngày, không thì 7 ngày. Access token sống 60 phút.

### Tạo lịch cá nhân kèm nhân bản

```
POST /timeblocks
{
  "task": "Học tiếng Nhật",
  "description": "Bài 5 Minna no Nihongo",
  "date": "2026-11-06",
  "start_time": "06:00",
  "end_time": "07:00",
  "color_code": "#9B5DE5",
  "remind": 10,
  "repeating_dates": ["2026-11-07", "2026-11-08"]
}
```

Kết quả trả `timeblock` (bản gốc, `repeating_dates` là các ngày đã nhân bản thành công), `copies` (các bản sao)
và `skipped_dates` (ngày quá khứ hoặc ngày đã có lịch trùng giờ nên bị bỏ qua).

Quy tắc kiểm tra giống form trên app: tên 2-100 ký tự, ghi chú tối đa 300 ký tự, không chọn ngày quá khứ,
kết thúc sau bắt đầu ít nhất 5 phút, `remind` thuộc 0, 5, 10, 15, 30, 60, không trùng giờ hoạt động khác cùng ngày.

### Lịch trang chủ

```
GET /schedule?date=2026-11-05&filter=all
```

```json
{
  "date": "2026-11-05",
  "timezone": "Asia/Ho_Chi_Minh",
  "filter": "all",
  "personal": [ { "task": "Tập Gym", "start_time": "17:30:00", "end_time": "19:00:00" } ],
  "group": [
    {
      "task": "Họp chốt tiến độ",
      "date": "2026-11-05", "start_time": "13:00:00", "end_time": "14:00:00",
      "start_utc": "2026-11-05T13:00:00Z", "end_utc": "2026-11-05T14:00:00Z",
      "local_date": "2026-11-05", "local_start_time": "20:00:00", "local_end_time": "21:00:00",
      "my_status": "accepted",
      "tribe_name": "Đồ án NIC"
    }
  ],
  "total": 2
}
```

Hoạt động nhóm lưu theo UTC (`date`, `start_time`, `end_time`), server trả thêm giờ đã đổi sang múi giờ
của người xem (`local_*`). Hoạt động mình đã từ chối thì không hiện trên lịch cá nhân.

### Áp dụng lịch mẫu

Bước 1, xem trước:

```
POST /templates/7f9dbda9-b0e7-5bc7-8fa0-9aebd6947c6c/apply
{ "day_indexes": [1, 3, 5], "weeks": 2, "dry_run": true }
```

Bước 2, áp dụng thật. Nếu có trùng giờ mà chưa gửi `replace_conflicts` thì nhận 409 `conflict`,
`details` có `conflict_count` và `conflict_dates` để app hiện hộp thoại "Thay thế & Thêm".
Đồng ý thì gửi lại:

```
{ "day_indexes": [1, 3, 5], "weeks": 2, "replace_conflicts": true }
```

Kết quả: `{ "added": 6, "overwritten": 6, "conflict_dates": [...] }`.

### Tạo hoạt động nhóm

Giờ gửi lên là UTC. Ví dụ 14:00 giờ Việt Nam = 07:00 UTC:

```
POST /tribes/7bc48d74-1b52-5485-ad17-bc82aeda2cf3/blocks
{
  "task": "Họp thiết kế CSDL",
  "description": "Chốt 11 bảng",
  "date": "2026-11-06",
  "start_time": "07:00:00",
  "end_time": "08:00:00",
  "color_code": "#3A86FF"
}
```

Hoặc gửi `"start_utc": "2026-11-06T07:00:00Z", "end_utc": "2026-11-06T08:00:00Z"`.
Người tạo được ghi `accepted`, các thành viên khác `pending` và nhận thông báo `tribeNewBlock`.
Kết quả kèm `busy_member_ids` là những ai đang bận đúng khung giờ đó.

### Giờ rảnh của nhóm

```
GET /tribes/7bc48d74-1b52-5485-ad17-bc82aeda2cf3/availability?date=2026-11-06
```

Trả `members[].busy` (các khoảng bận theo UTC, không lộ tên lịch riêng), `segments` (chia ngày thành
các đoạn, mỗi đoạn biết ai bận) và `free_windows` (các khoảng từ 30 phút trở lên cả nhóm cùng rảnh,
có sẵn `start_local`, `end_local` theo giờ người xem).

### Thông báo

```json
{
  "id": "...",
  "user_id": "7cd8a455-438d-5402-a4d1-004f816dbeca",
  "created_by": "97e3da5a-2292-5473-bdbd-ba40f7686a7e",
  "title": "tribeNewBlock",
  "content": "{\"actor\":\"Mai Võ\",\"task\":\"Đánh cầu tối\",\"tribe\":\"CLB Cầu lông Q7\",\"tribe_id\":\"64f48035-...\"}",
  "type": "group_schedule",
  "reference_id": "57803b3e-f100-535d-bbce-3388f17cdfed",
  "reference_type": "tribe_block",
  "is_read": false,
  "created_at": "2026-11-04T21:00:00Z",
  "kind": "tribeNewBlock",
  "args": { "actor": "Mai Võ", "task": "Đánh cầu tối", "tribe": "CLB Cầu lông Q7", "tribe_id": "64f48035-..." },
  "tribe_id": "64f48035-9cc0-59d7-adf1-66ba31c05d2e"
}
```

Đúng như ghi chú trong `tribe_viewmodel.dart`: `title` là loại thông báo (trùng tên enum `NotificationKind`),
`content` là JSON tham số để app tự dựng câu theo ngôn ngữ đang chọn. Server parse sẵn ra `kind`, `args`, `tribe_id`.
Thông báo push (FCM) thì server dựng sẵn câu tiếng Việt.

## 6. Kịch bản test gợi ý

Chạy lần lượt các folder trong collection, mỗi folder đã sắp sẵn thứ tự:

1. Folder 1: đăng ký, các trường hợp đăng nhập lỗi, làm mới token, quên mật khẩu, đổi mật khẩu, đăng xuất.
2. Folder 2: sửa hồ sơ rồi trả lại như cũ, xem trước khi xoá tài khoản, xoá tài khoản Quốc Bảo vừa đăng ký.
3. Folder 3: xem lịch trang chủ, tạo lịch có nhân bản, thử trùng giờ và ngày quá khứ, sửa, xoá.
4. Folder 4: tạo, sửa, đổi tên, chia sẻ, nhập, áp dụng lịch mẫu.
5. Folder 5: tham gia nhóm (thành công, đủ người, đã ở trong nhóm), tạo nhóm, đổi tên, đổi màu, bổ nhiệm, bãi nhiệm,
   mời rời nhóm, rời nhóm, giải tán.
6. Folder 6: xem giờ rảnh, tạo hoạt động nhóm, đổi tài khoản Minh và An để trả lời, quay lại Nga xem thông báo,
   đổi giờ (mọi người về `pending`), huỷ hoạt động, cuối cùng chuyển quyền trưởng nhóm cho Minh.
7. Folder 7: lọc thông báo, đếm chưa đọc, đánh dấu đã đọc.
8. Folder 8: đăng nhập admin, gửi thông báo chung, khoá và mở khoá tài khoản.

Muốn thử thủ công một trường hợp, ví dụ thành viên thường không được tạo hoạt động nhóm:
chạy request "Đăng nhập An Lê (thành viên)" rồi gọi `POST /tribes/{{tribeNic}}/blocks`, kết quả 403 `not_allowed`.

## 7. Test Firebase và Cloudinary

### Đăng nhập Google (AU-03)

Server nhận Firebase ID token (app lấy bằng `await FirebaseAuth.instance.currentUser!.getIdToken()` sau khi
đăng nhập Google qua Firebase Auth), xác thực bằng Firebase Admin SDK.

Cần bật Google trong Firebase Console > Authentication > Sign-in method.

Cách lấy token để test trên Postman không cần app:

1. Vào https://developers.google.com/oauthplayground, ô bên trái chọn
   "Google OAuth2 API v2" > tick `userinfo.email` và `userinfo.profile`, bấm Authorize APIs, đăng nhập Google,
   bấm "Exchange authorization code for tokens", copy `access_token`.
2. Trong Postman gọi:

```
POST https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=AIzaSyAMGNLPOK8EegPmDx2DvnwyCsJNXWAy2x0
{
  "postBody": "access_token=<access_token vừa copy>&providerId=google.com",
  "requestUri": "http://localhost",
  "returnIdpCredential": true,
  "returnSecureToken": true
}
```

3. Copy giá trị `idToken` trong kết quả, dán vào biến `firebaseIdToken` của collection, chạy request "AU-03 Đăng nhập Google".
   Lần đầu sẽ tạo tài khoản mới (`auth_provider = google`), nếu email đã có tài khoản thường thì gắn `google_id` vào tài khoản đó.

Firebase ID token chỉ sống 1 giờ, hết hạn thì lấy lại.

### Thông báo đẩy (FCM)

1. Trên app gọi `await FirebaseMessaging.instance.getToken()`, dán kết quả vào biến `fcmToken`.
2. Đăng nhập (thường hoặc Google) với `"fcm_token": "{{fcmToken}}"` trong body, server lưu vào `users.fcm_token`.
   Đăng nhập mà không gửi `fcm_token` thì cột này để null. Khi Firebase cấp mã mới thì app gọi `PUT /users/me/fcm-token`.
3. Dùng tài khoản khác làm một việc liên quan (ví dụ Minh tạo hoạt động trong nhóm NIC) là máy nhận được push.
   Admin gửi thông báo chung thì mọi máy đã đăng ký đều nhận (topic `all_users`).
4. Nhắc lịch: tạo lịch cá nhân bắt đầu sau vài phút với `remind = 0`, tới giờ sẽ có thông báo `personalReminder`.

Mỗi tài khoản chỉ đăng nhập trên một máy và giữ một `fcm_token`. Máy đã đăng xuất mà tài khoản khác đăng nhập
thì mã được chuyển sang tài khoản mới. Đăng xuất, xoá tài khoản hoặc mã không còn hiệu lực khi gửi thì `fcm_token` về null.

### Tải ảnh lên Cloudinary

Request "INFO-02/03 Cập nhật ảnh đại diện": tab Body chọn form-data, key `avatar`, đổi kiểu từ Text sang File,
chọn ảnh. Kết quả `avatar_url` là link `https://res.cloudinary.com/dfdxbssos/...`.
File không phải ảnh trả 400 `invalid_file`, ảnh quá 5MB trả `file_too_large`.

## 8. Một tài khoản một máy

- Mỗi lần đăng nhập (thường hoặc Google), server xoá mọi phiên cũ của tài khoản đó. Máy đang đăng nhập trước
  sẽ nhận lỗi 401 `session_ended` ở request kế tiếp, app tự xoá dữ liệu trên máy và quay về màn hình đăng nhập.
- Access token mang theo id của phiên (claim `jti`), middleware kiểm tra phiên đó còn trong `user_tokens` không.
- Làm mới token (`/auth/refresh`) giữ nguyên phiên, chỉ đổi chuỗi refresh token.
- Đăng xuất xong thì máy đó đăng nhập tài khoản khác bình thường. App xoá token, hồ sơ, cài đặt múi giờ và bảng màu
  trên máy, chỉ giữ ngôn ngữ và chế độ sáng tối vì đó là cài đặt của máy.

Thử trên Postman: chạy "AU-02 Đăng nhập Tuyết Nga", copy `accessToken` cũ ra một chỗ, chạy lại request đăng nhập lần nữa,
rồi gọi `GET /users/me` với token cũ sẽ nhận `session_ended`.
