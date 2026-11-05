import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ngôn ngữ của app (Tiếng Việt / English / Français), có lưu lại.
class LocaleProvider extends ChangeNotifier {
  static const _key = 'settings.locale';

  static const supported = [Locale('vi'), Locale('en'), Locale('fr')];

  Locale _locale = const Locale('vi');
  Locale get locale => _locale;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null && supported.any((l) => l.languageCode == code)) {
        _locale = Locale(code);
      }
    } catch (_) {}
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, locale.languageCode);
    } catch (_) {}
    // TODO(backend): lưu ngôn ngữ vào hồ sơ để server gửi thông báo đúng ngôn ngữ
  }

  /// Tên ngôn ngữ hiển thị bằng chính ngôn ngữ đó.
  static String nativeName(Locale locale) => switch (locale.languageCode) {
    'en' => 'English',
    'fr' => 'Français',
    _ => 'Tiếng Việt',
  };

  static String flag(Locale locale) => switch (locale.languageCode) {
    'en' => '🇬🇧',
    'fr' => '🇫🇷',
    _ => '🇻🇳',
  };
}
