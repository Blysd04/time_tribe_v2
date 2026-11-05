# TimeTribe

Ứng dụng quản lý lịch cá nhân và lịch nhóm (Tribe), hỗ trợ nhiều múi giờ
và 3 ngôn ngữ: Tiếng Việt, English, Français.

## Chạy app

```bash
flutter pub get
flutter run
```

Tài khoản mẫu: `admin` (hoặc `admin@timetribe.com`), mật khẩu `123456`.

## Cấu trúc thư mục

```
lib/
├── core/                      # Dùng chung cho mọi tính năng
│   ├── l10n/                  # context.l10n, LocaleProvider (đổi ngôn ngữ)
│   ├── models/                # AppUser
│   ├── session/               # Người dùng đang đăng nhập
│   ├── theme/                 # AppColors, AppTheme, ThemeProvider
│   ├── utils/                 # AppTime (múi giờ), Fmt (định dạng), OverlapLayout...
│   └── widgets/               # AppCard, AppSection, AppDialogs, AppSnack, form widgets
│       └── calendar/          # CalendarPanel, DayStrip, TimeGrid, TimeblockCard
├── features/<tính năng>/
│   ├── models/                # Khớp bảng trong database (fromJson/toJson)
│   ├── viewmodels/            # ChangeNotifier, chứa logic + TODO(backend)
│   ├── data/ hoặc services/   # Dữ liệu giả lập / thuật toán thuần (có test)
│   └── views/                 # Màn hình
│       └── widgets/           # Widget riêng của tính năng
└── l10n/                      # app_vi.arb (gốc), app_en.arb, app_fr.arb + gen/
```

## Quy ước giao diện

- Màu, bo góc, ô nhập, nút, hộp thoại lấy từ `AppTheme` — không tự ghi mã màu.
- Danh sách dạng thẻ dùng `AppCard`; trang cài đặt/hồ sơ dùng `AppSection` + `AppListTile`.
- Xác nhận dùng `AppDialogs.confirm`, thông báo nhanh dùng `AppSnack.show`.
- Hộp thoại có ô nhập dùng `showInputDialog` (tự quản lý controller, báo lỗi ngay trong hộp thoại).
- Lịch dùng chung `CalendarPanel` + `TimeGrid` + `gridBlock` + `OverlapLayout`
  (khối trùng giờ tự chia cột).
- Trang form: nút đóng (X) bên trái, "Lưu" bên phải, nút xoá màu đỏ.

## Đa ngôn ngữ

Chuỗi hiển thị nằm trong `lib/l10n/*.arb`. Thêm chuỗi mới vào cả 3 file
(file `app_vi.arb` là bản gốc, khai báo tham số), rồi chạy `flutter gen-l10n`
(hoặc `flutter run` sẽ tự sinh). Dùng trong code: `context.l10n.tenChuoi`.

## Múi giờ

- `AppTime.now()` luôn theo múi giờ trong Profile (tự động theo thiết bị hoặc chọn tay).
- Hoạt động nhóm (`tribe_blocks`) lưu theo **UTC**; mỗi người xem được quy đổi sang giờ của mình.
- Lịch cá nhân (`timeblocks`) lưu theo múi giờ của chủ sở hữu (`users.timezone`).
