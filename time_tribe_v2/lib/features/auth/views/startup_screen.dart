import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../onboarding/onboarding_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_screen.dart';
import 'widgets/app_logo.dart';

/// Màn hình chờ lúc mở app: lần trước có ghi nhớ đăng nhập thì vào thẳng trang chủ,
/// không thì sang màn hình đăng nhập.
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  /// Tạo phần state giữ dữ liệu thay đổi của màn hình chờ lúc mở app.
  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  /// Chạy một lần lúc màn hình chờ lúc mở app vừa được tạo, chuẩn bị dữ liệu ban đầu.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  /// Thử lấy lại phiên đăng nhập cũ rồi chuyển màn hình.
  Future<void> _decide() async {
    final ok = await context.read<AuthViewModel>().restoreSession();
    // Tài khoản mới chưa xem phần chào mừng thì vào đó trước
    final next = ok ? await Onboarding.entryScreen() : const LoginScreen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => next),
    );
  }

  /// Dựng giao diện màn hình chờ lúc mở app.
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(height: 120),
            SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
