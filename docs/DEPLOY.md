# Phát hành TimeTribe: backend trên Zeabur, database MongoDB Atlas, app dạng APK

```
Điện thoại (APK) ──HTTPS──> Zeabur (Docker, backend Go) ──TLS──> MongoDB Atlas
                                   └──> Firebase (FCM, đăng nhập Google), Cloudinary (ảnh)
```

> **Không commit** các file sau: `.env`, `serviceAccountKey.json`, `google-services.json`, `key.properties`, `*.jks`.
> Tất cả đã nằm trong `.gitignore`. Mật khẩu và khoá chỉ nhập vào phần Variables của Zeabur.

---

## Bước 1. MongoDB Atlas

1. Vào Atlas → **Database Access**, kiểm tra user `ngavdt125010122005` có quyền *Read and write to any database*.
   Nên đổi sang một mật khẩu mạnh hơn.
2. Vào **Network Access** → **Add IP Address** → chọn **Allow access from anywhere** (`0.0.0.0/0`).
   IP của Zeabur thay đổi nên không whitelist từng IP được.
3. Chuỗi kết nối sẽ dùng:

```
mongodb+srv://<user>:<password>@kidsenglishcluster.pa5mcec.mongodb.net/?retryWrites=true&w=majority
```

   Dữ liệu nằm trong database riêng `timetribe` (đặt bằng biến `DB_NAME`), không đụng tới dữ liệu khác trong cluster.
   Mật khẩu có ký tự đặc biệt (`@ : / ? #`) thì phải mã hoá URL, ví dụ `@` viết thành `%40`.

4. (Tuỳ chọn) Nạp dữ liệu mẫu lên Atlas, chạy từ máy tính:

```bash
cd backend
```

```bash
MONGO_URI='mongodb+srv://<user>:<password>@kidsenglishcluster.pa5mcec.mongodb.net/' go run ./cmd/seed
```

   ⚠️ Seed **xoá sạch** database `timetribe` rồi nạp lại. Chỉ chạy khi chưa có người dùng thật.

## Bước 2. Deploy backend lên Zeabur

1. Đẩy code lên GitHub (nhánh muốn deploy, ví dụ `main`).
2. Vào Zeabur:
   1. **Create Project** → chọn region gần người dùng (Singapore/Tokyo cho Việt Nam).
   2. **Add Service** → **Git** → chọn repo `time_tribe_v2`.
3. Trong service vừa tạo, vào **Settings**:
   - **Root Directory** = `backend`. Zeabur thấy `backend/Dockerfile` sẽ tự build bằng Docker.
   - Branch: chọn nhánh muốn deploy.
4. Mở tab **Variables** và thêm các biến dưới đây. Mẫu đầy đủ ở `backend/.env.production.example`.

| Biến | Giá trị |
|---|---|
| `APP_ENV` | `production` |
| `MONGO_URI` | chuỗi Atlas ở bước 1 |
| `DB_NAME` | `timetribe` |
| `JWT_SECRET` | chuỗi ngẫu nhiên ≥ 32 ký tự, tạo bằng `openssl rand -base64 48`. Server **từ chối chạy** nếu thiếu hoặc quá ngắn |
| `FIREBASE_CREDENTIALS_JSON` | nội dung `serviceAccountKey.json` mã hoá base64 (lệnh ở dưới bảng). Dán JSON thô cũng được |
| `CLOUDINARY_URL` | `cloudinary://<api_key>:<api_secret>@<cloud_name>` |
| `BASE_URL` | domain Zeabur ở bước 5, ví dụ `https://timetribe-api.zeabur.app` |
| `ENABLE_REMINDER` | `true` |
| `SMTP_*` | để trống nếu chưa gửi email |

   Lấy base64 của `serviceAccountKey.json` (chạy lệnh tuỳ hệ điều hành):

```bash
base64 -w0 serviceAccountKey.json
```

```bash
base64 -i serviceAccountKey.json
```

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("serviceAccountKey.json"))
```

   Lệnh đầu cho Linux, lệnh thứ hai cho macOS, lệnh cuối cho Windows PowerShell.
   Không cần đặt `PORT`, Zeabur tự cấp và server đọc biến này.

5. Mở tab **Networking** → **Generate Domain**, đặt tên `timetribe-api` để được `https://timetribe-api.zeabur.app`.
   Đặt tên khác thì nhớ sửa `productionUrl` ở bước 3.
6. Bấm **Redeploy**, xem tab **Logs**. Phải thấy các dòng:

```
đã kết nối Firebase
đã bật bộ nhắc lịch, quét đầu mỗi phút
TimeTribe API đang chạy tại https://timetribe-api.zeabur.app (db: timetribe)
```

7. Mở `https://timetribe-api.zeabur.app/health`. Kết quả đúng là `"status":"ok"`, `"firebase_auth":true`, `"firebase_push":true`.

> Chỉ chạy **1 instance**. Bộ nhắc lịch chạy chung trong server. Nếu lỡ chạy 2 instance cũng không gửi trùng,
> vì `reminder_logs` có khoá duy nhất cho mỗi lần nhắc.

### Chạy thử Docker ở máy (tuỳ chọn)

```bash
cd backend
```

```bash
docker build -t timetribe-api .
```

```bash
docker run --rm --env-file .env -e APP_ENV=development -p 8080:8080 timetribe-api
```

## Bước 3. Build APK cho người dùng tải

1. Mở `time_tribe_v2/lib/core/api/api_config.dart`, kiểm tra `productionUrl` đúng domain Zeabur.
   Bản release dùng địa chỉ này nếu không truyền `--dart-define`.
2. Tạo khoá ký bản phát hành. Chỉ làm **một lần**, và **giữ kỹ file .jks**: mất file thì không cập nhật được app cho người đã cài.

```bash
keytool -genkey -v -keystore ~/timetribe-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias timetribe
```

   Sau đó tạo file `time_tribe_v2/android/key.properties` (đã nằm trong `.gitignore`):

```
storePassword=<mật khẩu kho>
keyPassword=<mật khẩu khoá>
keyAlias=timetribe
storeFile=/đường/dẫn/tới/timetribe-release.jks
```

   Chưa có `key.properties` thì APK vẫn build được, nhưng ký bằng khoá debug.

3. **Đăng nhập Google với khoá mới.** Lấy SHA-1 và SHA-256 của khoá:

```bash
keytool -list -v -keystore ~/timetribe-release.jks -alias timetribe
```

   Thêm cả hai mã vào Firebase Console → Project settings → app Android `com.example.time_tribe_v2` → **Add fingerprint**.
   Tải lại `google-services.json`, chép vào `time_tribe_v2/android/app/`.
   Thiếu bước này thì nút "Đăng nhập Google" sẽ lỗi trên APK phát hành.

4. Mỗi lần phát hành, tăng phiên bản trong `pubspec.yaml`, ví dụ `version: 1.0.1+2`.
   Số sau dấu `+` phải tăng thì máy mới cài đè được bản cũ.
5. Build. Lệnh đầu tạo một file APK chạy được trên mọi điện thoại (khoảng 50 MB):

```bash
cd time_tribe_v2
```

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://timetribe-api.zeabur.app/api/v1
```

   File nằm ở `build/app/outputs/flutter-apk/app-release.apk`.
   Muốn file nhẹ hơn thì build tách theo loại CPU; hầu hết điện thoại hiện nay dùng file `app-arm64-v8a-release.apk`:

```bash
flutter build apk --release --split-per-abi --dart-define=API_BASE_URL=https://timetribe-api.zeabur.app/api/v1
```

6. Phát hành: đưa file APK lên **GitHub Releases** hoặc Google Drive (chế độ "Ai có link cũng xem được"), rồi gửi link.
   Người dùng tải về, cho phép "Cài ứng dụng không rõ nguồn gốc", cài đặt, rồi **cho phép thông báo** khi app hỏi.

## Bước 4. Kiểm tra sau khi phát hành

- [ ] `/health` trả `firebase_push: true`.
- [ ] Đăng ký tài khoản mới trên APK → thấy màn hình chào mừng.
- [ ] Đăng nhập Google được.
- [ ] Cài đặt → Trợ giúp → **Gửi thông báo thử** → có thông báo.
- [ ] Tạo lịch nhắc trước 5 phút → tới giờ có thông báo, kể cả khi đã tắt app.
- [ ] Đổi ảnh đại diện được (Cloudinary).
- [ ] Atlas → Browse Collections → database `timetribe` có dữ liệu mới.

## Lỗi thường gặp

| Hiện tượng | Cách xử lý |
|---|---|
| Log báo `không ping được MongoDB` | Chưa mở Network Access `0.0.0.0/0`, sai mật khẩu, hoặc mật khẩu có ký tự đặc biệt chưa mã hoá URL |
| Log báo `APP_ENV=production cần JWT_SECRET ...` | Đặt `JWT_SECRET` dài ≥ 32 ký tự |
| `/health` trả `firebase_push: false` | `FIREBASE_CREDENTIALS_JSON` sai hoặc bị cắt mất. Dán lại bản base64 một dòng |
| App báo không kết nối được | Sai domain trong `--dart-define` hoặc `productionUrl`, hoặc thiếu `/api/v1` ở cuối |
| Đăng nhập Google lỗi (mã 10) | Chưa thêm SHA-1/SHA-256 của khoá phát hành vào Firebase |
| Thông báo trễ khi app tắt hẳn (Xiaomi, Oppo...) | Bật "Tự khởi chạy" và "Không hạn chế pin" cho TimeTribe |
| Zeabur báo hết tài nguyên hoặc server ngủ | Gói miễn phí có giới hạn. Server ngủ thì bộ nhắc lịch dừng; khi chạy lại sẽ nhắc bù tối đa 24 giờ, nhưng không đẩy thông báo cho hoạt động đã bắt đầu |
