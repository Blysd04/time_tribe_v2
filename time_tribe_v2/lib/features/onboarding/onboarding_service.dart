import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/session/session.dart';
import '../home/views/home_screen.dart';
import 'views/onboarding_screen.dart';

/// Quản lý phần chào mừng + hướng dẫn cho người mới.
///
/// - Server đánh dấu `needs_onboarding = true` cho tài khoản vừa tạo (đăng ký hoặc Google lần đầu).
/// - Xem xong thì app gửi `needs_onboarding: false` lên, đồng thời ghi nhớ trên máy
///   (phòng khi gọi API lỗi thì lần sau cũng không hiện lại).
/// - Chọn "Tôi là người mới" thì bật [pendingTour], trang chủ sẽ chạy hướng dẫn từng bước.
class Onboarding {
  Onboarding._();

  static const _doneKey = 'onboarding.done.';

  /// Trang chủ cần chạy hướng dẫn từng bước ngay khi mở.
  static bool pendingTour = false;

  /// Người đang đăng nhập có cần xem màn hình chào mừng không.
  static Future<bool> needsWelcome() async {
    final user = Session.currentUser;
    if (user == null || !user.needsOnboarding) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool('$_doneKey${user.id}') ?? false);
    } catch (_) {
      return true;
    }
  }

  /// Màn hình đầu tiên sau khi đăng nhập: chào mừng (người mới) hoặc trang chủ.
  static Future<Widget> entryScreen() async =>
      await needsWelcome() ? const OnboardingScreen() : const HomeScreen();

  /// Người dùng đã xem xong phần chào mừng. [wantsTour] = chọn "Tôi là người mới".
  static Future<void> complete({required bool wantsTour}) async {
    pendingTour = wantsTour;
    final id = Session.currentUserId;
    if (id.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_doneKey$id', true);
    } catch (_) {}
    // Không chờ server: mạng chậm cũng không giữ người dùng ở màn hình chào mừng
    ApiClient.instance
        .patch('/users/me', {'needs_onboarding': false})
        .catchError((_) => null);
  }
}
