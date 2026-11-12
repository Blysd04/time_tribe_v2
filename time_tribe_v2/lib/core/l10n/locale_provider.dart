import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../../features/profile/models/user_model.dart';
import '../session/session.dart';

/// Ngôn ngữ của app (Tiếng Việt / English / Français), có lưu lại.
class LocaleProvider extends ChangeNotifier {
  static const _key = 'settings.locale';

  static const supported = [Locale('vi'), Locale('en'), Locale('fr')];

  Locale _locale = const Locale('vi');

  /// Mã ngôn ngữ đang dùng (vi, en, fr), đọc được ở nơi không có BuildContext
  /// (VD gửi kèm khi bấm "Quên mật khẩu" để email về đúng ngôn ngữ).
  static String currentCode = 'vi';

  /// Ngôn ngữ đang dùng.
  Locale get locale => _locale;

  /// Đọc ngôn ngữ đã lưu trên máy lúc mở app.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null && supported.any((l) => l.languageCode == code)) {
        _locale = Locale(code);
        currentCode = code;
      }
    } catch (_) {}
  }

  /// SET-02: đổi ngôn ngữ và lưu lại trên máy.
  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    currentCode = locale.languageCode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, locale.languageCode);
    } catch (_) {}
    await syncToServer();
  }

  /// Gửi ngôn ngữ đang dùng lên server (users.language) để thông báo đẩy trên khay hệ thống
  /// dùng đúng ngôn ngữ của app. Gọi khi đổi ngôn ngữ và sau khi đăng nhập. Lỗi mạng thì bỏ qua,
  /// lần mở app sau sẽ gửi lại.
  Future<void> syncToServer() async {
    final user = Session.currentUser;
    if (user == null || user.language == _locale.languageCode) return;
    try {
      final data = await ApiClient.instance.patch('/users/me', {
        'language': _locale.languageCode,
      });
      Session.start(UserModel.fromJson(data));
    } on ApiException {
      // Bỏ qua
    }
  }

  /// Tên ngôn ngữ hiển thị bằng chính ngôn ngữ đó.
  static String nativeName(Locale locale) => switch (locale.languageCode) {
    'en' => 'English',
    'fr' => 'Français',
    _ => 'Tiếng Việt',
  };

  /// Cờ của từng ngôn ngữ để hiện cạnh tên.
  static String flag(Locale locale) => switch (locale.languageCode) {
    'en' => '🇬🇧',
    'fr' => '🇫🇷',
    _ => '🇻🇳',
  };
}
