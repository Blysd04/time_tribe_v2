import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/l10n/l10n.dart';
import 'core/l10n/locale_provider.dart';
import 'core/services/push_service.dart';
import 'core/session/app_reset.dart';
import 'core/session/session.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/app_time.dart';
import 'features/auth/viewmodels/auth_viewmodel.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/startup_screen.dart';
import 'features/home/viewmodels/home_viewmodel.dart';
import 'features/notifications/viewmodels/notification_viewmodel.dart';
import 'features/profile/viewmodels/profile_viewmodel.dart';
import 'features/template/viewmodels/template_viewmodel.dart';
import 'features/timeblock/viewmodels/timeblock_viewmodel.dart';
import 'features/tribe/viewmodels/tribe_viewmodel.dart';

/// Dùng để chuyển màn hình và hiện snackbar từ chỗ không có BuildContext
/// (ví dụ phiên đăng nhập bị kết thúc khi đang gọi API).
final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

/// Điểm bắt đầu của app: nạp cài đặt đã lưu, khởi tạo Firebase, gắn xử lý phiên hết hạn rồi chạy app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nạp múi giờ, ngôn ngữ, giao diện đã lưu trước khi vẽ giao diện
  AppTime.ensureInitialized();
  AppTime.startDayWatcher();
  final profileViewModel = ProfileViewModel();
  final localeProvider = LocaleProvider();
  final themeProvider = ThemeProvider();
  await Future.wait([
    profileViewModel.init(),
    localeProvider.load(),
    themeProvider.load(),
    PushService.init(),
  ]);

  // Tài khoản vừa đăng nhập ở máy khác, bị khoá, đổi mật khẩu... thì server trả lỗi phiên.
  // Lúc đó xoá dữ liệu trên máy và đưa người dùng về màn hình đăng nhập.
  ApiClient.instance.onSessionEnded = (_) async {
    await AuthViewModel.clearDeviceData(ApiClient.instance);
    final ctx = navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    AppData.clearAll(ctx);
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(ctx.l10n.sessionEnded)),
    );
  };

  // Thông báo đẩy tới lúc đang mở app (Android không tự hiện): hiện banner trong app,
  // bấm "Xem" để mở tab Thông báo.
  PushService.onForeground = _showForegroundPush;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => TribeViewModel()),
        ChangeNotifierProvider.value(value: profileViewModel),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => TimeblockViewModel()),
        ChangeNotifierProvider(create: (_) => TemplateViewModel()),
      ],
      child: const TimeTribeApp(),
    ),
  );
}

/// Banner nổi ở cuối màn hình cho thông báo đẩy tới khi app đang mở.
void _showForegroundPush(String title, String body) {
  final messenger = messengerKey.currentState;
  final ctx = navigatorKey.currentContext;
  if (messenger == null || ctx == null || (title.isEmpty && body.isEmpty)) {
    return;
  }
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: ctx.l10n.view,
          textColor: const Color(0xFF8AB6FF),
          onPressed: () {
            final c = navigatorKey.currentContext;
            if (c == null || Session.currentUserId.isEmpty) return;
            navigatorKey.currentState?.popUntil((r) => r.isFirst);
            c.read<HomeViewModel>().changeTab(3);
          },
        ),
      ),
    );
}

class TimeTribeApp extends StatelessWidget {
  const TimeTribeApp({super.key});

  /// Dựng giao diện toàn bộ app (theme, ngôn ngữ, màn hình đầu tiên).
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>().locale;

    return MaterialApp(
      title: 'TimeTribe',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: locale,
      supportedLocales: LocaleProvider.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Trang không có AppBar cũng hiển thị đúng màu icon thanh trạng thái
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkStatusBar
            : AppTheme.lightStatusBar,
        child: child!,
      ),
      home: const StartupScreen(),
    );
  }
}
