import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/app_time.dart';

class ProfileViewModel extends ChangeNotifier with WidgetsBindingObserver {
  static const _kAutoKey = 'profile.timezone.auto';
  static const _kTimezoneIdKey = 'profile.timezone.id';
  static const _kCityKey = 'profile.timezone.city';
  static const _kCountryKey = 'profile.timezone.country';

  String _name = "Van Dang Tuyet Nga";
  String _email = "admin@timetribe.com";

  bool _isAutoTimezone = true;

  /// Múi giờ IANA người dùng chọn thủ công (VD: `Asia/Tokyo`).
  String? _manualTimezoneId;

  /// Thành phố + mã quốc gia khi chọn thủ công (tên quốc gia dịch ở giao diện).
  String? _manualCity;
  String? _manualCountry;

  /// Múi giờ IANA đọc từ cài đặt của thiết bị.
  String? _deviceTimezoneId;

  ProfileViewModel() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Đọc cấu hình đã lưu + múi giờ thiết bị. Gọi trước `runApp`.
  Future<void> init() async {
    await refreshDeviceTimezone(notify: false);
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAutoTimezone = prefs.getBool(_kAutoKey) ?? true;
      _manualTimezoneId = prefs.getString(_kTimezoneIdKey);
      _manualCity = prefs.getString(_kCityKey);
      _manualCountry = prefs.getString(_kCountryKey);
    } catch (_) {
      // Không đọc được bộ nhớ -> mặc định theo thiết bị.
    }
    _applyToAppTime();
  }

  String get name => _name;
  String get email => _email;
  bool get isAutoTimezone => _isAutoTimezone;
  String? get manualTimezoneId => _manualTimezoneId;
  String? get manualCity => _manualCity;
  String? get manualCountry => _manualCountry;
  String? get deviceTimezoneId => _deviceTimezoneId;

  /// Múi giờ IANA đang có hiệu lực -> giá trị gửi lên `users.timezone`.
  String get timezone => _isAutoTimezone
      ? (_deviceTimezoneId ?? DateTime.now().timeZoneName)
      : (_manualTimezoneId ?? 'Asia/Ho_Chi_Minh');

  /// Độ lệch GMT hiện tại của múi giờ đang áp dụng, VD `GMT+07:00`.
  String get timezoneOffset => AppTime.formatOffset(AppTime.currentOffset);

  /// Độ lệch GMT hiện tại của thiết bị.
  String get deviceTimezoneOffset =>
      AppTime.formatOffset(DateTime.now().timeZoneOffset);

  /// Tên hiển thị của múi giờ thiết bị.
  String get deviceTimezoneLabel =>
      _deviceTimezoneId ?? DateTime.now().timeZoneName;

  /// Đọc lại múi giờ của thiết bị từ hệ điều hành.
  Future<void> refreshDeviceTimezone({bool notify = true}) async {
    String? id;
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      id = info.identifier;
    } catch (_) {
      id = null; // Nền tảng không hỗ trợ -> dùng tên viết tắt của Dart.
    }
    final changed = id != _deviceTimezoneId;
    _deviceTimezoneId = id;
    if (notify) {
      // Múi giờ thiết bị có thể đã đổi khi app chạy nền -> vẽ lại mọi màn hình.
      if (_isAutoTimezone) AppTime.notifyChanged();
      if (changed || _isAutoTimezone) notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshDeviceTimezone();
    }
  }

  void updateAvatar() {
    //gọi thư viện ImagePicker
    debugPrint("Mở thư viện ảnh");
  }

  void updateName(String newName) {
    _name = newName;
    notifyListeners();
  }

  void updateEmail(String newEmail) {
    _email = newEmail;
    notifyListeners();
  }

  /// Bật chế độ tự động: lấy múi giờ thực từ cài đặt thiết bị.
  Future<void> useDeviceTimezone() async {
    _isAutoTimezone = true;
    await refreshDeviceTimezone(notify: false);
    _applyToAppTime();
    await _persist();
    notifyListeners();
    // TODO(backend): PATCH /users/me { timezone: deviceTimezoneId }
  }

  /// Chọn thủ công 1 thành phố/múi giờ IANA.
  Future<bool> useManualTimezone(
    String countryCode,
    String city,
    String timezoneId,
  ) async {
    if (AppTime.findLocation(timezoneId) == null) return false;
    _isAutoTimezone = false;
    _manualCountry = countryCode;
    _manualCity = city;
    _manualTimezoneId = timezoneId;
    _applyToAppTime();
    await _persist();
    notifyListeners();
    // TODO(backend): PATCH /users/me { timezone: timezoneId }
    return true;
  }

  void _applyToAppTime() {
    if (_isAutoTimezone || _manualTimezoneId == null) {
      _isAutoTimezone = true;
      AppTime.useDeviceTimezone();
    } else if (!AppTime.useTimezone(_manualTimezoneId!)) {
      _isAutoTimezone = true;
      AppTime.useDeviceTimezone();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAutoKey, _isAutoTimezone);
      if (_manualTimezoneId != null) {
        await prefs.setString(_kTimezoneIdKey, _manualTimezoneId!);
      }
      if (_manualCity != null && _manualCountry != null) {
        await prefs.setString(_kCityKey, _manualCity!);
        await prefs.setString(_kCountryKey, _manualCountry!);
      }
    } catch (_) {
      // Bỏ qua lỗi lưu cục bộ, cấu hình vẫn có hiệu lực trong phiên hiện tại.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
