import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/utils/email_check.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../core/services/push_service.dart';
import '../../../core/session/session.dart';
import '../../profile/models/user_model.dart';

/// Mã lỗi xác thực; câu chữ hiển thị nằm ở giao diện (đa ngôn ngữ).
enum AuthError {
  identifierRequired,
  passwordRequired,
  wrongCredentials,
  nameRequired,
  emailRequired,
  createPasswordRequired,
  passwordMismatch,
  nameLength,
  emailInvalid,
  emailTypo,
  emailDomainInvalid,
  passwordTooShort,
  emailTaken,
  nameTaken,
  accountBanned,
  accountDeleted,
  googleAccount,
  googleFailed,
  googleUnsupported,
  network,
  server,
}

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  bool _isLoading = false;

  /// Đang gọi API đăng nhập/đăng ký hay không, để khoá nút và hiện vòng tải.
  bool get isLoading => _isLoading;

  AuthError? _identifierError; // Email hoặc Username
  AuthError? _passwordError;
  AuthError? _nameError;
  AuthError? _confirmPasswordError;
  AuthError? _generalError;

  /// Lỗi của ô email hoặc tên đăng nhập.
  AuthError? get emailError => _identifierError;

  String? _emailSuggestion;

  /// Xoá lỗi ô email (sau khi người dùng bấm dùng email gợi ý).
  void clearEmailError() {
    _identifierError = null;
    _emailSuggestion = null;
    notifyListeners();
  }

  /// Email gợi ý khi email đăng ký có vẻ gõ nhầm tên miền (VD gmial.com -> gmail.com).
  String? get emailSuggestion => _emailSuggestion;

  /// Lỗi của ô mật khẩu.
  AuthError? get passwordError => _passwordError;

  /// Lỗi của ô tên hiển thị (màn đăng ký).
  AuthError? get nameError => _nameError;

  /// Lỗi của ô xác nhận mật khẩu (màn đăng ký).
  AuthError? get confirmPasswordError => _confirmPasswordError;

  /// Lỗi không thuộc ô nhập nào (mất mạng, tài khoản bị khoá...), giao diện hiện bằng snackbar.
  AuthError? get generalError => _generalError;

  bool _rememberMe = true;

  /// Người dùng có tích "Ghi nhớ đăng nhập" không.
  bool get rememberMe => _rememberMe;

  /// Bật tắt ô "Ghi nhớ đăng nhập".
  void toggleRememberMe() {
    _rememberMe = !_rememberMe;
    notifyListeners();
  }

  /// Xoá hết thông báo lỗi cũ trước mỗi lần bấm nút.
  void _clearErrors() {
    _identifierError = null;
    _passwordError = null;
    _nameError = null;
    _confirmPasswordError = null;
    _generalError = null;
  }

  /// Bật tắt trạng thái đang tải rồi báo giao diện vẽ lại.
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Tên máy gửi kèm khi đăng nhập để backend biết phiên này ở thiết bị nào.
  String get _deviceInfo => kIsWeb ? 'web' : defaultTargetPlatform.name;

  /// Đổi lỗi chung từ server sang mã lỗi của app.
  AuthError _generalFrom(ApiException e) => switch (e.code) {
    'account_banned' => AuthError.accountBanned,
    'account_deleted' => AuthError.accountDeleted,
    'google_account' => AuthError.googleAccount,
    'network_error' => AuthError.network,
    _ => AuthError.server,
  };

  /// Lưu token và người dùng sau khi đăng nhập thành công.
  Future<void> _startSession(
    Map<String, dynamic> data, {
    required bool persist,
  }) async {
    await _api.setTokens(
      data['access_token'],
      data['refresh_token'],
      persist: persist,
    );
    Session.start(UserModel.fromJson(data['user']));
  }

  /// AU-02: đăng nhập bằng email hoặc tên hiển thị.
  /// Gửi kèm mã FCM của máy (nếu có) để server lưu vào users.fcm_token.
  Future<bool> login(String emailOrUsername, String password) async {
    _clearErrors();
    if (emailOrUsername.trim().isEmpty) {
      _identifierError = AuthError.identifierRequired;
    }
    if (password.trim().isEmpty) _passwordError = AuthError.passwordRequired;
    if (_identifierError != null || _passwordError != null) {
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      final data = await _api.post('/auth/login', {
        'identifier': emailOrUsername.trim(),
        'password': password,
        'remember_me': _rememberMe,
        'fcm_token': await PushService.getToken() ?? '',
        'device_info': _deviceInfo,
      });
      await _startSession(data, persist: _rememberMe);
      return true;
    } on ApiException catch (e) {
      if (e.code == 'wrong_credentials') {
        // Gom chung lỗi tài khoản/mật khẩu để tránh bị dò tài khoản
        _passwordError = AuthError.wrongCredentials;
      } else {
        _generalError = _generalFrom(e);
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// AU-03: đăng nhập Google. App lấy Firebase ID token rồi gửi lên backend cùng mã FCM.
  /// Trả về false khi người dùng tự đóng hộp chọn tài khoản (không báo lỗi).
  Future<bool> loginWithGoogle() async {
    _clearErrors();
    _setLoading(true);
    try {
      final google = await GoogleAuthService.signIn();
      switch (google.status) {
        case GoogleSignInStatus.cancelled:
          return false;
        case GoogleSignInStatus.unsupported:
          _generalError = AuthError.googleUnsupported;
          return false;
        case GoogleSignInStatus.failed:
          _generalError = AuthError.googleFailed;
          return false;
        case GoogleSignInStatus.success:
          break;
      }
      final data = await _api.post('/auth/google', {
        'id_token': google.idToken,
        'fcm_token': await PushService.getToken() ?? '',
        'device_info': _deviceInfo,
      });
      await _startSession(data, persist: true);
      return true;
    } on ApiException catch (e) {
      _generalError = e.code == 'invalid_google_token'
          ? AuthError.googleFailed
          : _generalFrom(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// AU-01: đăng ký tài khoản. Thành công thì quay về màn hình đăng nhập.
  Future<bool> register(
    String name,
    String email,
    String password,
    String confirm,
  ) async {
    _clearErrors();
    if (name.trim().isEmpty) _nameError = AuthError.nameRequired;
    _emailSuggestion = null;
    if (email.trim().isEmpty) {
      _identifierError = AuthError.emailRequired;
    } else if (!EmailCheck.isValid(email)) {
      _identifierError = AuthError.emailInvalid;
    } else if (EmailCheck.suggest(email) != null) {
      _emailSuggestion = EmailCheck.suggest(email);
      _identifierError = AuthError.emailTypo;
    }
    if (password.trim().isEmpty) {
      _passwordError = AuthError.createPasswordRequired;
    }
    if (confirm != password) _confirmPasswordError = AuthError.passwordMismatch;
    if (_nameError != null ||
        _identifierError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      notifyListeners();
      return false;
    }

    _setLoading(true);
    try {
      await _api.post('/auth/register', {
        'nick_name': name.trim(),
        'email': email.trim(),
        'password': password,
        'confirm_password': confirm,
      });
      return true;
    } on ApiException catch (e) {
      _applyFieldErrors(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Đọc details của lỗi validation_error / account_exists rồi gắn vào đúng ô nhập.
  void _applyFieldErrors(ApiException e) {
    final details = e.details is Map ? e.details as Map : const {};
    if (details.isEmpty) {
      _generalError = _generalFrom(e);
      return;
    }
    _nameError = switch (details['nick_name']) {
      'name_required' => AuthError.nameRequired,
      'name_length' => AuthError.nameLength,
      'already_taken' => AuthError.nameTaken,
      _ => null,
    };
    _emailSuggestion = details['email_suggestion'] as String?;
    _identifierError = switch (details['email']) {
      'email_required' => AuthError.emailRequired,
      'email_invalid' => AuthError.emailInvalid,
      'email_typo' => AuthError.emailTypo,
      'email_domain_invalid' => AuthError.emailDomainInvalid,
      'already_taken' => AuthError.emailTaken,
      _ => null,
    };
    _passwordError = switch (details['password']) {
      'create_password_required' => AuthError.createPasswordRequired,
      'password_too_short' => AuthError.passwordTooShort,
      _ => null,
    };
    if (details['confirm_password'] == 'password_mismatch') {
      _confirmPasswordError = AuthError.passwordMismatch;
    }
  }

  /// AU-04: gửi email đặt lại mật khẩu. Server luôn trả thành công dù email có tồn tại hay không.
  Future<bool> forgotPassword(String email) async {
    _clearErrors();
    final value = email.trim();
    if (value.isEmpty) {
      _identifierError = AuthError.emailRequired;
      notifyListeners();
      return false;
    }
    _setLoading(true);
    try {
      // Gửi kèm ngôn ngữ app để email đặt lại mật khẩu viết đúng ngôn ngữ đang dùng
      await _api.post('/auth/forgot-password', {
        'email': value,
        'language': LocaleProvider.currentCode,
      });
      return true;
    } on ApiException catch (e) {
      _identifierError = e.code == 'validation_error'
          ? AuthError.emailInvalid
          : null;
      if (_identifierError == null) _generalError = _generalFrom(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Mở app: nếu lần trước có ghi nhớ đăng nhập thì lấy lại hồ sơ, vào thẳng trang chủ.
  Future<bool> restoreSession() async {
    await _api.loadTokens();
    if (!_api.hasSession) return false;
    try {
      final data = await _api.get('/users/me');
      Session.start(UserModel.fromJson(data));
      return true;
    } on ApiException {
      // Token hết hạn hoặc máy chủ không trả lời thì bắt đăng nhập lại
      return false;
    }
  }

  /// AU-06: đăng xuất. Server xoá phiên và đặt fcm_token về null.
  /// Dù gọi server lỗi (mất mạng) thì máy vẫn xoá sạch dữ liệu đăng nhập.
  Future<void> logout() async {
    _clearErrors();
    try {
      await _api.post('/auth/logout');
    } on ApiException {
      // Bỏ qua, phiên trên server sẽ tự hết hạn
    }
    await clearDeviceData(_api);
    notifyListeners();
  }

  /// AU-05: đổi mật khẩu (hoặc tạo mật khẩu lần đầu cho tài khoản Google, khi đó [current] để null).
  /// Thành công thì server đăng xuất mọi thiết bị, máy này cũng xoá phiên để người dùng đăng nhập lại.
  /// Trả về null nếu thành công, ngược lại là lỗi để hiện dưới ô nhập tương ứng.
  Future<ChangePasswordError?> changePassword({
    String? current,
    required String next,
    required String confirm,
  }) async {
    _setLoading(true);
    try {
      await _api.put('/auth/change-password', {
        'current_password': ?current,
        'new_password': next,
        'confirm_password': confirm,
      });
      await clearDeviceData(_api);
      return null;
    } on ApiException catch (e) {
      if (e.code == 'wrong_current_password') return ChangePasswordError.wrongCurrent;
      if (e.code == 'same_password') return ChangePasswordError.samePassword;
      final d = e.details is Map ? e.details as Map : const {};
      if (d['current_password'] != null) return ChangePasswordError.currentRequired;
      if (d['new_password'] != null) return ChangePasswordError.tooShort;
      if (d['confirm_password'] != null) return ChangePasswordError.mismatch;
      return e.isNetwork ? ChangePasswordError.network : ChangePasswordError.server;
    } finally {
      _setLoading(false);
    }
  }

  /// AU-07: xoá tài khoản vĩnh viễn với lý do người dùng chọn.
  Future<bool> deleteAccount(String reason) async {
    _clearErrors();
    _setLoading(true);
    try {
      await _api.delete('/users/me', {'reason': reason});
      await clearDeviceData(_api);
      return true;
    } on ApiException catch (e) {
      _generalError = _generalFrom(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Xoá mọi thông tin của tài khoản trên máy: token, hồ sơ, cài đặt múi giờ, tài khoản Google.
  /// Giữ lại ngôn ngữ và chế độ sáng tối vì đó là cài đặt của máy, không phải của tài khoản.
  static Future<void> clearDeviceData(ApiClient api) async {
    await api.clearTokens();
    Session.clear();
    await GoogleAuthService.signOut();
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().toList()) {
        if (key.startsWith('profile.') ||
            key.startsWith('auth.') ||
            key.startsWith('timeblock.')) {
          await prefs.remove(key);
        }
      }
    } catch (_) {}
  }
}

/// Lỗi khi đổi mật khẩu, để màn hình hiện đúng câu dưới đúng ô.
enum ChangePasswordError {
  currentRequired,
  wrongCurrent,
  samePassword,
  tooShort,
  mismatch,
  network,
  server,
}
