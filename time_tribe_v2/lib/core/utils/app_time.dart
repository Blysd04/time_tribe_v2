import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Nguồn thời gian duy nhất của toàn app.
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

  /// Tăng giá trị khi server vừa đổi múi giờ của tài khoản: server đã tính lại ngày giờ
  /// của lịch cá nhân theo múi giờ mới, lịch trên máy cần tải lại.
  static final ValueNotifier<int> scheduleShifted = ValueNotifier<int>(0);

  /// Nạp cơ sở dữ liệu múi giờ IANA. Gọi 1 lần trong `main()`.
  static void ensureInitialized() {
    if (_tzDataLoaded) return;
    tzdata.initializeTimeZones();
    _tzDataLoaded = true;
  }

  /// Đang để múi giờ tự động theo thiết bị hay không.
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

  static Timer? _dayWatcher;
  static DateTime? _lastDay;

  /// Theo dõi lúc sang ngày mới (app để mở qua nửa đêm): báo [changes] để
  /// "Hôm nay", vạch giờ hiện tại và lịch đang xem chuyển sang ngày mới. Gọi 1 lần trong `main()`.
  static void startDayWatcher() {
    _lastDay = today();
    _dayWatcher ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => checkDayChanged(),
    );
  }

  /// Kiểm tra đã sang ngày mới chưa (cũng gọi khi app quay lại từ nền).
  static void checkDayChanged() {
    final t = today();
    final changed = _lastDay != null && t != _lastDay;
    _lastDay = t;
    if (changed) notifyChanged();
  }

  /// Báo cho các widget đang lắng nghe biết cần vẽ lại
  /// (VD: khi múi giờ của thiết bị vừa thay đổi lúc app chạy nền).
  static void notifyChanged() => changes.value++;

  /// Tìm múi giờ theo tên IANA (ví dụ Asia/Tokyo), không có thì trả null.
  static tz.Location? findLocation(String ianaId) {
    ensureInitialized();
    try {
      return tz.getLocation(ianaId);
    } catch (_) {
      return null;
    }
  }

  /// Tên múi giờ IANA chắc chắn khớp với độ lệch hiện tại của thiết bị.
  ///
  /// Một số máy trả về tên lạ (VD `GMT+08:00`) hoặc tên không khớp với giờ đang hiện
  /// trên máy. Gửi tên đó lên thì server từ chối hoặc tính sai giờ nhắc lịch, nên:
  /// tên hợp lệ và đúng độ lệch thì giữ, không thì đổi sang `Etc/GMT±N`
  /// (lưu ý dấu ngược: `Etc/GMT-7` là UTC+7), lệch lẻ phút thì tìm một múi giờ cùng độ lệch.
  static String resolveDeviceTimezone(String? id) {
    ensureInitialized();
    final offset = DateTime.now().timeZoneOffset;
    if (id != null && id.isNotEmpty) {
      final location = findLocation(id);
      if (location != null &&
          tz.TZDateTime.now(location).timeZoneOffset == offset) {
        return id;
      }
    }
    if (offset.inMinutes % 60 == 0) {
      final h = offset.inHours;
      if (h == 0) return 'Etc/UTC';
      return 'Etc/GMT${h > 0 ? '-' : '+'}${h.abs()}';
    }
    for (final location in tz.timeZoneDatabase.locations.values) {
      if (tz.TZDateTime.now(location).timeZoneOffset == offset) {
        return location.name;
      }
    }
    return id ?? 'Etc/UTC';
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
  // Quy đổi giữa các múi giờ (dùng cho lịch nhóm có thành viên ở nhiều nơi)
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
