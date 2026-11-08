import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'app_theme.dart';

/// Chế độ sáng / tối, có lưu lại giữa các lần mở app.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'settings.theme_mode';

  ThemeMode _themeMode = ThemeMode.system; // Mặc định theo hệ thống máy
  /// Chế độ sáng hay tối đang dùng.
  ThemeMode get themeMode => _themeMode;

  /// Đọc chế độ sáng/tối đã lưu trên máy lúc mở app.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {}
  }

  /// SET-01: bật tắt chế độ tối và lưu lại trên máy.
  Future<void> toggleTheme(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _themeMode.name);
    } catch (_) {}
  }
}
