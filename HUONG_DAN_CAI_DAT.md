# Hướng dẫn cài đặt TimeTribe

Tài liệu này hướng dẫn cài đặt và chạy TimeTribe theo hai cách:

- **Cách A: chỉ cài app để dùng thử.** Dùng máy chủ đã deploy sẵn, không cần cài gì trên máy tính (khoảng 2 phút).
- **Cách B: chạy toàn bộ từ mã nguồn trên máy tính.** Gồm backend Go, cơ sở dữ liệu MongoDB và app Flutter (khoảng 30–45 phút lần đầu).

Hướng dẫn sử dụng các chức năng nằm ở [README.md](README.md#2-hướng-dẫn-sử-dụng).

---

## Mục lục

- [Cách A: Cài app Android](#cách-a-cài-app-android)
- [Cách B: Chạy từ mã nguồn](#cách-b-chạy-từ-mã-nguồn)
  - [B1. Cấu trúc mã nguồn](#b1-cấu-trúc-mã-nguồn)
  - [B2. Cài công cụ](#b2-cài-công-cụ)
  - [B3. Các file cấu hình bí mật](#b3-các-file-cấu-hình-bí-mật)
  - [B4. Chạy backend](#b4-chạy-backend)
  - [B5. Chạy app Flutter](#b5-chạy-app-flutter)
  - [B6. Tài khoản mẫu để test](#b6-tài-khoản-mẫu-để-test)
  - [B7. Build file APK](#b7-build-file-apk)
- [Xử lý lỗi thường gặp](#xử-lý-lỗi-thường-gặp)

---

## Cách A: Cài app Android

1. Trên điện thoại Android, mở **https://timetribe.onrender.com/** rồi bấm **Tải APK**.
   Máy chủ dùng gói miễn phí, nên lần đầu mở có thể phải chờ 30–60 giây.
2. Mở file `timetribe.apk` vừa tải.
3. Android hỏi **Cho phép cài ứng dụng từ nguồn này** → bật cho trình duyệt đang dùng → quay lại bấm **Cài đặt**.
4. Nếu Google Play Protect cảnh báo → **Chi tiết** → **Vẫn cài đặt**. App chưa lên Play Store nên luôn có bước này.
5. Mở app, **cho phép thông báo**, rồi đăng ký tài khoản mới hoặc đăng nhập bằng Google.

Máy **Xiaomi, Oppo, Vivo, Realme** hay chặn app chạy nền. Để nhận nhắc lịch đúng giờ, vào
*Cài đặt → Ứng dụng → TimeTribe*: bật **Tự khởi chạy** và chọn **Tiết kiệm pin: Không hạn chế**.

---

## Cách B: Chạy từ mã nguồn

### B1. Cấu trúc mã nguồn

```
time_tribe_v2/                  (thư mục gốc repo)
├── backend/                    API viết bằng Go (Gin) + MongoDB
│   ├── cmd/server/             điểm chạy server
│   ├── cmd/seed/               nạp dữ liệu mẫu
│   ├── internal/               handlers, services, repository, models, ...
│   ├── public/timetribe.apk    file APK cho trang tải
│   └── .env.example            mẫu cấu hình
├── time_tribe_v2/              app Flutter (Android)
│   ├── lib/core/               API client, tiện ích giờ/múi giờ, widget dùng chung
│   └── lib/features/           auth, timeblock, template, tribe, notifications, profile, settings, ...
├── README.md                   giới thiệu + hướng dẫn sử dụng
└── HUONG_DAN_CAI_DAT.md        tài liệu này
```

```
App Flutter ──HTTP/JSON──> Backend Go (cổng 8080) ──> MongoDB (cổng 27017)
     ▲                            │
     └──── Firebase Cloud Messaging (thông báo đẩy)
```

### B2. Cài công cụ

| Công cụ | Phiên bản | Tải ở đâu | Kiểm tra |
|---|---|---|---|
| Git | bất kỳ | https://git-scm.com/downloads | `git --version` |
| Go | 1.23 trở lên | https://go.dev/dl/ | `go version` |
| MongoDB Community Server | 6.0 trở lên | https://www.mongodb.com/try/download/community | `mongod --version` |
| MongoDB Compass (không bắt buộc) | bất kỳ | đi kèm bộ cài MongoDB | Xem dữ liệu bằng giao diện |
| Flutter SDK | bản stable mới (Dart 3.12 trở lên) | https://docs.flutter.dev/get-started/install | `flutter --version` |
| Android Studio | bản mới | https://developer.android.com/studio | Dùng để cài Android SDK và máy ảo |

Sau khi cài Flutter và Android Studio:

```bash
flutter doctor --android-licenses
```

```bash
flutter doctor
```

Các dòng **Flutter** và **Android toolchain** phải có dấu ✓.

**MongoDB trên Windows:** khi cài, chọn *Install MongoD as a Service* để MongoDB tự chạy cùng máy.
Mở Compass, kết nối `mongodb://localhost:27017` là biết MongoDB đã chạy.

Lấy mã nguồn:

```bash
git clone https://github.com/Blysd04/time_tribe_v2.git
```

```bash
cd time_tribe_v2
```

Nếu nhận mã nguồn dạng file zip thì giải nén rồi mở terminal tại thư mục vừa giải nén.

### B3. Các file cấu hình bí mật

Ba file dưới đây chứa khoá truy cập nên **không đưa lên GitHub**. Nếu nhận mã nguồn dạng zip có kèm sẵn
các file này, chỉ cần chép đúng vị trí.

| File | Đặt ở | Thiếu thì sao |
|---|---|---|
| `.env` | `backend/.env` | Tạo từ `.env.example` (bước B4), không thể thiếu |
| `serviceAccountKey.json` | `backend/serviceAccountKey.json` | Server vẫn chạy, nhưng **tắt đăng nhập Google và thông báo đẩy** |
| `google-services.json` | `time_tribe_v2/android/app/google-services.json` | **App không build được** |

**Tự tạo các file Firebase (nếu không được gửi kèm):**

1. Vào https://console.firebase.google.com → **Add project** → đặt tên bất kỳ.
2. **Lấy `google-services.json`:**
   - *Project settings* → *Your apps* → **Add app** → Android.
   - Package name: `com.example.time_tribe_v2`.
   - Tải file `google-services.json`, chép vào `time_tribe_v2/android/app/`.
3. **Lấy `serviceAccountKey.json`:**
   - *Project settings* → **Service accounts** → **Generate new private key**.
   - Đổi tên file thành `serviceAccountKey.json`, chép vào `backend/`.
4. **Bật đăng nhập Google (không bắt buộc):**
   - *Build* → **Authentication** → *Sign-in method* → bật **Google**.
   - Thêm mã SHA-1 của máy vào *Project settings* → *Your apps* → **Add fingerprint**. Lấy mã bằng lệnh:

```bash
cd time_tribe_v2/android && ./gradlew signingReport
```

   Trên Windows dùng `gradlew signingReport`. Sau khi thêm SHA-1, tải lại `google-services.json`.

### B4. Chạy backend

Mở terminal tại thư mục `backend`:

```bash
cd backend
```

**1. Tạo file cấu hình**

macOS / Linux:

```bash
cp .env.example .env
```

Windows (PowerShell):

```bash
Copy-Item .env.example .env
```

Mở `backend/.env` và kiểm tra các dòng sau. Giá trị mặc định đủ để chạy ở máy:

| Biến | Giá trị khi chạy ở máy | Ghi chú |
|---|---|---|
| `MONGO_URI` | `mongodb://localhost:27017` | Dùng MongoDB Atlas thì dán chuỗi `mongodb+srv://...` |
| `DB_NAME` | `timetribe` | |
| `JWT_SECRET` | chuỗi bất kỳ | Chạy ở máy để mặc định được |
| `FIREBASE_CREDENTIALS` | `serviceAccountKey.json` | Đường dẫn tới file ở bước B3 |
| `CLOUDINARY_URL` | để trống hoặc `cloudinary://...` | Trống thì tắt chức năng đổi ảnh đại diện |
| `SMTP_HOST`... | để trống | Trống thì email (quên mật khẩu, đổi email) **in ra terminal**, mở link trong log để test |

**2. Tải thư viện Go**

```bash
go mod download
```

**3. Nạp dữ liệu mẫu**

Lệnh này **xoá sạch** database `timetribe` rồi nạp lại tài khoản, nhóm, lịch, lịch mẫu và thông báo mẫu:

```bash
go run ./cmd/seed
```

**4. Chạy server**

```bash
go run ./cmd/server
```

Terminal in ra dòng `TimeTribe API đang chạy tại http://localhost:8080 (db: timetribe)`. Mở trình duyệt:

- http://localhost:8080/health: thấy `"status":"ok"` là server chạy được.
  `firebase_auth` và `firebase_push` bằng `true` nghĩa là đã đọc được `serviceAccountKey.json`.
- http://localhost:8080/: trang giới thiệu và tải app.

Để terminal này chạy suốt lúc dùng app. Muốn dừng thì nhấn `Ctrl + C`.

**Chạy test backend (không bắt buộc):**

```bash
go test ./...
```

### B5. Chạy app Flutter

Mở **terminal thứ hai** tại thư mục `time_tribe_v2/time_tribe_v2`:

```bash
cd time_tribe_v2
```

```bash
flutter pub get
```

Chọn **một** trong hai cách chạy dưới đây. App cần biết địa chỉ backend qua tham số `API_BASE_URL`.

**Máy ảo Android:** mở Android Studio → *Device Manager* → bật một máy ảo, rồi chạy:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

`10.0.2.2` là địa chỉ máy ảo dùng để gọi về máy tính.

**Điện thoại thật:**

1. Bật *Tuỳ chọn nhà phát triển* và *Gỡ lỗi USB* trên điện thoại, cắm cáp vào máy tính.
2. Điện thoại và máy tính phải **dùng chung Wi-Fi**.
3. Xem IP của máy tính:
   - Windows: `ipconfig`, lấy dòng *IPv4 Address*.
   - macOS / Linux: `ifconfig` hoặc `ip addr`.
4. Chạy, thay `192.168.1.10` bằng IP vừa xem:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api/v1
```

Windows có thể chặn cổng 8080. Khi tường lửa hỏi lúc chạy server, bấm **Allow access**.

**Dùng máy chủ đã deploy thay cho backend ở máy:**

```bash
flutter run --dart-define=API_BASE_URL=https://timetribe.onrender.com/api/v1
```

### B6. Tài khoản mẫu để test

Sau khi chạy `go run ./cmd/seed`, mọi tài khoản dưới đây có mật khẩu **`123456`**. Đăng nhập bằng email hoặc tên hiển thị.

| Email | Tên hiển thị | Dùng để thử |
|---|---|---|
| `tuyetnga@timetribe.app` | Tuyết Nga | Tài khoản chính: có lịch cá nhân, lịch mẫu, là trưởng nhóm "Đồ án NIC" |
| `minh.tran@timetribe.app` | Minh Trần | Phó nhóm NIC: trả lời tham gia, nhận thông báo |
| `linh.pham@timetribe.app` | Linh Phạm | Trưởng nhóm Marketing |
| `hana.sato@timetribe.app` | Hana Sato | Ở Tokyo: xem lịch nhóm theo múi giờ khác |
| `david.nguyen@timetribe.app` | David Nguyen | Ở Vancouver |
| `nguoimoi@timetribe.app` | Người Mới | Tài khoản mới: thấy màn hình chào mừng và hướng dẫn từng bước |
| `spam.bot@timetribe.app` | spam.bot | Tài khoản bị khoá: đăng nhập sẽ báo lỗi |
| `admin@timetribe.com` | admin | Quản trị: gửi thông báo chung qua API `POST /api/v1/admin/notifications/broadcast`, app không có màn hình riêng cho admin |

**Mã để thử:**

| Loại | Mã | Ghi chú |
|---|---|---|
| Mã mời nhóm | `NIC2026` | Nhóm "Đồ án NIC" |
| Mã mời nhóm | `CAULONGQ7`, `MKTGLOBAL`, `GAMEDEV26` | Nhóm Cầu lông Q7, Team Marketing Global, Hội Game Dev |
| Mã mời nhóm | `FULLHOUSE` | Nhóm đã đủ 10 người: nhập sẽ báo đầy |
| Mã lịch mẫu | `GYM4DAY`, `STUDYWEEK` | Nhập ở *Lịch mẫu → Nhập bằng liên kết* |

Đầy đủ danh sách tài khoản được in ra cuối lệnh `go run ./cmd/seed`.

Mỗi tài khoản chỉ đăng nhập trên **một máy** cùng lúc. Muốn thử hai người tương tác (một người tạo hoạt động nhóm,
người kia trả lời), dùng hai máy (ví dụ máy ảo và điện thoại) với hai tài khoản khác nhau.

### B7. Build file APK

Trong thư mục `time_tribe_v2/time_tribe_v2`:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://timetribe.onrender.com/api/v1
```

File nằm ở `build/app/outputs/flutter-apk/app-release.apk`. Chép sang điện thoại để cài, hoặc chép vào
`backend/public/timetribe.apk` để nút **Tải APK** trên trang chủ phát file này.

Chưa có file `android/key.properties` thì APK được ký bằng khoá debug, cài thử bình thường được.

---

## Xử lý lỗi thường gặp

| Lỗi | Nguyên nhân và cách sửa |
|---|---|
| `go run ./cmd/seed` báo không kết nối được MongoDB | MongoDB chưa chạy. Windows: mở *Services* → khởi động **MongoDB Server**. macOS: `brew services start mongodb-community`. Kiểm tra `MONGO_URI` trong `.env` |
| `go: go.mod requires go >= 1.23` | Cài Go bản mới hơn |
| Build app báo `File google-services.json is missing` | Thiếu file ở bước B3 |
| App báo **không kết nối được máy chủ** | Server chưa chạy, sai `API_BASE_URL` (thiếu `/api/v1`), điện thoại khác Wi-Fi với máy tính, hoặc tường lửa chặn cổng 8080 |
| Đăng nhập Google báo lỗi (`ApiException: 10`) | Chưa thêm SHA-1 vào Firebase, hoặc chưa tải lại `google-services.json` sau khi thêm |
| Không nhận thông báo đẩy | Thiếu `serviceAccountKey.json` (xem `/health`), chưa cho phép thông báo, hoặc máy Xiaomi/Oppo chặn chạy nền |
| Đổi ảnh đại diện báo lỗi | Chưa điền `CLOUDINARY_URL` |
| Không nhận email quên mật khẩu | Chưa cấu hình SMTP: link được in ra terminal của server, mở link đó trong trình duyệt |
| Đăng nhập máy này thì máy kia bị đăng xuất | Đúng thiết kế: mỗi tài khoản chỉ đăng nhập một máy |
| `flutter run` báo không thấy thiết bị | Chạy `flutter devices`. Máy ảo chưa bật hoặc điện thoại chưa bật *Gỡ lỗi USB* |
