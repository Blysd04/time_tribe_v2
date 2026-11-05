import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'app_theme.dart';

/// Chế độ sáng / tối, có lưu lại giữa các lần mở app.
class ThemeProvider extends ChangeNotifier {
  static const _key = 'settings.theme_mode';

  ThemeMode _themeMode = ThemeMode.system; // Mặc định theo hệ thống máy
  ThemeMode get themeMode => _themeMode;

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

  Future<void> toggleTheme(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, _themeMode.name);
    } catch (_) {}
  }
}
