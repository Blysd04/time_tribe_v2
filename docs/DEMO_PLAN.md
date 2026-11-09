# Kịch bản quay video demo TimeTribe v2

Tài liệu này dùng khi quay video demo trước thầy cô. Gồm 6 phần:

1. Chuẩn bị trước khi quay: thiết bị, dữ liệu, tài khoản.
2. Thứ tự demo theo từng cảnh: bấm gì, nói gì, có điểm "ăn điểm" để nhấn mạnh.
3. Hành trình phát triển và các vấn đề đã gặp: frontend, rồi backend, rồi tới hiện tại.
4. Câu hỏi thầy cô có thể hỏi và cách trả lời.
5. Phụ lục: tài khoản, mã mời, giới hạn nghiệp vụ, mã chức năng.
6. Checklist ngay trước khi bấm quay.

> Mã chức năng (AU-xx, COM-xx, TP-xx, NOTI-xx, SET-xx) lấy theo chú thích trong code.
> Khi quay, mở sheet danh sách chức năng song song để đối chiếu và tick từng mục.

---

## 1. Chuẩn bị trước khi quay

### 1.1. Thiết bị

| Thiết bị | Đăng nhập tài khoản | Dùng để |
|---|---|---|
| **Điện thoại thật** (máy chính, đang quay màn hình) | **Tuyết Nga** | Nhận thông báo đẩy thật, demo lịch cá nhân, lịch mẫu, nhóm |
| **Máy ảo Android** (hoặc điện thoại thứ 2) | **Minh Trần** → **Người Mới** → **Linh Phạm** | Đóng vai người khác: tạo hoạt động nhóm, trả lời tham gia, nhập mã |
| **Máy tính** | — | Chạy MongoDB + backend, mở MongoDB Compass, Postman, terminal xem log |

- Mỗi tài khoản chỉ được đăng nhập trên **một máy** cùng lúc (xem cảnh 10).
  Vì vậy đổi tài khoản trên máy ảo bằng cách vào Cài đặt → Đăng xuất rồi đăng nhập tài khoản khác.
  Không đăng nhập tài khoản Nga trên máy ảo, trừ khi đang demo cảnh 10.
- Máy ảo chạy app với địa chỉ backend của máy tính:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
```

- Điện thoại thật dùng IP LAN của máy tính. Hai máy phải chung Wi-Fi:

```bash
flutter run --release --dart-define=API_BASE_URL=http://<IP-máy-tính>:8080/api/v1
```

- Trên điện thoại: bật thông báo cho TimeTribe. Với Xiaomi/MIUI, bật thêm "Tự khởi chạy",
  tắt tiết kiệm pin cho app, và bật "Thông báo nổi" cho kênh "Nhắc lịch & hoạt động nhóm".
- Bật "Hiện thao tác chạm" trong tuỳ chọn nhà phát triển, để người xem thấy chỗ bạn bấm.

### 1.2. Nạp dữ liệu demo

File seed đã có sẵn chế độ demo: `backend/cmd/seed/main.go`, cờ `-demo`.

```bash
cd backend
```

```bash
go run ./cmd/seed -demo -tz America/Vancouver -lead 12
```

- `-tz`: múi giờ của **điện thoại dùng để quay**. Ví dụ `America/Vancouver`, hoặc `Asia/Ho_Chi_Minh` nếu để giờ Việt Nam.
  Cờ này áp cho tài khoản Tuyết Nga và Người Mới.
- `-lead 12`: 12 phút sau khi seed thì có thông báo nhắc đầu tiên.
  Nếu dự định quay chậm hơn, đặt 15–20.

Seed xoá sạch database rồi nạp lại. Cuối lệnh, seed in ra **lịch trình demo** theo giờ của Nga, ví dụ:

```
== Kịch bản demo (giờ theo múi giờ America/Vancouver) ==
  20:12 09/11  thông báo đẩy "Sắp tới giờ: Tập thuyết trình đồ án" (cá nhân, nhắc trước 15 phút)
  20:15 09/11  thông báo đẩy "Sắp tới giờ: Chạy thử demo với nhóm" (nhóm Đồ án NIC, nhắc trước 10 phút)
  20:25 09/11  hai lịch trên trùng giờ, xem lịch hiển thị cạnh nhau
  ngay khi bật server  thông báo nhắc bù "Gọi điện cho mẹ" (đã bắt đầu lúc 19:50, không đẩy)
  19:00 10/11  lịch "Học tiếng Anh" để thử tạo lịch trùng giờ
  20:00 10/11  "Chốt nội dung video quảng cáo" (Team Marketing) đang chờ Nga trả lời
```

**Chụp lại đoạn này** để biết lúc nào điện thoại sẽ rung.

Sau khi seed:

1. Chạy server **ngay**:

```bash
go run ./cmd/server
```

2. Đăng nhập lại trên điện thoại và máy ảo. Seed đã xoá phiên đăng nhập và `fcm_token` cũ;
   app tự gửi `fcm_token` mới khi vào trang chủ.
3. Kiểm tra push. Trên điện thoại vào Cài đặt → Trợ giúp → **Gửi thông báo thử**. Phải thấy thông báo hiện trên thanh thông báo.

### 1.3. Dữ liệu demo gồm những gì

| Dữ liệu | Mục đích demo |
|---|---|
| Lịch cá nhân 7 ngày trước tới 14 ngày sau của Nga, Minh, Linh, Hana (Tokyo), David (Vancouver) | Lịch trang chủ có dữ liệu thật, tính giờ bận khi xếp lịch nhóm |
| "Đọc sách 30 phút" có 2 bản nhân bản | Tính năng nhân bản sang ngày khác (`repeating_dates`) |
| **"Tập thuyết trình đồ án"** (bắt đầu sau lead+15 phút, nhắc trước 15 phút) | Thông báo nhắc lịch cá nhân đẩy về máy |
| **"Chạy thử demo với nhóm"** (nhóm NIC, nhắc trước 10 phút). David đã từ chối | Thông báo nhắc nhóm. Người từ chối không bị nhắc. Trùng giờ với lịch cá nhân ở dòng trên |
| **"Gọi điện cho mẹ"** (đã bắt đầu 10 phút trước khi seed) | Nhắc bù khi server tắt đúng lúc tới giờ nhắc |
| **"Học tiếng Anh"** 19:00–20:30 | Thử thêm lịch 19:30 → bị chặn vì trùng giờ |
| **"Chốt nội dung video quảng cáo"** (Marketing, ngày mai, Nga đang chờ) | Nút Tham gia / Từ chối, thông báo về cho trưởng nhóm |
| 5 nhóm: NIC, Cầu lông Q7, Marketing Global, Game Dev, **Nhóm đã đủ người** (10/10) | Danh sách nhóm, vai trò, giới hạn 10 người |
| Lịch mẫu "Quy trình tập Gym 4 ngày" mã **GYM4DAY**, "Tuần ôn thi" mã **STUDYWEEK** | Nhập lịch mẫu bằng mã chia sẻ |
| Lịch mẫu "Tuần học NIC & Đi làm" của Nga, trùng giờ với lịch "Học UI/UX" đã có | Áp dụng lịch mẫu và hộp thoại "Thay thế & Thêm" |
| Thông báo cũ: mời vào nhóm, bổ nhiệm phó nhóm, có người từ chối; một thông báo quá 30 ngày (không hiện) | Danh sách thông báo, lọc theo nhóm, giới hạn 30 ngày |
| Thông báo chung của admin "Chào mừng bạn đến với TimeTribe v2" | Thông báo hệ thống, trạng thái đã đọc riêng từng người |
| **Người Mới** (`nguoimoi@timetribe.app`, chưa xem hướng dẫn) | Màn hình chào mừng và hướng dẫn từng bước |
| `spam.bot` (bị khoá) | Đăng nhập tài khoản bị khoá |

Mật khẩu chung của mọi tài khoản: **123456**. Riêng tài khoản Google (Bảo Ngọc) không có mật khẩu.

---

## 2. Thứ tự demo (khoảng 25–30 phút)

Nguyên tắc sắp xếp:

- Đi theo **hành trình của một người dùng mới**: đăng ký → làm quen → lịch cá nhân → lịch mẫu → nhóm → thông báo → cài đặt.
- Sau đó mới mở "hậu trường" (backend, database) để chứng minh hiểu code.
- Thông báo đẩy tới theo giờ đã canh. **Khi điện thoại rung thì nhảy sang cảnh 5**, demo xong quay lại cảnh đang dở.

Mỗi cảnh có ba phần:

- 🎬 thao tác
- 🗣️ lời nói gợi ý (nói tự nhiên, không cần đọc nguyên văn)
- ⭐ điểm kỹ thuật nên nhấn mạnh

### Cảnh 0. Mở đầu (1 phút)

🎬 Mở slide kiến trúc, hoặc vẽ nhanh sơ đồ:

```
Flutter app (MVVM + Provider)  ──HTTP/JSON──>  Go backend (Gin)  ──>  MongoDB (11 collection + 2 bảng kỹ thuật)
        ▲                                         │
        └──── Firebase Cloud Messaging <──────────┘   (Firebase Auth cho Google, Cloudinary cho ảnh)
```

🗣️ "TimeTribe là ứng dụng quản lý thời gian cá nhân và xếp lịch nhóm. Điểm khác biệt là các thành viên
có thể ở **nhiều múi giờ khác nhau**. App tự tìm khung giờ cả nhóm cùng rảnh, nhắc lịch bằng thông báo đẩy,
và cho phép chia sẻ lịch mẫu.
Frontend viết bằng Flutter theo mô hình MVVM: View, ViewModel dùng ChangeNotifier, Model.
Backend viết bằng Go, chia ba lớp Handler → Service → Repository, lưu MongoDB."

⭐ Nêu ngắn quy ước: tên collection và tên trường snake_case theo thiết kế CSDL 11 bảng. ID là UUID.
Ngày lưu dạng `YYYY-MM-DD`, giờ lưu dạng `HH:mm:ss`.

### Cảnh 1. Đăng ký, đăng nhập, quên mật khẩu (AU-01 → AU-04) (3 phút)

🎬 Trên **máy ảo**:

1. Màn hình khởi động (splash) hiện **nền sáng**. Bấm Đăng ký.
2. Cố tình nhập sai: email sai định dạng, mật khẩu ngắn, xác nhận không khớp → lỗi hiện dưới từng ô.
3. Nhập nick `Tuấn Hồ` (đã có người dùng) → báo "Email hoặc tên hiển thị đã được sử dụng".
4. Đăng ký thành công một tài khoản mới, ví dụ `demo1@timetribe.app`.
5. Đăng nhập bằng **tên hiển thị** thay vì email để cho thấy cả hai cách đều được. Tick "Ghi nhớ đăng nhập".
6. Thử đăng nhập `spam.bot` → báo tài khoản bị khoá.
7. Quên mật khẩu: nhập email → app luôn báo đã gửi.

🗣️ "Mật khẩu được băm bằng **bcrypt**, không lưu bản rõ. Đăng nhập cấp **access token JWT** (ngắn hạn) và
**refresh token**. Refresh token chỉ lưu **bản băm SHA-256** trong bảng `user_tokens`, nên lộ database cũng không dùng lại được.
Quên mật khẩu thì server luôn trả 'đã gửi', dù email có tồn tại hay không, để không lộ danh sách tài khoản."

⭐ Có thể demo thêm **đăng nhập Google** (AU-03): app lấy Firebase ID token, backend xác minh bằng Firebase Admin SDK.

### Cảnh 2. Chào mừng và hướng dẫn cho người mới (2–3 phút)

🎬 Ngay sau khi tài khoản mới đăng nhập lần đầu, hoặc đăng nhập `nguoimoi@timetribe.app`:

1. Trang chào mừng → các trang giới thiệu lợi ích của app.
2. Màn hình chọn **"Tôi đã biết dùng"** / **"Tôi là người mới"**. Chọn người mới.
3. Hướng dẫn từng bước (tutorial_coach_mark): màn hình tối đi, khoét sáng từng nút (menu, lịch, nút +,
   thông báo, hồ sơ, cài đặt). Mỗi bước có thẻ giải thích, nút Quay lại / Tiếp tục / Bỏ qua và thanh tiến trình.
4. Đăng xuất rồi đăng nhập lại → **không hiện lại** hướng dẫn.

🗣️ "Trạng thái 'đã xem hướng dẫn' **lưu trên server** (`users.needs_onboarding`), không lưu trên máy.
Nên gỡ app cài lại, hoặc đổi máy, người dùng cũ cũng không bị hỏi lại.
Muốn xem lại thì vào Cài đặt → Trợ giúp → Xem lại hướng dẫn."

### Cảnh 3. Trang chủ và lịch cá nhân (5 phút)

🎬 Chuyển sang **điện thoại**, tài khoản Tuyết Nga.

1. Lịch theo ngày: thanh **giờ hiện tại** chạy ngang, các khối màu, đổi ngày, xem lịch theo tháng có số đếm.
2. Chỉ vào khối **"Gọi điện cho mẹ"**: bị làm mờ vì đã qua.
3. Mở tab **Thông báo** → có thông báo nhắc **"Gọi điện cho mẹ"** (nhắc bù). Giải thích ở mục 3.3, vấn đề 4.
4. Bấm **+** để thêm lịch:
   - Thử các lỗi: tên 1 ký tự, chọn ngày quá khứ, giờ kết thúc cách giờ bắt đầu dưới 5 phút → đều bị chặn.
   - Thêm lịch **ngày mai 19:30–20:00** → báo **trùng giờ với "Học tiếng Anh"**.
   - Thêm lịch hợp lệ, chọn màu, chọn nhắc trước 5/10/15/30/60 phút.
5. Sửa và xoá một lịch.
6. **Nhân bản** một lịch sang nhiều ngày (sheet chọn ngày).
7. Mở ngày có **"Tập thuyết trình đồ án"** và **"Chạy thử demo với nhóm"**: hai khối **trùng giờ nằm cạnh nhau**, không đè lên nhau.

🗣️ "Lịch cá nhân lưu theo **giờ địa phương của chủ lịch**. 8 giờ sáng là 8 giờ sáng ở nơi tôi đang sống.
Lịch nhóm thì lưu theo **UTC**, vì nhiều người ở nhiều múi giờ cùng nhìn chung một mốc.
Kiểm tra trùng giờ làm ở **cả hai phía**: app kiểm tra trước cho nhanh, server kiểm tra lại và trả lỗi 409 `overlap`,
để không ai gọi API bỏ qua được."

⭐ Thuật toán xếp cột khi trùng giờ (`core/utils/overlap_layout.dart`):

1. Sắp các khối theo giờ bắt đầu.
2. Gom các khối chồng nhau thành từng cụm.
3. Trong mỗi cụm, đặt khối vào cột trống đầu tiên. Mọi khối trong cụm rộng bằng nhau.

### Cảnh 4. Lịch mẫu (TP-01 → TP-09) (4 phút)

🎬 Trên điện thoại (Nga):

1. Mở tab Lịch mẫu: bộ đếm **x/10**.
2. Tạo lịch mẫu mới có khối ở nhiều thứ.
   - Thử thêm 2 khối trùng giờ trong cùng một thứ → bị chặn.
   - Thoát giữa chừng → **bản nháp được giữ lại**.
3. Chia sẻ "Quy trình tập Gym 4 ngày" → hiện mã **GYM4DAY**, có nút sao chép.
4. **Áp dụng** "Tuần học NIC & Đi làm" cho 2 tuần → hộp thoại báo **trùng với "Học UI/UX"** đã có.
   Hộp thoại liệt kê các ngày bị trùng, có nút **"Thay thế & Thêm"**. Bấm → lịch mới thay lịch cũ.
5. Trên **máy ảo** (Người Mới):
   - Nhập mã `gym4day` (viết thường vẫn được) → lịch mẫu về kho.
   - Nhập lại lần nữa → báo "đã có trong kho".

🗣️ "Mã chia sẻ gồm 8 ký tự viết hoa, nhập không phân biệt hoa thường. Bản nhập về lưu `original_template_id`
để biết nguồn gốc. Áp dụng lịch mẫu có chế độ **dry run**: server tính trước có bao nhiêu khối sẽ thêm,
bao nhiêu khối bị trùng. Chỉ khi người dùng đồng ý thay thế, server mới xoá lịch cũ và ghi lịch mới."

### Cảnh 5. Thông báo đẩy (chèn vào khi điện thoại rung) (3 phút)

🎬 Theo giờ đã canh khi seed:

1. **Mốc 1: "Sắp tới giờ: Tập thuyết trình đồ án"** (lịch cá nhân).
   Trước mốc 1 khoảng 30 giây, **khoá màn hình** hoặc **thoát app ra nền**.
   Thông báo hiện trên màn hình khoá, có icon chuông, có âm thanh.
   Bấm vào → app mở thẳng tab **Thông báo**.
2. **Mốc 2: "Sắp tới giờ: Chạy thử demo với nhóm"** (nhóm NIC).
   Lần này **để app đang mở**: vẫn hiện thông báo trên thanh thông báo, đồng thời có banner trong app.
3. Trên máy ảo đăng nhập David (người đã từ chối hoạt động này): **không nhận** nhắc.
4. Mở tab Thông báo:
   - Lọc theo "Cá nhân" và theo từng nhóm.
   - Bấm một thông báo → đã đọc. "Đánh dấu tất cả đã đọc".
   - Giờ trong nội dung thông báo hiển thị đúng **theo giờ máy**.
5. Cho terminal backend lên màn hình: có dòng log
   `nhắc lịch cá nhân "Tập thuyết trình đồ án" của Tuyết Nga: bắt đầu ... (múi giờ America/Vancouver)`.

🗣️ "Backend có một **worker chạy đúng giây :00 mỗi phút**. Nó tìm lịch có mốc 'giờ bắt đầu trừ số phút nhắc'
rơi vào khoảng từ lần quét trước tới bây giờ. Mỗi lần nhắc ghi vào `reminder_logs` với khoá duy nhất
'lịch + người nhận + mốc nhắc', nên không bao giờ gửi trùng.
Mốc quét cuối lưu ở `worker_state`. Server tắt rồi bật lại vẫn nhắc bù được trong vòng 24 giờ.
Nếu hoạt động đã bắt đầu thì chỉ ghi vào danh sách, không đẩy nữa, vì đẩy 'sắp tới giờ' lúc đã qua giờ thì vô nghĩa."

### Cảnh 6. Nhóm (COM-01 → COM-19) (7 phút). Phần chính của đề tài

**6a. Danh sách và chi tiết nhóm** (điện thoại, Nga)

1. Mở danh sách nhóm: vai trò của mình trong từng nhóm, số hoạt động **đang chờ mình trả lời**.
2. Mở "Đồ án NIC" → ngăn thành viên: trưởng nhóm, phó nhóm, thành viên.
   Có Hana (Tokyo) và David (Vancouver), mỗi người hiện múi giờ riêng.
3. Lịch nhóm theo ngày: các khung có **sọc chéo** là lúc có người bận.
   Bấm vào khung → xem **ai bận**. Chỉ hiện tên người bận, không hiện nội dung lịch riêng của họ.
4. Gợi ý **khung giờ cả nhóm rảnh** (từ 30 phút trở lên).

🗣️ "Đây là phần khó nhất. Mỗi người lưu lịch cá nhân theo giờ địa phương của họ.
Để so sánh, server đổi tất cả ra **khoảng thời gian tuyệt đối UTC**: lịch cá nhân của từng người,
cộng với hoạt động của **nhóm khác** mà họ đã nhận tham gia.
Sau đó gom mọi mốc bắt đầu và kết thúc, chia ngày thành các đoạn. Mỗi đoạn biết tập người bận,
đoạn liền kề có cùng tập người bận thì gộp lại.
Đoạn không ai bận và dài từ 30 phút trở lên là khung giờ gợi ý.
Vì múi giờ lệch nhau, server lấy rộng ra hai ngày mỗi phía để không bỏ sót lịch."

**6b. Tạo hoạt động nhóm (COM-07), cảnh báo người bận**

1. Bấm + trong nhóm NIC, chọn khung giờ **có sọc** (ví dụ giờ hành chính của Minh).
2. App cảnh báo **"Có N thành viên đang bận"** và liệt kê tên. Vẫn cho tạo nếu trưởng hoặc phó nhóm muốn.
3. Thử chọn giờ đã qua → bị chặn.

**6c. Trả lời tham gia (COM-19), đổi qua lại 2 tài khoản**

1. **Máy ảo** đăng nhập **Minh Trần** (phó nhóm NIC). Nhận thông báo "hoạt động mới", trên lịch cá nhân hiện hoạt động ở trạng thái **chờ**.
2. Minh bấm **Từ chối** → **điện thoại (Nga, trưởng nhóm)** nhận thông báo "Minh Trần không tham gia ...".
3. Trên điện thoại, Nga mở **"Chốt nội dung video quảng cáo"** (Marketing) → bấm **Tham gia**.
   Linh (trưởng nhóm Marketing) nhận thông báo.
4. **Sửa giờ** hoạt động (COM-09) → mọi người phải **xác nhận lại**, và nhận thông báo "đổi giờ".
   Huỷ hoạt động (COM-10) → mọi người nhận thông báo huỷ.

**6d. Tham gia bằng mã mời và các giới hạn** (máy ảo, Người Mới)

1. Nga mở **Mời** (COM-18) → hiện mã `NIC2026`, sao chép.
2. Người Mới nhập `nic2026` → vào nhóm. Nga nhận thông báo "Người Mới đã tham gia".
   Người Mới tự động có trạng thái "chờ" cho các hoạt động sắp tới của nhóm.
3. Nhập `FULLHOUSE` → báo **"Nhóm đã đủ 10 thành viên"**.
4. Nhập lại `NIC2026` → báo "Bạn đã ở trong nhóm này rồi".

**6e. Quản lý thành viên** (điện thoại, Nga là trưởng nhóm NIC)

1. Bổ nhiệm **phó nhóm** (COM-15): tối đa 3 người. Bãi nhiệm (COM-17).
2. **Chuyển quyền trưởng nhóm** (COM-16).
3. **Mời rời nhóm** (COM-14): Người Mới nhận thông báo bị mời ra.
4. Đổi tên nhóm (COM-05): chỉ trưởng nhóm làm được.
5. Trưởng nhóm bấm **Rời nhóm** (COM-12/13) → **bắt chọn người kế nhiệm** trước khi rời.
6. Giải tán nhóm (COM-06): tạo một nhóm thử rồi giải tán.
   Không giải tán nhóm NIC vì còn dùng trong demo.

🗣️ "Quyền được kiểm tra ở **server**, không chỉ ẩn nút trên app:

- Thành viên thường không tạo được hoạt động.
- Phó nhóm chỉ mời rời được thành viên thường.
- Mỗi người tối đa 5 nhóm, mỗi nhóm tối đa 10 người và 3 phó nhóm.

Vi phạm thì server trả **409** với mã lỗi riêng (`tribe_full`, `tribe_limit`, `vice_limit`...).
App dịch mã lỗi đó ra câu thông báo theo ngôn ngữ đang chọn."

### Cảnh 7. Đa múi giờ (3 phút). Chứng minh xử lý múi giờ đúng

🎬

1. Trên **máy ảo** đăng nhập **Hana Sato** (Tokyo) và mở nhóm NIC.
   Hoạt động **"Họp chốt tiến độ"** mà Nga thấy lúc X giờ thì Hana thấy theo **giờ Tokyo**.
   So sánh hai màn hình đặt cạnh nhau.
2. Trên điện thoại: Hồ sơ → **Vị trí / múi giờ**.
   - Chế độ **tự động** lấy theo máy.
   - Chuyển sang **chọn thủ công** một thành phố khác → lịch nhóm đổi giờ hiển thị.
   - Mở MongoDB Compass: `users.timezone`, `timezone_auto`, `timezone_city` đã đổi theo.
   - Đổi lại tự động.

🗣️ "Múi giờ lưu **trên server** và là nguồn chuẩn. Đăng nhập trên máy nào cũng hiển thị giống nhau.
Server dùng múi giờ này để tính 'hôm nay', tính giờ nhắc, tính giờ rảnh.
Backend nhúng sẵn **dữ liệu múi giờ IANA bản mới nhất** (`utils/tzdata/zoneinfo.zip`).
Lý do: dữ liệu múi giờ đi kèm Go đã cũ, tính sai giờ Vancouver 1 tiếng. Chi tiết ở phần vấn đề đã gặp."

### Cảnh 8. Hồ sơ và Cài đặt (SET-01, SET-02, AU-05 → AU-07) (3 phút)

🎬

1. Hồ sơ:
   - Đổi **ảnh đại diện**: chọn ảnh, tải lên Cloudinary.
   - Đổi tên hiển thị. Thử tên trùng với người khác → báo lỗi.
2. **Chế độ tối/sáng** (SET-01):
   - Bật tối rồi tắt.
   - Đóng hẳn app, mở lại → **màn hình khởi động theo đúng giao diện đã chọn**, kể cả khi điện thoại đang ở chế độ tối.
3. **Ngôn ngữ** (SET-02): Tiếng Việt → English → Français. Mọi chữ đổi, cả thông báo lỗi từ server.
4. Trợ giúp: **Gửi thông báo thử**, **Xem lại hướng dẫn**.
5. Đổi mật khẩu (AU-05): sai mật khẩu cũ → báo lỗi. Đổi xong thì các phiên khác bị đăng xuất.
6. **Xoá tài khoản** (AU-07): mở màn hình xem trước "chuyện gì sẽ xảy ra với từng nhóm"
   (rời nhóm, chuyển quyền trưởng, hoặc giải tán). Làm với tài khoản `demo1` vừa tạo, **không xoá Nga**.

### Cảnh 9. Admin (dùng Postman) (2 phút)

🎬

1. Đăng nhập `admin@timetribe.com` trong Postman, lấy access token.
2. Gọi `POST /api/v1/admin/notifications/broadcast` với title và content.
   Tất cả người dùng nhận thông báo đẩy, và thông báo nằm trong danh sách.
3. Trên điện thoại, đọc thông báo đó → **chỉ Nga** chuyển sang đã đọc. Trên máy ảo, người khác vẫn thấy chưa đọc.
4. Gọi `PATCH /api/v1/admin/users/:id/ban` để khoá một tài khoản → server xoá refresh token của tài khoản đó, nên phiên hết hạn là bị đẩy ra và không đăng nhập lại được.

🗣️ "Thông báo chung chỉ lưu **một bản** (`user_id = null`). Trạng thái đã đọc lưu theo từng người trong mảng `read_by`.
Không phải nhân ra một bản cho mỗi người dùng."

### Cảnh 10. Một tài khoản – một thiết bị (1 phút)

🎬 Trên máy ảo đăng nhập **Tuyết Nga**. Quay lại điện thoại, bấm bất kỳ chỗ nào
→ báo **"Phiên đăng nhập đã kết thúc, có thể tài khoản vừa đăng nhập trên máy khác"** và về màn hình đăng nhập.
Sau đó đăng nhập lại Nga trên điện thoại.

🗣️ "Access token mang id phiên trong claim `jti`. Đăng nhập mới thì phiên cũ bị xoá, máy cũ nhận 401 `session_ended`.
Như vậy thông báo đẩy luôn về đúng một máy đang dùng."

### Cảnh 11. Hậu trường: code và database (3 phút)

🎬

1. MongoDB Compass, đi qua các collection:
   - `users`, `user_securities` (tách thông tin đăng nhập ra bảng riêng).
   - `timeblocks`, `templates`, `template_blocks`.
   - `tribes`, `tribe_attendees`, `tribe_blocks`, `tribe_block_attendance`.
   - `notifications`, `user_tokens`.
   - Hai bảng kỹ thuật: `worker_state` và `reminder_logs` (có TTL tự xoá sau 3 ngày).
2. Mở `backend/internal/handlers/routes.go`: toàn bộ API trong một file.
3. Mở `services/reminder.go`: hàm `due()` và `claim()`.
4. Chạy test:

```bash
go test ./...
```

   Có test nhắc lịch cho giờ Việt Nam và giờ Vancouver, và test dữ liệu múi giờ.

### Cảnh 12. Kết (30 giây)

🗣️ Tóm tắt 3 điểm đã làm được: xếp lịch nhóm đa múi giờ, nhắc lịch tin cậy (không trùng, không sót), trải nghiệm cho người mới.
Hướng phát triển: gói đăng ký (đã có loại thông báo `subscription_reminder`), đồng bộ Google Calendar, chat nhóm, bản iOS.

---

## 3. Hành trình phát triển và các vấn đề đã gặp

Phần này nên nói thành một đoạn trong video (2–3 phút, sau cảnh 0 hoặc trước cảnh 11),
và chuẩn bị kỹ để trả lời khi thầy cô hỏi.

### 3.1. Giai đoạn 1: làm frontend trước, dùng dữ liệu giả

- Dựng toàn bộ giao diện Flutter theo MVVM với Provider.
  Dữ liệu giả đặt trong ViewModel và các file mock (`tribe_mock_data.dart`, mẫu trong `template_viewmodel.dart`).
- Giải quyết các bài toán giao diện:
  - **Khối lịch trùng giờ đè lên nhau** → viết thuật toán chia cột `OverlapLayout` (gom cụm, đặt vào cột trống).
  - **Hiển thị giờ bận của nhóm** → `availability_calculator.dart` tính đoạn bận/rảnh, `HatchPainter` vẽ sọc chéo.
  - **Lưới thời gian, vạch giờ hiện tại** → `time_grid_calculator.dart`, `current_time_line.dart`.
  - **Đa ngôn ngữ** → file arb vi/en/fr.
- Lợi ích: chốt được luồng màn hình và quy tắc nghiệp vụ (giới hạn 5 nhóm, 10 người, 3 phó nhóm,
  tối thiểu 5 phút, nhắc 0/5/10/15/30/60 phút) **trước khi** viết API.

### 3.2. Giai đoạn 2: làm backend và nối API

- Thiết kế CSDL 11 bảng, ánh xạ sang MongoDB, giữ tên cột snake_case giống bản thiết kế.
- Viết backend Go theo lớp Handler → Service → Repository. Lỗi nghiệp vụ trả **mã lỗi** (`overlap`, `tribe_full`...),
  app dịch ra câu thông báo theo ngôn ngữ, nên backend không phụ thuộc ngôn ngữ hiển thị.
- **Không dùng transaction**, vì MongoDB chạy đơn lẻ không hỗ trợ. Chỗ ghi nhiều collection thì ghi lần lượt,
  lỗi giữa chừng thì tự dọn bản ghi vừa tạo.
- Thay toàn bộ dữ liệu giả bằng API, xoá các file mock. Chỉ giữ `cmd/seed` để nạp dữ liệu mẫu vào MongoDB.
- Xác thực: JWT + refresh token băm, đăng nhập Google qua Firebase, một tài khoản một phiên.

### 3.3. Các vấn đề cụ thể và cách giải quyết

| # | Vấn đề | Nguyên nhân | Cách giải quyết |
|---|---|---|---|
| 1 | **Xung đột thời gian giữa các múi giờ.** Cùng một hoạt động nhóm, mỗi người thấy giờ khác nhau và tính sai ai bận | Lúc đầu lưu tất cả theo giờ địa phương | Tách hai loại: **lịch cá nhân lưu giờ địa phương** của chủ lịch, **lịch nhóm lưu UTC**. Mọi phép so sánh trùng/bận đổi ra **khoảng thời gian tuyệt đối** (`TimeRange` với `Overlaps`, `Clip`) rồi mới so. Lấy dữ liệu rộng ra ±2 ngày vì lệch múi giờ có thể sang ngày khác |
| 2 | **Lịch qua nửa đêm** (ví dụ 23:00 tới 01:00) | Giờ kết thúc nhỏ hơn giờ bắt đầu | Quy ước: kết thúc ≤ bắt đầu nghĩa là sang ngày hôm sau (`UTCRange`, `LocalRange`) |
| 3 | **Thông báo không đúng giờ / lệch 1 tiếng**, lịch "hiện mờ" sai ngày | (a) Múi giờ chọn trên máy khác múi giờ lưu trong DB. (b) Dữ liệu tzdata đi kèm Go đã cũ: tính Vancouver tháng 11/2026 là UTC−8, trong khi British Columbia đã giữ giờ UTC−7 quanh năm. (c) App không tự đổi "hôm nay" khi qua nửa đêm | (a) **Server là nguồn chuẩn** cho múi giờ (`timezone`, `timezone_auto`, `timezone_city`). App đồng bộ khi đăng nhập, và khi máy đổi múi giờ. (b) **Nhúng tzdata IANA bản mới** vào backend bằng `go:embed`, có test kiểm tra. (c) Thêm bộ theo dõi đổi ngày (`AppTime.startDayWatcher`) |
| 4 | **Server tắt đúng lúc tới giờ nhắc → mất thông báo** | Worker chỉ nhớ mốc quét trong RAM | Lưu mốc quét vào `worker_state`. Bật lại thì **quét bù** tối đa 24 giờ. Hoạt động đã bắt đầu quá 5 phút thì chỉ ghi vào danh sách, không đẩy |
| 5 | **Nhắc trùng**, hoặc **nhắc trễ tới 59 giây** | Ticker chạy lệch giây; quét chồng hoặc nhiều server cùng chạy | Canh đúng giây :00 mỗi phút. Ghi `reminder_logs` với khoá duy nhất `lịch|người|mốc` (index unique + TTL 3 ngày). Đổi giờ lịch thì mốc đổi, nên vẫn nhắc lại theo giờ mới |
| 6 | **Không nhận thông báo đẩy** | `fcm_token` null: token chỉ gửi khi đăng nhập thủ công, còn tự đăng nhập bằng phiên cũ thì không gửi. Token còn bị xoá nhầm khi FCM báo lỗi khác | App **gửi token mỗi lần vào trang chủ**. Server chỉ xoá token khi FCM báo token hết hiệu lực (`registration-token-not-registered`, `sender-id-mismatch`) |
| 7 | **Thông báo không nổi lên, không kêu** | Dùng kênh thông báo mặc định có độ ưu tiên thấp | Tạo kênh Android riêng `timetribe_alerts` với `IMPORTANCE_HIGH`. Server gửi `priority: high`, có channel id, icon và màu |
| 8 | **App đang mở thì không có thông báo ngoài** | Firebase **không tự hiện** thông báo khi app ở foreground | Nhận tin ở foreground → gọi code Kotlin qua `MethodChannel` để **tự đăng thông báo hệ thống**, kèm banner trong app. Bấm thông báo → mở tab Thông báo |
| 9 | **Chọn giao diện sáng nhưng màn hình khởi động vẫn tối** | Splash là của Android, theo giao diện của hệ thống, chạy trước khi Flutter đọc cài đặt | Khi đổi theme, Flutter gọi Kotlin (`UiModeManager.setApplicationNightMode`) để Android nhớ chế độ cho app. Tắt `forceDarkAllowed` |
| 10 | **Thông báo chung đọc rồi vẫn hiện chưa đọc** | Thông báo chung dùng chung một bản ghi, nên `is_read` dùng chung cho mọi người | Thêm mảng `read_by`, trạng thái đã đọc tính theo từng người |
| 11 | **Người mới không biết dùng** | Chưa có hướng dẫn | Màn hình chào mừng, trang giới thiệu lợi ích, chọn "đã biết / người mới", và hướng dẫn từng bước bằng `tutorial_coach_mark`. Cờ `needs_onboarding` lưu trên server |
| 12 | **Đăng nhập nhiều máy thì thông báo về sai máy** | — | Một tài khoản một phiên, `jti` trong JWT, máy cũ nhận `session_ended` |

---

## 4. Câu hỏi có thể bị hỏi

**Kiến trúc và công nghệ**

- *Vì sao chọn Flutter?* Một code chạy Android/iOS/web. Hot reload giúp làm giao diện nhanh. Có sẵn plugin Firebase.
- *Vì sao chọn Go?* Biên dịch ra một file chạy, nhanh, ít tốn RAM. Goroutine hợp để chạy worker nhắc lịch song song với API. Kiểu dữ liệu chặt.
- *Vì sao MongoDB mà thiết kế CSDL lại theo bảng quan hệ?* Thiết kế logic giữ đúng 11 bảng, mỗi bảng thành một collection và giữ quan hệ bằng id.
  MongoDB linh hoạt khi thêm trường mới (`read_by`, `timezone_auto`) mà không cần migration.
  Đổi lại thì không có khoá ngoại và (ở chế độ chạy đơn lẻ) không có transaction. Nhóm xử lý bằng cách kiểm tra ở service và dọn bản ghi khi lỗi.
- *MVVM là gì trong app?*
  - View là các màn hình `views/`.
  - ViewModel là `ChangeNotifier`, giữ trạng thái và gọi API.
  - Model là các class trong `models/`.
  - Provider cung cấp ViewModel cho cây widget. Khi ViewModel gọi `notifyListeners`, View vẽ lại.
- *Vì sao còn bảng `worker_state` và `reminder_logs` ngoài 11 bảng?* Đó là bảng kỹ thuật của bộ nhắc lịch, không phải dữ liệu nghiệp vụ,
  nên không vẽ trong ERD nghiệp vụ, chỉ có trong sơ đồ vật lý. `reminder_logs` tự xoá sau 3 ngày.

**Múi giờ, xung đột thời gian**

- *Người ở Tokyo tạo hoạt động 9h sáng, người ở Việt Nam thấy mấy giờ?* 7h sáng. Server lưu UTC (00:00), mỗi app tự đổi ra giờ máy.
- *Người dùng bay sang nước khác thì sao?* Chế độ tự động: app phát hiện múi giờ máy đổi và cập nhật lên server.
  Lịch cá nhân giữ nguyên giờ địa phương (8h sáng vẫn là 8h sáng), lịch nhóm đổi giờ hiển thị cho đúng mốc tuyệt đối.
- *Lịch cá nhân trùng với lịch nhóm thì có bị chặn không?* Không. Chỉ chặn khi **hai lịch cá nhân** trùng nhau.
  Lịch nhóm do người khác tạo nên chỉ cảnh báo (sọc bận, "N người đang bận"), và hiện cạnh nhau trên lịch.
  Người dùng tự quyết bằng nút Tham gia / Từ chối.
- *Tính giờ rảnh có lộ lịch riêng không?* Không. API chỉ trả **khoảng thời gian bận**, không trả tên hay nội dung lịch.
- *Kiểm tra trùng giờ chạy ở đâu?* Ở cả app (phản hồi nhanh) và server (bắt buộc, trả 409).

**Thông báo**

- *Nhắc lịch hoạt động thế nào?* Worker goroutine, quét đầu mỗi phút, tìm mốc `start − remind` trong khoảng (lần quét trước, bây giờ].
  Ghi `notifications`, gửi FCM, chống trùng bằng `reminder_logs`.
- *Server sập lúc tới giờ thì sao?* Nhắc bù khi bật lại (tối đa 24 giờ). Đã quá giờ bắt đầu thì chỉ lưu, không đẩy.
- *Chạy 2 server thì có gửi 2 lần không?* Không, vì khoá unique trong `reminder_logs`. Server nào ghi được trước thì gửi.
- *Vì sao app đang mở mà vẫn hiện thông báo ngoài?* FCM không tự hiện khi app ở foreground. App tự đăng thông báo qua code Android gốc (MethodChannel).
- *Gỡ app cài lại có nhận thông báo không?* Có. Token mới được gửi lên ngay khi vào trang chủ.

**Bảo mật**

- *Mật khẩu lưu thế nào?* bcrypt. Refresh token và token đặt lại mật khẩu chỉ lưu bản băm SHA-256.
- *Đổi mật khẩu thì token cũ còn dùng được không?* Không. Mọi access token cấp trước thời điểm đổi đều bị từ chối.
- *Phân quyền?* Middleware JWT cho mọi API cần đăng nhập. `AdminOnly` cho API admin. Quyền trong nhóm (trưởng/phó/thành viên) kiểm tra trong service.
- *File bí mật?* `.env` và `serviceAccountKey.json` nằm trong `.gitignore`, không commit.

**Kiểm thử, giới hạn**

- *Test thế nào?*
  - Unit test Go cho phần khó: hàm `due`, nhắc lịch theo giờ Việt Nam và Vancouver, tzdata.
  - Postman collection cho toàn bộ API (`backend/postman`, `API_TESTING.md`).
  - Seed dữ liệu để test tay.
- *Hạn chế hiện tại?*
  - Chưa có giao diện admin trong app (đang dùng Postman).
  - Chưa test tự động phía Flutter.
  - MongoDB chạy đơn lẻ nên không có transaction.
  - iOS chưa kiểm thử push.
  - Thông báo chỉ giữ 30 ngày.
- *Nếu có nhiều người dùng?* Đã có index trên các trường hay truy vấn. Worker chỉ đọc lịch trong khoảng ±1–2 ngày.
  Có thể tách worker ra tiến trình riêng, và đổi MongoDB sang replica set để có transaction.

---

## 5. Phụ lục

### 5.1. Tài khoản (mật khẩu chung `123456`)

| Tên | Email | Múi giờ | Vai trò trong demo |
|---|---|---|---|
| admin | admin@timetribe.com | VN | Admin, gửi thông báo chung, khoá tài khoản |
| **Tuyết Nga** | tuyetnga@timetribe.app | theo `-tz` | Nhân vật chính. Trưởng nhóm NIC, phó nhóm Marketing |
| **Minh Trần** | minh.tran@timetribe.app | VN | Phó nhóm NIC, phó nhóm Cầu lông |
| **Linh Phạm** | linh.pham@timetribe.app | VN | Trưởng nhóm Marketing, có mẫu STUDYWEEK |
| Hana Sato | hana.sato@timetribe.app | Tokyo | So sánh giờ hiển thị |
| David Nguyen | david.nguyen@timetribe.app | Vancouver | Đã từ chối hoạt động demo |
| Khoa Đỗ | khoa.do@timetribe.app | London | Đa múi giờ |
| Vy Ngô | vy.ngo@timetribe.app | Sydney | Đa múi giờ |
| An Lê, Mai Võ, Tuấn Hồ, Phúc Lâm | an.le@…, mai.vo@…, tuan.ho@…, phuc.lam@… | VN | Thành viên |
| **Người Mới** | nguoimoi@timetribe.app | theo `-tz` | Chưa xem hướng dẫn, chưa có nhóm |
| spam.bot | spam.bot@timetribe.app | VN | Bị khoá |
| Bảo Ngọc | baongoc.gg@gmail.com | VN | Tài khoản Google (không có mật khẩu) |

### 5.2. Mã mời nhóm và mã lịch mẫu

| Nhóm | Mã mời | Thành viên |
|---|---|---|
| Đồ án NIC | `NIC2026` | 6 |
| CLB Cầu lông Q7 | `CAULONGQ7` | 4 |
| Team Marketing Global | `MKTGLOBAL` | 8 |
| Hội Game Dev | `GAMEDEV26` | 3 |
| Nhóm đã đủ người | `FULLHOUSE` | 10 (đầy) |

Lịch mẫu chia sẻ: `GYM4DAY` (của Nga), `STUDYWEEK` (của Linh).

### 5.3. Giới hạn nghiệp vụ (nên nhớ khi bị hỏi)

| Quy tắc | Giá trị |
|---|---|
| Số nhóm mỗi người được tham gia | tối đa 5 |
| Số thành viên mỗi nhóm | tối đa 10 |
| Số phó nhóm mỗi nhóm | tối đa 3 |
| Số lịch mẫu mỗi người | tối đa 10 |
| Áp dụng lịch mẫu | 1–12 tuần |
| Thời lượng lịch tối thiểu | 5 phút |
| Tên lịch | 2–100 ký tự |
| Ghi chú | tối đa 300 ký tự |
| Nhắc trước | 0 / 5 / 10 / 15 / 30 / 60 phút (lịch cá nhân mặc định 15, lịch nhóm mặc định 60) |
| Khung giờ gợi ý cả nhóm rảnh | từ 30 phút trở lên |
| Danh sách thông báo | 30 ngày gần nhất |
| Nhắc bù khi server tắt | tối đa 24 giờ; đã bắt đầu quá 5 phút thì không đẩy |

### 5.4. Bản đồ chức năng ↔ code

| Mã | Chức năng | Backend | Frontend |
|---|---|---|---|
| AU-01…07 | Đăng ký, đăng nhập, Google, quên/đặt lại mật khẩu, đổi mật khẩu, đăng xuất, xoá tài khoản | `services/auth_service.go`, `user_service.go` | `features/auth`, `settings/delete_account_screen.dart` |
| Lịch cá nhân | Thêm/sửa/xoá, trùng giờ, nhân bản, lịch theo ngày/tháng | `services/timeblock_service.go` | `features/timeblock`, `core/widgets/calendar` |
| TP-01…09 | Lịch mẫu: danh sách, tạo, nhập mã, sửa, xoá, chia sẻ, áp dụng | `services/template_service.go` | `features/template` |
| COM-01…19 | Nhóm, thành viên, vai trò, hoạt động nhóm, giờ rảnh, trả lời | `services/tribe_service.go`, `tribe_block_service.go` | `features/tribe` |
| NOTI-01/02 | Danh sách thông báo, đánh dấu đã đọc | `services/notification_service.go`, `reminder.go`, `firebase.go` | `features/notifications`, `core/services/push_service.dart`, `MainActivity.kt` |
| SET-01/02 | Chế độ tối, ngôn ngữ | — | `core/theme/theme_provider.dart`, `core/l10n/locale_provider.dart` |
| Onboarding | Chào mừng, hướng dẫn | `users.needs_onboarding` | `features/onboarding` |

---

## 6. Checklist ngay trước khi bấm quay

- [ ] MongoDB đang chạy.
- [ ] Đã chạy `go run ./cmd/seed -demo -tz <múi giờ điện thoại> -lead 12` và chụp lịch trình demo.
- [ ] `go run ./cmd/server` đang chạy. Mở `http://localhost:8080/health`: `firebase_push: true`.
- [ ] Điện thoại: đăng nhập Tuyết Nga, "Gửi thông báo thử" đã hiện ra.
- [ ] Máy ảo: đã đăng xuất, sẵn sàng đăng ký tài khoản mới.
- [ ] Postman: đã đăng nhập admin.
- [ ] Đã tắt thông báo của các app khác (chế độ không làm phiền trừ TimeTribe). Âm lượng thông báo bật.
- [ ] Điện thoại để giao diện **sáng**, ngôn ngữ **Tiếng Việt**.
- [ ] Nếu quay hỏng, chạy lại seed để làm lại từ đầu (dữ liệu và ID không đổi giữa các lần seed).
