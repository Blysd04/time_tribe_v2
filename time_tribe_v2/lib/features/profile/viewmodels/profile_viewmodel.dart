import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/utils/app_time.dart';
import '../models/user_model.dart';

/// Lỗi khi sửa hồ sơ, giao diện đổi ra câu chữ theo ngôn ngữ.
enum ProfileError {
  emailInvalid,
  emailTypo,
  emailDomainInvalid,
  emailUnavailable,
  emailTaken,
  nameLength,
  nameTaken,
  network,
  server,
}

class ProfileViewModel extends ChangeNotifier with WidgetsBindingObserver {
  static const _kAutoKey = 'profile.timezone.auto';
  static const _kTimezoneIdKey = 'profile.timezone.id';
  static const _kCityKey = 'profile.timezone.city';
  static const _kCountryKey = 'profile.timezone.country';

  String _name = '';
  String _email = '';
  String? _pendingEmail;
  bool _hasPassword = true;
  String? _emailSuggestion;

  /// Email gợi ý khi server báo email mới có vẻ gõ nhầm tên miền (VD gmial.com -> gmail.com).
  String? get emailSuggestion => _emailSuggestion;
  String? _avatarUrl;
  bool _uploadingAvatar = false;

  bool _isAutoTimezone = true;

  /// Múi giờ IANA người dùng chọn thủ công (VD: `Asia/Tokyo`).
  String? _manualTimezoneId;

  /// Thành phố + mã quốc gia khi chọn thủ công (tên quốc gia dịch ở giao diện).
  String? _manualCity;
  String? _manualCountry;

  /// Múi giờ IANA đọc từ cài đặt của thiết bị.
  String? _deviceTimezoneId;

  ProfileViewModel({ApiClient? api}) : _api = api ?? ApiClient.instance {
    WidgetsBinding.instance.addObserver(this);
  }

  final ApiClient _api;

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

  /// Tên hiển thị của người đang đăng nhập.
  String get name => _name;

  /// Email của người đang đăng nhập.
  String get email => _email;

  /// Email mới đang chờ xác nhận qua link gửi tới hộp thư mới.
  String? get pendingEmail => _pendingEmail;

  /// Tài khoản đã có mật khẩu chưa (tài khoản Google có thể chưa có).
  bool get hasPassword => _hasPassword;

  /// Link ảnh đại diện trên Cloudinary, chưa có ảnh thì null.
  String? get avatarUrl => _avatarUrl;

  /// Đang tải ảnh đại diện lên hay không.
  bool get uploadingAvatar => _uploadingAvatar;

  /// Đang để múi giờ tự động theo thiết bị hay không.
  bool get isAutoTimezone => _isAutoTimezone;

  /// Múi giờ IANA người dùng tự chọn.
  String? get manualTimezoneId => _manualTimezoneId;

  /// Thành phố người dùng tự chọn.
  String? get manualCity => _manualCity;

  /// Mã quốc gia người dùng tự chọn.
  String? get manualCountry => _manualCountry;

  /// Múi giờ IANA đọc từ cài đặt của thiết bị.
  String? get deviceTimezoneId => _deviceTimezoneId;

  /// Múi giờ IANA đang có hiệu lực -> giá trị gửi lên `users.timezone`.
  String get timezone => _isAutoTimezone
      ? (_deviceTimezoneId ?? AppTime.resolveDeviceTimezone(null))
      : (_manualTimezoneId ?? 'Asia/Ho_Chi_Minh');

  /// Độ lệch GMT hiện tại của múi giờ đang áp dụng, VD `GMT+07:00`.
  String get timezoneOffset => AppTime.formatOffset(AppTime.currentOffset);

  /// Độ lệch GMT hiện tại của thiết bị.
  String get deviceTimezoneOffset =>
      AppTime.formatOffset(DateTime.now().timeZoneOffset);

  /// Tên hiển thị của múi giờ thiết bị.
  String get deviceTimezoneLabel =>
      _deviceTimezoneId ?? AppTime.resolveDeviceTimezone(null);

  /// Đọc lại múi giờ của thiết bị từ hệ điều hành.
  Future<void> refreshDeviceTimezone({bool notify = true}) async {
    String? raw;
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      raw = info.identifier;
    } catch (_) {
      raw = null; // Nền tảng không hỗ trợ -> suy ra từ độ lệch giờ của máy.
    }
    // Luôn ra một tên IANA hợp lệ và đúng độ lệch giờ đang hiện trên máy
    final id = AppTime.resolveDeviceTimezone(raw);
    final changed = id != _deviceTimezoneId;
    _deviceTimezoneId = id;
    if (notify) {
      // Múi giờ thiết bị có thể đã đổi khi app chạy nền -> vẽ lại mọi màn hình.
      if (_isAutoTimezone) AppTime.notifyChanged();
      if (changed || _isAutoTimezone) notifyListeners();
    }
    // Server tính giờ nhắc lịch cá nhân theo múi giờ này, lệch là báo sai giờ
    final serverTz = Session.currentUser?.timezone;
    if (_isAutoTimezone && serverTz != null && serverTz != timezone) {
      await _syncTimezone();
    }
  }

  /// App quay lại từ nền thì đọc lại múi giờ thiết bị (người dùng có thể vừa đi sang nước khác).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppTime.checkDayChanged();
      refreshDeviceTimezone();
    }
  }

  /// Gán hồ sơ lấy từ server (sau khi đăng nhập hoặc mở app).
  ///
  /// Cách chọn múi giờ lấy theo CSDL (users.timezone_auto, users.timezone) để mọi máy
  /// hiển thị giống hệt giờ đã lưu trên server:
  /// - Tự động: dùng múi giờ thiết bị, khác với server thì gửi lên cho khớp.
  /// - Tự chọn: dùng đúng múi giờ server đang lưu, không lấy cài đặt cũ còn trên máy.
  Future<void> loadFromSession() async {
    final user = Session.currentUser;
    if (user == null) return;
    _applyUser(user);
    if (!user.timezoneAuto && AppTime.findLocation(user.timezone) != null) {
      _isAutoTimezone = false;
      _manualTimezoneId = user.timezone;
      _manualCity = user.timezoneCity;
      _manualCountry = user.timezoneCountry;
    } else {
      _isAutoTimezone = true;
      _manualTimezoneId = null;
      _manualCity = null;
      _manualCountry = null;
    }
    _applyToAppTime();
    AppTime.notifyChanged();
    await _persist();
    notifyListeners();
    if (_isAutoTimezone && user.timezone != timezone) await _syncTimezone();
  }

  /// Gán thông tin hồ sơ mới nhận từ server rồi vẽ lại giao diện.
  void _applyUser(UserModel user) {
    _name = user.nickName;
    _email = user.email;
    _pendingEmail = user.pendingEmail;
    _hasPassword = user.hasPassword;
    _avatarUrl = user.avatarUrl;
    Session.start(user);
    notifyListeners();
  }

  /// Xoá hồ sơ khỏi bộ nhớ khi đăng xuất, múi giờ quay về theo thiết bị.
  void clear() {
    _name = '';
    _email = '';
    _pendingEmail = null;
    _hasPassword = true;
    _avatarUrl = null;
    _isAutoTimezone = true;
    _manualTimezoneId = null;
    _manualCity = null;
    _manualCountry = null;
    _applyToAppTime();
    // Xoá lựa chọn múi giờ của tài khoản cũ trên máy, tài khoản sau lấy lại từ server
    _persist();
    notifyListeners();
  }

  /// Đổi lỗi server thành lỗi của màn hình hồ sơ.
  ProfileError _errorFrom(ApiException e) {
    final details = e.details is Map ? e.details as Map : const {};
    _emailSuggestion = details['email_suggestion'] as String?;
    if (details['email'] == 'email_typo') return ProfileError.emailTypo;
    if (details['email'] == 'email_domain_invalid') {
      return ProfileError.emailDomainInvalid;
    }
    if (e.code == 'email_disabled' || e.code == 'email_send_failed') {
      return ProfileError.emailUnavailable;
    }
    if (details['email'] == 'already_taken') return ProfileError.emailTaken;
    if (details['nick_name'] == 'already_taken') return ProfileError.nameTaken;
    if (details['email'] == 'email_invalid') return ProfileError.emailInvalid;
    if (details['nick_name'] != null) return ProfileError.nameLength;
    return e.isNetwork ? ProfileError.network : ProfileError.server;
  }

  /// Gửi PATCH /users/me với các trường cần sửa, trả về lỗi nếu có (null là thành công).
  Future<ProfileError?> _patch(Map<String, dynamic> body) async {
    try {
      final data = await _api.patch('/users/me', body);
      _applyUser(UserModel.fromJson(data));
      return null;
    } on ApiException catch (e) {
      return _errorFrom(e);
    }
  }

  /// INFO-01: đổi tên hiển thị.
  Future<ProfileError?> updateName(String newName) =>
      _patch({'nick_name': newName.trim()});

  /// INFO-01: đổi email. Server chưa đổi ngay mà gửi link xác nhận tới email mới,
  /// trong lúc chờ thì [pendingEmail] mang địa chỉ mới.
  Future<ProfileError?> updateEmail(String newEmail) =>
      _patch({'email': newEmail.trim()});

  /// Huỷ yêu cầu đổi email đang chờ xác nhận.
  Future<ProfileError?> cancelEmailChange() async {
    try {
      final data = await _api.delete('/users/me/pending-email');
      _applyUser(UserModel.fromJson(data));
      return null;
    } on ApiException catch (e) {
      return e.isNetwork ? ProfileError.network : ProfileError.server;
    }
  }

  /// Tải lại hồ sơ từ server, dùng khi mở màn hình hồ sơ để biết email mới đã được xác nhận chưa.
  Future<void> reloadMe() async {
    if (Session.currentUserId.isEmpty) return;
    try {
      final data = await _api.get('/users/me');
      _applyUser(UserModel.fromJson(data));
    } on ApiException {
      // Bỏ qua, giữ thông tin đang có
    }
  }

  /// INFO-02, INFO-03: tải ảnh đại diện lên server (server đẩy tiếp lên Cloudinary).
  Future<ProfileError?> uploadAvatar(List<int> bytes, String filename) async {
    _uploadingAvatar = true;
    notifyListeners();
    try {
      final data = await _api.upload(
        '/users/me/avatar',
        'avatar',
        bytes,
        filename,
      );
      _applyUser(UserModel.fromJson(data));
      return null;
    } on ApiException catch (e) {
      return e.isNetwork ? ProfileError.network : ProfileError.server;
    } finally {
      _uploadingAvatar = false;
      notifyListeners();
    }
  }

  /// INFO-04: gửi múi giờ đang dùng lên server. Lỗi mạng thì bỏ qua, lần mở app sau sẽ gửi lại.
  Future<void> _syncTimezone() async {
    if (Session.currentUserId.isEmpty) return;
    final before = Session.currentUser?.timezone;
    try {
      final data = await _api.patch('/users/me', {
        'timezone': timezone,
        'timezone_auto': _isAutoTimezone,
        if (!_isAutoTimezone) 'timezone_city': _manualCity,
        if (!_isAutoTimezone) 'timezone_country': _manualCountry,
      });
      final user = UserModel.fromJson(data);
      _applyUser(user);
      // Server đã đổi lịch cá nhân sang múi giờ mới (giữ đúng thời điểm), báo lịch tải lại
      if (before != null && before != user.timezone) {
        AppTime.scheduleShifted.value++;
      }
    } on ApiException {
      // Bỏ qua
    }
  }

  /// Bật chế độ tự động: lấy múi giờ thực từ cài đặt thiết bị.
  Future<void> useDeviceTimezone() async {
    _isAutoTimezone = true;
    await refreshDeviceTimezone(notify: false);
    _applyToAppTime();
    await _persist();
    notifyListeners();
    await _syncTimezone();
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
    await _syncTimezone();
    return true;
  }

  /// Áp múi giờ đang chọn cho toàn app (AppTime), múi giờ sai thì quay về theo thiết bị.
  void _applyToAppTime() {
    if (_isAutoTimezone || _manualTimezoneId == null) {
      _isAutoTimezone = true;
      AppTime.useDeviceTimezone();
    } else if (!AppTime.useTimezone(_manualTimezoneId!)) {
      _isAutoTimezone = true;
      AppTime.useDeviceTimezone();
    }
  }

  /// Lưu cài đặt múi giờ xuống máy để lần sau mở app vẫn còn.
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kAutoKey, _isAutoTimezone);
      Future<void> put(String key, String? value) async {
        if (value == null) {
          await prefs.remove(key);
        } else {
          await prefs.setString(key, value);
        }
      }

      await put(_kTimezoneIdKey, _manualTimezoneId);
      await put(_kCityKey, _manualCity);
      await put(_kCountryKey, _manualCountry);
    } catch (_) {
      // Bỏ qua lỗi lưu cục bộ, cấu hình vẫn có hiệu lực trong phiên hiện tại.
    }
  }

  /// Dọn controller, listener khi hồ sơ bị đóng để không rò bộ nhớ.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
