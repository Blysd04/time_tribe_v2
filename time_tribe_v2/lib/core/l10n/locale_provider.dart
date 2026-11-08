import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ngôn ngữ của app (Tiếng Việt / English / Français), có lưu lại.
class LocaleProvider extends ChangeNotifier {
  static const _key = 'settings.locale';

  static const supported = [Locale('vi'), Locale('en'), Locale('fr')];

  Locale _locale = const Locale('vi');

  /// Ngôn ngữ đang dùng.
  Locale get locale => _locale;

  /// Đọc ngôn ngữ đã lưu trên máy lúc mở app.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null && supported.any((l) => l.languageCode == code)) {
        _locale = Locale(code);
      }
    } catch (_) {}
  }

  /// SET-02: đổi ngôn ngữ và lưu lại trên máy.
  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, locale.languageCode);
    } catch (_) {}
    // Ngôn ngữ chỉ lưu trên máy (bảng users chưa có cột ngôn ngữ), nên thông báo đẩy
    // từ server là tiếng Việt, còn danh sách thông báo trong app vẫn dịch theo ngôn ngữ đang chọn.
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
