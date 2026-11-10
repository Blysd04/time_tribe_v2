# Hướng dẫn publish TimeTribe

Backend lên **Render**, database **MongoDB Atlas**, app Android phát hành dạng **APK**, kèm **landing page** để tải.

```
Người dùng ──> https://timetribe-api.onrender.com/            Landing page, nút "Tải APK"
                                              /download        ──> APK_URL (GitHub Releases)
App Android ──> https://timetribe-api.onrender.com/api/v1/... ──> MongoDB Atlas
                         │
                         ├──> Firebase  (đăng nhập Google, thông báo đẩy FCM)
                         ├──> Cloudinary (ảnh đại diện)
                         └──> Gmail SMTP (email quên mật khẩu, xác nhận đổi email)
```

Làm lần lượt từ bước 0 đến bước 10. Mỗi bước có phần **Kiểm tra** để biết đã làm đúng trước khi sang bước sau.

> **Quy tắc bí mật.** Mọi mật khẩu và key chỉ nhập vào trang Environment của Render, hoặc lưu trong file nằm trong
> `.gitignore` ở máy bạn. **Không bao giờ** commit hay gửi các file sau qua chat:
> `.env`, `serviceAccountKey.json`, `google-services.json`, `key.properties`, `*.jks`.

---

## Bước 0. Chuẩn bị

### 0.1. Tài khoản cần có (đều miễn phí)

| Dịch vụ | Dùng để | Đăng ký |
|---|---|---|
| GitHub | Chứa code; Render lấy code từ đây; chứa file APK | github.com |
| MongoDB Atlas | Database | cloud.mongodb.com |
| Render | Chạy backend và landing page | render.com (đăng nhập bằng GitHub cho nhanh) |
| Firebase | Đăng nhập Google, thông báo đẩy | console.firebase.google.com (dự án đang dùng) |
| Cloudinary | Lưu ảnh đại diện | cloudinary.com (tài khoản đang dùng) |
| Gmail | Gửi email | Một Gmail riêng cho app, ví dụ `timetribe.noreply@gmail.com` |
| cron-job.org | Giữ server không ngủ (bước 6) | cron-job.org |

### 0.2. Phần mềm trên máy tính

- **Git**, **Go 1.23+**, **Flutter** (bản đang dùng để chạy app), **Android Studio**.
- **JDK 17**: có sẵn trong Android Studio, dùng cho lệnh `keytool`.
  - Windows: `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`
  - macOS: `/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool`

### 0.3. Bảng key sẽ lập (điền dần khi làm)

| Biến trên Render | Lấy ở bước | Ghi chú |
|---|---|---|
| `MONGO_URI` | 1 | Chuỗi kết nối Atlas |
| `JWT_SECRET` | 2.1 | Render tự sinh nếu dùng Blueprint |
| `FIREBASE_CREDENTIALS_JSON` | 2.2 | Service account dạng base64 |
| `CLOUDINARY_URL` | 2.4 | `cloudinary://...` |
| `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM` | 2.5 | Mật khẩu ứng dụng Gmail |
| `APK_URL` | 8 | Link file APK |

---

## Bước 1. MongoDB Atlas

Bạn đã có một cluster đang dùng, có thể dùng chung. Dữ liệu TimeTribe nằm trong database riêng tên `timetribe`,
không đụng tới dữ liệu khác. Muốn tách hẳn thì tạo cluster mới theo mục 1.1; dùng cluster cũ thì bỏ qua 1.1.

### 1.1. (Tuỳ chọn) Tạo cluster mới

1. Vào cloud.mongodb.com → **Create** → chọn **M0 (Free)**.
2. Provider **AWS**, region **Singapore (ap-southeast-1)**. Cùng khu vực với Render ở bước 5 nên truy vấn nhanh hơn.
3. Đặt tên `timetribe` → **Create Deployment**.

### 1.2. Tạo user cho database

1. Menu trái **Security → Database Access** → **Add New Database User**.
2. Authentication Method: **Password**.
   - Username: `timetribe_app`
   - Password: bấm **Autogenerate Secure Password** → **Copy** và lưu lại.
3. **Database User Privileges** → **Built-in Role** → **Read and write to any database**.
4. **Add User**.

> Mật khẩu của user cũ đã lộ trong chat. Nếu vẫn dùng user cũ thì vào **Edit → Edit Password** để đổi.

### 1.3. Mở mạng cho Render

1. **Security → Network Access** → **Add IP Address**.
2. Bấm **Allow Access from Anywhere** (`0.0.0.0/0`) → **Confirm**.
   IP của Render free thay đổi liên tục nên không whitelist từng IP được. Bảo mật dựa vào user và mật khẩu mạnh ở 1.2.

### 1.4. Lấy chuỗi kết nối

1. **Database → Clusters** → nút **Connect** của cluster → **Drivers** → Driver **Go**.
2. Copy chuỗi dạng:

```
mongodb+srv://timetribe_app:<db_password>@<ten-cluster>.<ma>.mongodb.net/?retryWrites=true&w=majority&appName=<ten-cluster>
```

3. Thay `<db_password>` bằng mật khẩu ở 1.2. Nếu mật khẩu có ký tự đặc biệt thì phải **mã hoá URL**:

| Ký tự | Viết thành |
|---|---|
| `@` | `%40` |
| `:` | `%3A` |
| `/` | `%2F` |
| `?` | `%3F` |
| `#` | `%23` |
| `%` | `%25` |

   Mật khẩu tự sinh của Atlas chỉ gồm chữ và số nên không cần mã hoá.
4. Đây là giá trị của **`MONGO_URI`**. Không cần ghi tên database vào chuỗi, vì biến `DB_NAME=timetribe` đã lo phần đó.

**Kiểm tra** từ máy tính, trong thư mục `backend`. Lệnh đầu cho macOS/Linux, lệnh sau cho Windows PowerShell:

```bash
MONGO_URI='mongodb+srv://...' go run ./cmd/server
```

```powershell
$env:MONGO_URI='mongodb+srv://...'; go run ./cmd/server
```

Thấy dòng `TimeTribe API đang chạy` là kết nối được. Bấm Ctrl+C để tắt.
Nếu báo `không ping được MongoDB` thì xem lại mục 1.3 và mật khẩu.

### 1.5. (Tuỳ chọn) Nạp dữ liệu mẫu lên Atlas

Dữ liệu mẫu tiện cho demo. **Seed xoá sạch database `timetribe`**, nên chỉ chạy khi chưa có người dùng thật.

```bash
MONGO_URI='mongodb+srv://...' go run ./cmd/seed
```

---

## Bước 2. Lập các key

### 2.1. `JWT_SECRET`

Chuỗi ký token đăng nhập. Ai có chuỗi này là giả được token, nên phải ngẫu nhiên và dài từ 32 ký tự trở lên.
Server **từ chối chạy** ở chế độ production nếu chuỗi ngắn hơn.

- **Dùng Blueprint ở bước 5:** Render tự sinh, không cần làm gì.
- **Tự tạo:** chạy một trong hai lệnh dưới.

```bash
openssl rand -base64 48
```

```powershell
[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }))
```

Đổi `JWT_SECRET` sẽ đăng xuất mọi người dùng, vì token cũ không còn hợp lệ.

### 2.2. Firebase service account → `FIREBASE_CREDENTIALS_JSON`

Backend dùng khoá này để xác minh đăng nhập Google và gửi thông báo đẩy.

1. console.firebase.google.com → chọn dự án TimeTribe → ⚙️ **Project settings** → tab **Service accounts**.
2. **Generate new private key** → **Generate key**. Máy tải về một file `.json`, đổi tên thành `serviceAccountKey.json`.
3. **Thu hồi key cũ đã lộ trong chat:**
   1. Cùng tab đó, bấm **Manage service account permissions** (mở Google Cloud Console).
   2. Chọn service account `firebase-adminsdk-...` → tab **Keys**.
   3. Xoá các key cũ, chỉ giữ key vừa tạo.
4. Chuyển file sang base64 một dòng, chạy lệnh đúng hệ điều hành:

```bash
base64 -w0 serviceAccountKey.json > sa.b64.txt
```

```bash
base64 -i serviceAccountKey.json | tr -d '\n' > sa.b64.txt
```

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("serviceAccountKey.json")) | Set-Content -NoNewline sa.b64.txt
```

   Lệnh đầu cho Linux, lệnh thứ hai cho macOS, lệnh cuối cho Windows.
   Mở `sa.b64.txt`, copy toàn bộ: đó là giá trị **`FIREBASE_CREDENTIALS_JSON`**. Dán xong vào Render thì **xoá `sa.b64.txt`**.
5. Kiểm tra Firebase đã bật đủ:
   - **Build → Authentication → Sign-in method**: **Google** ở trạng thái *Enabled*.
   - **Project settings → Cloud Messaging**: *Firebase Cloud Messaging API (V1)* ở trạng thái *Enabled*.

### 2.3. Khoá ký APK và mã SHA cho đăng nhập Google

Mỗi APK phải được ký. Google chỉ cho đăng nhập nếu mã SHA của khoá ký đã khai báo trong Firebase.

1. Tạo khoá. Chỉ làm **một lần**, và **sao lưu file .jks cùng mật khẩu** (Google Drive cá nhân, USB):
   mất file này thì không cập nhật được app cho người đã cài.

```bash
keytool -genkey -v -keystore timetribe-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias timetribe
```

   Máy hỏi mật khẩu kho, họ tên, đơn vị... Điền tuỳ ý, chỉ cần nhớ mật khẩu.
   Đặt file `.jks` **ngoài thư mục repo**, ví dụ `C:\keys\timetribe-release.jks`.

2. Tạo file `time_tribe_v2/android/key.properties`. File này đã nằm trong `.gitignore`.
   Trên Windows dùng dấu `/` hoặc `\\` trong đường dẫn.

```
storePassword=<mật khẩu kho>
keyPassword=<mật khẩu khoá, thường giống mật khẩu kho>
keyAlias=timetribe
storeFile=C:/keys/timetribe-release.jks
```

3. Lấy mã SHA-1 và SHA-256:

```bash
keytool -list -v -keystore timetribe-release.jks -alias timetribe
```

4. Firebase → ⚙️ **Project settings** → **General** → kéo xuống app Android `com.example.time_tribe_v2`
   → **Add fingerprint**. Dán **SHA-1**, rồi **Add fingerprint** lần nữa để dán **SHA-256**.
   Giữ nguyên các fingerprint debug đang có để vẫn chạy được `flutter run`.
5. Bấm **google-services.json** để tải bản mới, chép đè vào `time_tribe_v2/android/app/google-services.json`.

### 2.4. Cloudinary → `CLOUDINARY_URL`

1. cloudinary.com → **Settings** (⚙️) → **API Keys**.
2. Key cũ đã lộ trong chat, nên bấm **Generate New API Key**, rồi xoá hoặc vô hiệu key cũ.
3. Ghép thành: `cloudinary://<API Key>:<API Secret>@<Cloud name>`. Cloud name xem ở góc trên trang Dashboard.

### 2.5. Gmail SMTP → `SMTP_*`

Bắt buộc phải có thì mới gửi được email **quên mật khẩu** và **xác nhận đổi email**.

1. Đăng nhập Gmail sẽ dùng để gửi → myaccount.google.com → **Bảo mật**.
2. Bật **Xác minh 2 bước**. Đây là điều kiện để tạo mật khẩu ứng dụng.
3. Tìm **Mật khẩu ứng dụng** (App passwords) → đặt tên `TimeTribe` → **Tạo**.
   Google hiện mã 16 ký tự: bỏ dấu cách, đó là `SMTP_PASS`.
4. Các biến cần điền:

| Biến | Giá trị |
|---|---|
| `SMTP_HOST` | `smtp.gmail.com` |
| `SMTP_PORT` | `587` (Blueprint đã điền) |
| `SMTP_USER` | địa chỉ Gmail đó |
| `SMTP_PASS` | mật khẩu ứng dụng 16 ký tự |
| `SMTP_FROM` | địa chỉ Gmail đó |

Gmail miễn phí gửi được khoảng 500 email/ngày, đủ cho đồ án.

---

## Bước 3. Đưa code lên GitHub

Render và người dùng đều lấy từ nhánh `main`.

1. Gộp nhánh `claude/brave-allen-9xgnqv` vào `main`: tạo Pull Request trên GitHub rồi **Merge**,
   hoặc chạy hai lệnh dưới ở máy:

```bash
git checkout main && git pull
```

```bash
git merge claude/brave-allen-9xgnqv && git push origin main
```

2. Kiểm tra trên GitHub không có các file bí mật:
   - Không thấy `backend/.env` hay `serviceAccountKey.json`.
   - Có thấy `render.yaml` ở gốc repo.
3. Repo **public hay private**:
   - Render chạy được cả repo private (cấp quyền ở bước 5).
   - Muốn để **APK trên GitHub Releases** cho người ngoài tải thì repo phải **public**. Repo private thì dùng Google Drive (bước 8.2).

---

## Bước 4. Kiểm tra lần cuối ở máy (tuỳ chọn, nên làm)

Nếu máy có Docker, chạy thử đúng image Render sẽ chạy. Trong thư mục `backend`:

```bash
docker build -t timetribe-api .
```

```bash
docker run --rm --env-file .env -e APP_ENV=development -p 8080:8080 timetribe-api
```

Mở `http://localhost:8080/` thấy landing page, mở `http://localhost:8080/health` thấy `"status":"ok"`.

---

## Bước 5. Deploy backend lên Render

### Cách A: dùng Blueprint (khuyên dùng)

Repo đã có sẵn `render.yaml` khai báo toàn bộ service.

1. dashboard.render.com → **New +** → **Blueprint**.
2. **Connect GitHub**: cho phép Render đọc repo `time_tribe_v2`. Repo private thì chọn *Only select repositories* và tick repo này.
3. Chọn repo, branch `main`. Đặt **Blueprint Name** `timetribe` → **Apply** (hoặc **Deploy Blueprint**).
4. Render hỏi các biến `sync: false`. Điền theo bảng ở mục 0.3:
   - `MONGO_URI`, `FIREBASE_CREDENTIALS_JSON`, `CLOUDINARY_URL`
   - `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`
   - `APK_URL`: chưa có thì tạm điền `https://github.com`, sửa lại ở bước 8.
5. **Apply**. Render build Docker image (lần đầu 3–6 phút) rồi chạy.

### Cách B: tạo tay (nếu không dùng Blueprint)

1. **New +** → **Web Service** → chọn repo.
2. Điền các mục:
   - **Name:** `timetribe-api`
   - **Region:** Singapore
   - **Branch:** `main`
   - **Language/Runtime:** Docker
   - **Root Directory:** `backend`
   - **Instance Type:** Free
3. **Advanced** → **Health Check Path** = `/health`.
4. **Environment Variables**: thêm `APP_ENV=production`, `DB_NAME=timetribe`, `ENABLE_REMINDER=true`, `JWT_SECRET` (bước 2.1)
   và các biến ở mục 0.3. Mẫu đầy đủ ở `backend/.env.production.example`.
5. **Create Web Service**.

### Kiểm tra

1. Tab **Logs** có các dòng:

```
đã kết nối Firebase
đã bật bộ nhắc lịch, quét đầu mỗi phút
TimeTribe API đang chạy tại https://timetribe-api.onrender.com (db: timetribe)
```

2. Mở `https://timetribe-api.onrender.com/health`. Phải có `"status":"ok"`, `"firebase_auth":true`, `"firebase_push":true`.
3. Mở `https://timetribe-api.onrender.com/` thấy landing page.

> **Nếu Render cấp domain khác** (vì tên `timetribe-api` đã có người dùng, ví dụ `timetribe-api-x1y2.onrender.com`),
> phải đổi domain ở 2 chỗ trước khi build APK:
> - `time_tribe_v2/lib/core/api/api_config.dart` → `productionUrl`
> - `backend/internal/handlers/web/landing.html` → các link `.../download` (tìm `onrender.com`)
>
> Sửa xong thì commit và push để Render tự deploy lại.

Mỗi lần push lên `main` có thay đổi trong `backend/`, Render tự build và deploy lại.

---

## Bước 6. Giữ server không ngủ

Gói Free của Render **tắt server sau 15 phút không có request**. Khi server ngủ:
- **bộ nhắc lịch cũng dừng**, nên không có thông báo đẩy;
- request đầu tiên sau đó phải chờ khoảng 30–60 giây để server khởi động lại.

Cách xử lý: dùng dịch vụ gọi `/health` mỗi 10 phút.

1. cron-job.org → **Create cronjob**.
2. Điền:
   - **Title:** `TimeTribe keep-alive`
   - **URL:** `https://timetribe-api.onrender.com/health`
   - **Execution schedule:** Every **10 minutes**
3. **Create**. Sau vài lần chạy, mục History phải báo `200 OK`.

Gói Free có 750 giờ chạy mỗi tháng, đủ cho 1 service chạy liên tục (khoảng 744 giờ).
Nếu lỡ ngủ, khi thức dậy server **nhắc bù** các lịch trong vòng 24 giờ: thông báo vẫn vào danh sách trong app,
nhưng không đẩy cho hoạt động đã bắt đầu.
Muốn chắc chắn không bao giờ ngủ thì nâng service lên gói **Starter** (trả phí).

---

## Bước 7. Build APK

Làm trong thư mục `time_tribe_v2`.

1. Kiểm tra `lib/core/api/api_config.dart`: `productionUrl` đúng domain Render, có `/api/v1` ở cuối.
2. Đặt phiên bản trong `pubspec.yaml`. Bản đầu là `version: 1.0.0+1`; mỗi lần phát hành **tăng số sau dấu `+`**
   (`1.0.1+2`, `1.0.2+3`...), nếu không thì máy không cài đè được.
3. Kiểm tra đã có `android/key.properties` (bước 2.3) và `android/app/google-services.json` bản mới.
4. Build:

```bash
flutter clean && flutter pub get
```

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://timetribe-api.onrender.com/api/v1
```

   File ra ở `build/app/outputs/flutter-apk/app-release.apk`, khoảng 50–60 MB, chạy được trên mọi điện thoại Android.
5. Kiểm tra APK đã ký bằng khoá phát hành, không phải khoá debug. Hai mã SHA-256 phải trùng nhau:

```bash
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

6. Cài thử lên điện thoại thật: gỡ bản debug cũ trước, vì khác chữ ký nên không cài đè được.
   Thử đăng ký, đăng nhập Google, Cài đặt → Trợ giúp → **Gửi thông báo thử**.

---

## Bước 8. Phát hành file APK

### 8.1. GitHub Releases (repo public)

1. Trên GitHub: repo → **Releases** → **Draft a new release**.
2. **Choose a tag** → gõ `v1.0.0` → **Create new tag**. Title: `TimeTribe 1.0.0`. Ghi chú: các thay đổi chính.
3. Kéo thả file APK vào ô **Attach binaries**, **đổi tên file thành `timetribe.apk`** trước khi kéo vào.
4. **Publish release**.
5. Link luôn trỏ tới bản mới nhất (thay `<owner>` bằng tên GitHub của bạn):

```
https://github.com/<owner>/time_tribe_v2/releases/latest/download/timetribe.apk
```

### 8.2. Google Drive (repo private)

1. Tải APK lên Drive → chuột phải → **Chia sẻ** → *Bất kỳ ai có đường liên kết* → **Người xem**.
2. Link chia sẻ có dạng `https://drive.google.com/file/d/<ID>/view`. Lấy phần `<ID>` và ghép thành:

```
https://drive.google.com/uc?export=download&id=<ID>
```

   File lớn, nên Drive sẽ hiện thêm trang "không quét được virus", người dùng bấm **Vẫn tải xuống**.

### 8.3. Gắn link vào server

Render → service `timetribe-api` → **Environment** → sửa `APK_URL` thành link ở 8.1 hoặc 8.2 → **Save Changes**.
Render tự khởi động lại.

**Kiểm tra:** mở `https://timetribe-api.onrender.com/download`, file APK phải bắt đầu tải.

---

## Bước 9. Landing page

Landing page đi kèm backend, không cần deploy riêng.

- Địa chỉ: `https://timetribe-api.onrender.com/`. Gửi link này cho người dùng.
- Nội dung trang ở `backend/internal/handlers/web/landing.html`; logo ở `logo.png` và `favicon.png` cùng thư mục.
  Sửa xong thì push, Render tự cập nhật.
- Nút "Tải APK" trỏ tới `/download`, server chuyển tiếp tới `APK_URL`. Ra bản mới chỉ cần đổi `APK_URL`
  (hoặc giữ nguyên nếu dùng link `releases/latest`), không phải sửa trang.
- Trang **đặt lại mật khẩu** cũng do backend phục vụ ở `/reset-password`; link trong email quên mật khẩu tự trỏ về đây.
- Bản xem trước trên claude.ai (https://claude.ai/artifact/MdmumehXtbCVBhccrNpYZD) là riêng tư. Muốn người khác xem
  thì bật chia sẻ trong menu Share, nhưng nên dùng link Render ở trên.

**Muốn dùng tên miền riêng** (ví dụ `timetribe.app`):
1. Render → service → **Settings → Custom Domains** → **Add**, rồi tạo bản ghi CNAME theo hướng dẫn hiện ra.
2. Thêm biến `BASE_URL=https://timetribe.app` để link trong email dùng tên miền mới.
3. Đổi `productionUrl` trong app rồi build lại APK.

---

## Bước 10. Kiểm tra sau khi publish

- [ ] `/health` trả `firebase_auth: true`, `firebase_push: true`.
- [ ] `/` hiện landing page có logo; nút **Tải APK** tải được file.
- [ ] Cài APK trên một điện thoại **khác** máy dev.
- [ ] Đăng ký tài khoản mới → thấy màn hình chào mừng và hướng dẫn.
- [ ] Đăng nhập Google được.
- [ ] Cài đặt → Trợ giúp → **Gửi thông báo thử** → có thông báo.
- [ ] Tạo lịch nhắc trước 5 phút, **tắt hẳn app** → tới giờ có thông báo.
- [ ] Đổi ảnh đại diện → ảnh hiện (Cloudinary).
- [ ] Hồ sơ → đổi email → email mới nhận link → bấm link thấy "Đã xác nhận email" → mở lại app thấy email mới.
- [ ] Đăng xuất → **Quên mật khẩu** → email có link → trang đặt lại mật khẩu → đăng nhập bằng mật khẩu mới.
- [ ] Atlas → **Browse Collections** → database `timetribe` có dữ liệu.
- [ ] cron-job.org báo `200 OK` đều đặn.

---

## Cập nhật về sau

| Thay đổi | Làm gì |
|---|---|
| Sửa backend hoặc landing page | Push lên `main`, Render tự deploy (xem tab **Events**) |
| Sửa app | Tăng `version` trong `pubspec.yaml` → build APK → tạo Release mới, tên file vẫn là `timetribe.apk` |
| Đổi key | Render → **Environment** → sửa → **Save Changes** (service tự khởi động lại) |
| Xem lỗi | Render → **Logs** |

---

## Lỗi thường gặp

| Hiện tượng | Nguyên nhân và cách xử lý |
|---|---|
| Build Render lỗi `failed to read dockerfile` | Cách B quên đặt **Root Directory** = `backend` |
| Log: `không ping được MongoDB` | Chưa mở `0.0.0.0/0` (bước 1.3), sai mật khẩu, hoặc mật khẩu có ký tự đặc biệt chưa mã hoá |
| Log: `APP_ENV=production cần JWT_SECRET ...` | `JWT_SECRET` trống hoặc dưới 32 ký tự |
| `/health` có `firebase_push: false` | `FIREBASE_CREDENTIALS_JSON` bị cắt khi dán, hoặc đã xoá nhầm key đang dùng. Tạo lại theo 2.2 |
| App báo không kết nối được máy chủ | Sai `productionUrl`, thiếu `/api/v1`, hoặc server đang ngủ (đợi 30–60 giây rồi thử lại) |
| Đăng nhập Google báo lỗi (mã 10 / `DEVELOPER_ERROR`) | Chưa thêm SHA-1/SHA-256 của khoá phát hành (2.3), hoặc chưa chép `google-services.json` mới rồi build lại |
| Không nhận email | Thiếu `SMTP_*`, sai mật khẩu ứng dụng, hoặc thư nằm trong Spam. Log ghi `gửi email thất bại` |
| Không có thông báo đẩy khi tắt app | Server ngủ (bước 6). Máy Xiaomi/Oppo/Vivo: bật **Tự khởi chạy**, pin **Không hạn chế** |
| `/download` báo "Chưa có file APK" | Chưa đặt `APK_URL` |
| Cài APK báo "Ứng dụng chưa được cài đặt" | Đang có bản ký khác (bản debug), gỡ bản cũ rồi cài lại |
| Người dùng cập nhật không cài đè được | Quên tăng số sau dấu `+` trong `version`, hoặc ký bằng khoá khác (mất file `.jks`) |
