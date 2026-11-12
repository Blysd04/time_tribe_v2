# TimeTribe

Ứng dụng Android quản lý thời gian cá nhân và xếp lịch nhóm, kể cả khi các thành viên ở **nhiều múi giờ khác nhau**.
App tự tìm khung giờ cả nhóm cùng rảnh, nhắc lịch bằng thông báo đẩy, và cho chia sẻ lịch mẫu bằng mã.

- **Tải app:** https://timetribe.onrender.com/
- **Ngôn ngữ:** Tiếng Việt, English, Français
- **Nền tảng:** Android

---

## Mục lục

1. [Cài đặt app](#1-cài-đặt-app)
2. [Hướng dẫn sử dụng](#2-hướng-dẫn-sử-dụng)
3. [Câu hỏi thường gặp](#3-câu-hỏi-thường-gặp)
4. [Dành cho nhà phát triển](#4-dành-cho-nhà-phát-triển)

---

## 1. Cài đặt app

1. Trên điện thoại Android, mở https://timetribe.onrender.com/ rồi bấm **Tải APK**.
   Lần đầu mở trang có thể chờ 30–60 giây vì máy chủ miễn phí đang "ngủ".
2. Tải xong, mở file `timetribe.apk`.
3. Android hỏi **"Cho phép cài ứng dụng từ nguồn này"** → bật cho trình duyệt đang dùng (Chrome, Cốc Cốc...) → quay lại bấm **Cài đặt**.
4. Nếu Google Play Protect cảnh báo "ứng dụng không xác định" → **Chi tiết** → **Vẫn cài đặt**.
   App chưa lên Play Store nên Android luôn hỏi bước này.
5. Mở app, **cho phép thông báo** khi được hỏi. Không cho thì sẽ không nhận được nhắc lịch.

**Máy Xiaomi, Oppo, Vivo, Realme:** các hãng này hay tắt app chạy nền, làm mất thông báo. Vào
**Cài đặt điện thoại → Ứng dụng → TimeTribe**:

- Bật **Tự khởi chạy** (Autostart).
- **Tiết kiệm pin** → chọn **Không hạn chế**.
- **Thông báo** → bật **Thông báo nổi** và **Màn hình khoá**.

**Cập nhật bản mới:** tải APK mới từ trang trên rồi cài đè, dữ liệu vẫn giữ vì dữ liệu nằm trên máy chủ.

---

## 2. Hướng dẫn sử dụng

App có 5 tab ở thanh dưới: **Hồ sơ**, **Trang chủ**, nút **+** (thêm lịch), **Thông báo**, **Cài đặt**.
Ở Trang chủ, nút menu **☰** chuyển giữa **Lịch cá nhân**, **Lịch mẫu** và **Lịch nhóm**.

### 2.1. Tài khoản

| Việc | Cách làm |
|---|---|
| Đăng ký | Màn hình đầu → **Đăng ký** → nhập email, tên hiển thị, mật khẩu (ít nhất 6 ký tự). Gõ sai tên miền email (vd `gmial.com`) app sẽ gợi ý sửa |
| Đăng nhập | Dùng **email hoặc tên hiển thị** + mật khẩu, hoặc **Đăng nhập bằng Google**. Tick **Ghi nhớ đăng nhập** để không phải nhập lại |
| Quên mật khẩu | **Quên mật khẩu** → nhập email → mở link trong thư (hạn 30 phút) → đặt mật khẩu mới |
| Đổi mật khẩu | **Cài đặt → Đổi mật khẩu**. Tài khoản Google chưa có mật khẩu thì mục này là **Tạo mật khẩu** |
| Đổi email | **Hồ sơ → Email** → nhập email mới → mở link xác nhận gửi tới **email mới** (hạn 24 giờ). Chưa bấm link thì email cũ vẫn dùng bình thường, có thể **Huỷ đổi email** |

Lần đầu đăng nhập, app hiện màn hình chào mừng và **hướng dẫn từng bước** chỉ vào từng nút.
Muốn xem lại: **Cài đặt → Trợ giúp → Xem hướng dẫn sử dụng**.

### 2.2. Lịch cá nhân (Trang chủ)

- **Xem lịch:** lịch theo ngày, đường kẻ ngang là **giờ hiện tại**. Vuốt hoặc bấm thanh ngày để đổi ngày,
  bấm biểu tượng lịch để xem cả tháng. Lịch đã qua hiện mờ.
- **Thêm lịch:** bấm **+** → tên, ngày, giờ bắt đầu/kết thúc, màu, nhắc trước (5/10/15/30/60 phút) → **Lưu**.
  - Không thêm được lịch ở quá khứ, hoặc dài dưới 5 phút.
  - Trùng giờ với lịch đã có thì app báo và không cho lưu.
- **Sửa / xoá:** bấm vào khối lịch → sửa hoặc xoá.
- **Nhân bản:** khi sửa lịch → **Nhân bản sang ngày khác** → chọn các ngày muốn chép sang.
- Hai lịch trùng giờ (vd lịch riêng và hoạt động nhóm) hiện **cạnh nhau**, không đè lên nhau.

Tới giờ nhắc, điện thoại hiện thông báo **"Sắp tới giờ: ..."** kể cả khi app đang tắt.

### 2.3. Lịch mẫu

Lịch mẫu là một tuần mẫu (vd "Tập gym 4 ngày", "Tuần ôn thi") để áp vào lịch thật nhiều lần. Mỗi người tối đa **10 lịch mẫu**.

- **Tạo:** menu ☰ → **Lịch mẫu** → tạo mới → thêm khối giờ cho từng thứ. Thoát giữa chừng vẫn giữ bản nháp.
- **Áp dụng:** chọn lịch mẫu → **Áp dụng** → chọn ngày bắt đầu và số tuần.
  Nếu trùng với lịch đang có, app liệt kê các chỗ trùng và hỏi **Thay thế & Thêm**.
- **Chia sẻ:** chọn lịch mẫu → **Chia sẻ** → gửi **mã 8 ký tự** cho người khác.
- **Nhập mã:** **Lịch mẫu** → **Nhập bằng liên kết** → gõ mã (vd `GYM4DAY`) (không phân biệt hoa thường) → lịch mẫu về kho của bạn.

### 2.4. Nhóm (Tribe)

Mỗi người tham gia tối đa **5 nhóm**; mỗi nhóm tối đa **10 thành viên**, gồm 1 trưởng nhóm và tối đa **3 phó nhóm**.

**Tạo và tham gia**

- **Tạo nhóm:** menu ☰ → **Lịch nhóm** → **Tạo Tribe mới** → đặt tên. Bạn là trưởng nhóm.
- **Mời người:** trong nhóm → **Mời thành viên** → gửi mã/link mời cho bạn bè.
- **Tham gia:** **Lịch nhóm** → **Tham gia Tribe** → nhập mã mời. Vào nhóm là thấy luôn các hoạt động sắp tới và được hỏi có tham gia không.

**Xếp lịch nhóm**

- Lịch nhóm hiện theo **giờ của máy bạn**: cùng một buổi họp, người ở Việt Nam và người ở Nhật thấy đúng giờ địa phương của mình.
- Khung có **sọc chéo** là lúc có thành viên bận. Bấm vào để xem **ai bận** (chỉ hiện tên, không hiện nội dung lịch riêng).
- App **gợi ý các khung cả nhóm rảnh** từ 30 phút trở lên.
- **Tạo hoạt động** (trưởng hoặc phó nhóm): bấm **+** trong nhóm. Chọn giờ có người bận thì app cảnh báo trước khi lưu.

**Trả lời tham gia**

- Hoạt động mới hiện trong lịch của mỗi thành viên ở trạng thái **chờ**. Bấm vào → **Tham gia** hoặc **Từ chối**.
- Trưởng nhóm nhận thông báo khi có người trả lời. Người từ chối không bị nhắc giờ.
- Khi hoạt động **đổi giờ**, mọi người phải xác nhận lại. Khi bị **huỷ**, mọi người nhận thông báo.

**Quản lý thành viên** (mở ngăn thành viên trong nhóm)

| Việc | Ai làm được |
|---|---|
| Đổi tên nhóm, giải tán nhóm | Trưởng nhóm |
| Bổ nhiệm / bãi nhiệm phó nhóm | Trưởng nhóm |
| Chuyển quyền trưởng nhóm | Trưởng nhóm |
| Mời thành viên rời nhóm | Trưởng nhóm (mọi người), phó nhóm (chỉ thành viên thường) |
| Rời nhóm | Mọi người. Trưởng nhóm phải chọn người kế nhiệm trước |

### 2.5. Thông báo

- Tab **Thông báo** giữ thông báo trong **30 ngày** gần nhất.
- Lọc **Tất cả**, **Cá nhân**, hoặc theo từng nhóm; số trên mỗi mục là số chưa đọc.
- Bấm vào thông báo để đánh dấu đã đọc, hoặc **Đánh dấu đã đọc tất cả**.
- Bấm thông báo đẩy trên thanh thông báo của điện thoại sẽ mở thẳng tab này.

### 2.6. Hồ sơ và Cài đặt

- **Hồ sơ:** đổi ảnh đại diện, tên hiển thị, email.
- **Múi giờ:** **Hồ sơ → Vị trí / múi giờ**.
  - **Tự động:** lấy theo điện thoại.
  - **Chọn thủ công:** chọn một thành phố. Đổi múi giờ thì lịch cá nhân giữ đúng thời điểm thật, chỉ đổi giờ hiển thị.
- **Cài đặt:**
  - Ngôn ngữ (Tiếng Việt / English / Français). Email và thông báo đẩy cũng gửi theo ngôn ngữ này.
  - Chế độ tối.
  - Đổi mật khẩu (hoặc Tạo mật khẩu với tài khoản Google).
  - Xem hướng dẫn sử dụng.
  - Đăng xuất.
  - Xoá tài khoản.

Mỗi tài khoản chỉ đăng nhập trên **một máy** cùng lúc; đăng nhập máy mới thì máy cũ bị đăng xuất.

---

## 3. Câu hỏi thường gặp

**Không nhận được thông báo nhắc lịch?**
Kiểm tra đã cho phép thông báo, đã tắt tiết kiệm pin cho app (mục 1). Máy chủ miễn phí có thể ngủ khi không có ai dùng;
nhắc bị trễ sẽ được bù khi máy chủ thức dậy, nhưng nếu lịch đã bắt đầu thì chỉ ghi vào tab Thông báo.

**Cài báo "Ứng dụng chưa được cài đặt"?**
Máy đang có bản TimeTribe ký bằng khoá khác (thường là bản build thử). Gỡ bản cũ rồi cài lại.

**App báo không kết nối được máy chủ?**
Máy chủ đang khởi động lại sau khi ngủ. Đợi 30–60 giây rồi thử lại.

**Không thấy thư xác nhận / đặt lại mật khẩu?**
Xem trong thư mục Spam hoặc Quảng cáo. Link đổi email hết hạn sau 24 giờ, link đặt lại mật khẩu sau 30 phút.

**Đổi điện thoại có mất dữ liệu không?**
Không. Lịch, nhóm, lịch mẫu, múi giờ và trạng thái hướng dẫn đều lưu trên máy chủ. Cài app trên máy mới và đăng nhập là đủ.

---

## 4. Dành cho nhà phát triển

### 4.1. Kiến trúc

```
Flutter app (MVVM + Provider)  ──HTTP/JSON──>  Go backend (Gin)  ──>  MongoDB
        ▲                                          │
        └──── Firebase Cloud Messaging <───────────┘
              Firebase Auth (đăng nhập Google), Cloudinary (ảnh), Brevo/SMTP (email)
```

```
.
├── backend/          # API Go: cmd/server, cmd/seed, internal/{handlers,services,repository,models,...}
│   └── public/       # timetribe.apk cho trang tải
├── time_tribe_v2/    # App Flutter: lib/core, lib/features/{auth,home,timeblock,template,tribe,notifications,profile,settings,onboarding}
└── render.yaml       # Cấu hình deploy Render
```

- **Múi giờ:** lịch cá nhân lưu theo giờ địa phương của chủ lịch, lịch nhóm lưu theo UTC.
- **Tài liệu backend:** chi tiết API và cấu trúc thư mục ở [`backend/README.md`](backend/README.md) và [`backend/API_TESTING.md`](backend/API_TESTING.md).

### 4.2. Yêu cầu

- Go 1.23 trở lên
- MongoDB 6+ chạy ở máy (hoặc MongoDB Atlas)
- Flutter SDK (Dart ^3.12) và Android SDK
- Dự án Firebase. Lấy hai file này từ Firebase Console; chúng **không có trong repo, không được commit**:
  - `backend/serviceAccountKey.json`: service account
  - `time_tribe_v2/android/app/google-services.json`

### 4.3. Chạy backend ở máy

```bash
cd backend
```

```bash
cp .env.example .env
```

Sửa `.env`: đổi `JWT_SECRET`, điền `CLOUDINARY_URL`. Đặt `serviceAccountKey.json` cạnh `.env`.
Không cấu hình SMTP/Brevo thì email chỉ in ra log, mở link trong log để test.

```bash
go mod download
```

Nạp dữ liệu mẫu. Lệnh này **xoá sạch** database `timetribe` rồi nạp lại; mật khẩu chung các tài khoản mẫu là `123456`:

```bash
go run ./cmd/seed
```

```bash
go run ./cmd/server
```

Mở http://localhost:8080/health, thấy `"status":"ok"` là được.

Chạy test:

```bash
go test ./...
```

### 4.4. Chạy app

```bash
cd time_tribe_v2
```

```bash
flutter pub get
```

Máy ảo Android (gọi backend trên máy tính):

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

Điện thoại thật cùng Wi-Fi với máy tính:

```bash
flutter run --dart-define=API_BASE_URL=http://<IP-máy-tính>:8080/api/v1
```

Không truyền `API_BASE_URL` thì bản release dùng `productionUrl` trong `lib/core/api/api_config.dart`.

### 4.5. Build APK và phát hành

1. Tạo khoá ký và `android/key.properties` (không commit file `.jks` và `key.properties`).
   Thêm SHA-1/SHA-256 của khoá vào Firebase để đăng nhập Google chạy được.
2. Build:

```bash
flutter build apk --release
```

3. Chép file vào backend, đúng tên `timetribe.apk`:

```bash
cp build/app/outputs/flutter-apk/app-release.apk ../backend/public/timetribe.apk
```

4. Commit và push. Render deploy lại, nút **Tải APK** ở trang chủ sẽ gửi file mới.
   Nhớ tăng `version` trong `pubspec.yaml` (số sau dấu `+`) để người dùng cài đè được.

### 4.6. Deploy

Backend chạy trên **Render**, database **MongoDB Atlas**.

- **Biến môi trường:** xem [`backend/.env.production.example`](backend/.env.production.example).
- **Firebase:** service account đưa vào biến `FIREBASE_CREDENTIALS_JSON` dạng base64.
- **Trang do backend phục vụ:**
  - `/`: trang tải app.
  - `/download`: file APK.
  - `/reset-password`: đặt lại mật khẩu.
  - `/health`: kiểm tra server.

**Không commit:** `.env`, `serviceAccountKey.json`, `google-services.json`, `key.properties`, `*.jks`.
