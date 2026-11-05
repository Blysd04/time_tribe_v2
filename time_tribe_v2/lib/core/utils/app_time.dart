import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Nguồn thời gian DUY NHẤT của toàn app.
///
/// - Chế độ tự động: lấy trực tiếp đồng hồ + múi giờ của thiết bị
///   (`DateTime.now()`), không phụ thuộc dữ liệu database hay giao diện.
/// - Chế độ thủ công: quy đổi giờ UTC sang múi giờ IANA người dùng chọn
///   trong Profile (VD: `Asia/Tokyo`), có tính cả giờ mùa hè (DST).
///
/// [now] luôn trả về một `DateTime` "giờ treo tường" (wall-clock) của múi giờ
/// đang áp dụng, nên mọi chỗ dùng `.hour`, `.day`, `DateTime(y, m, d)` đều
/// đồng nhất với nhau.
///
/// Mọi màn hình cần hiển thị theo giờ hiện tại nên lắng nghe [changes] để
/// vẽ lại khi người dùng đổi múi giờ.
class AppTime {
  AppTime._();

  static bool _tzDataLoaded = false;
  static bool _isAuto = true;
  static tz.Location? _manualLocation;

  /// Tăng giá trị mỗi khi cấu hình múi giờ thay đổi.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// Nạp cơ sở dữ liệu múi giờ IANA. Gọi 1 lần trong `main()`.
  static void ensureInitialized() {
    if (_tzDataLoaded) return;
    tzdata.initializeTimeZones();
    _tzDataLoaded = true;
  }

  static bool get isAuto => _isAuto || _manualLocation == null;

  /// Múi giờ IANA đang áp dụng thủ công (null nếu đang theo thiết bị).
  static String? get manualTimezoneId => isAuto ? null : _manualLocation!.name;

  /// Chuyển sang dùng múi giờ của thiết bị.
  static void useDeviceTimezone() {
    _isAuto = true;
    _manualLocation = null;
    notifyChanged();
  }

  /// Dùng múi giờ IANA cố định (VD: `America/Vancouver`).
  /// Trả về `false` nếu ID không hợp lệ (khi đó giữ nguyên cấu hình cũ).
  static bool useTimezone(String ianaId) {
    final location = findLocation(ianaId);
    if (location == null) return false;
    _isAuto = false;
    _manualLocation = location;
    notifyChanged();
    return true;
  }

  /// Báo cho các widget đang lắng nghe biết cần vẽ lại
  /// (VD: khi múi giờ của thiết bị vừa thay đổi lúc app chạy nền).
  static void notifyChanged() => changes.value++;

  static tz.Location? findLocation(String ianaId) {
    ensureInitialized();
    try {
      return tz.getLocation(ianaId);
    } catch (_) {
      return null;
    }
  }

  /// Thời gian hiện tại theo múi giờ đang áp dụng.
  static DateTime now() {
    if (isAuto) return DateTime.now();
    final t = tz.TZDateTime.now(_manualLocation!);
    return DateTime(
      t.year,
      t.month,
      t.day,
      t.hour,
      t.minute,
      t.second,
      t.millisecond,
      t.microsecond,
    );
  }

  // ---------------------------------------------------------------------------
  // QUY ĐỔI GIỮA CÁC MÚI GIỜ (dùng cho lịch nhóm có thành viên ở nhiều nơi)
  // ---------------------------------------------------------------------------

  /// Đổi "giờ treo tường" sang mốc UTC.
  /// [timezoneId] = null nghĩa là múi giờ đang áp dụng trong Profile.
  static DateTime toUtc(DateTime wallClock, {String? timezoneId}) {
    if (timezoneId != null) {
      final location = findLocation(timezoneId);
      if (location != null) {
        return tz.TZDateTime(
          location,
          wallClock.year,
          wallClock.month,
          wallClock.day,
          wallClock.hour,
          wallClock.minute,
        ).toUtc();
      }
    }
    if (isAuto) {
      return DateTime(
        wallClock.year,
        wallClock.month,
        wallClock.day,
        wallClock.hour,
        wallClock.minute,
      ).toUtc();
    }
    return tz.TZDateTime(
      _manualLocation!,
      wallClock.year,
      wallClock.month,
      wallClock.day,
      wallClock.hour,
      wallClock.minute,
    ).toUtc();
  }

  /// Đổi mốc UTC sang giờ treo tường của múi giờ đang áp dụng
  /// (hoặc của [timezoneId] nếu truyền vào).
  static DateTime fromUtc(DateTime utc, {String? timezoneId}) {
    final u = utc.toUtc();
    tz.Location? location;
    if (timezoneId != null) {
      location = findLocation(timezoneId);
    } else if (!isAuto) {
      location = _manualLocation;
    }
    if (location == null) {
      final l = u.toLocal();
      return DateTime(l.year, l.month, l.day, l.hour, l.minute, l.second);
    }
    final t = tz.TZDateTime.from(u, location);
    return DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
  }

  /// Giờ hiện tại ở một múi giờ khác (VD: giờ của thành viên ở Tokyo).
  static DateTime nowIn(String timezoneId) =>
      fromUtc(DateTime.now().toUtc(), timezoneId: timezoneId);

  /// Độ lệch GMT của một múi giờ, dạng chữ. VD `GMT+09:00`.
  static String offsetLabelOf(String timezoneId) {
    final offset = offsetOf(timezoneId);
    return offset == null ? timezoneId : formatOffset(offset);
  }

  /// Mốc 00:00 của ngày hôm nay theo múi giờ đang áp dụng.
  static DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Giờ/phút hiện tại (dùng cho Picker).
  static TimeOfDay timeOfDayNow() {
    final dt = now();
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  /// Độ lệch so với UTC của múi giờ đang áp dụng (đã tính DST).
  static Duration get currentOffset => isAuto
      ? DateTime.now().timeZoneOffset
      : tz.TZDateTime.now(_manualLocation!).timeZoneOffset;

  /// Độ lệch UTC hiện tại của một múi giờ IANA bất kỳ.
  static Duration? offsetOf(String ianaId) {
    final location = findLocation(ianaId);
    if (location == null) return null;
    return tz.TZDateTime.now(location).timeZoneOffset;
  }

  /// Định dạng độ lệch: `GMT+07:00`, `GMT-08:00`, `GMT+05:30`.
  static String formatOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final totalMinutes = offset.inMinutes.abs();
    final hh = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final mm = (totalMinutes % 60).toString().padLeft(2, '0');
    return 'GMT$sign$hh:$mm';
  }
}
