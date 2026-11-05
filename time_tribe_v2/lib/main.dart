import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/l10n/l10n.dart';
import 'core/l10n/locale_provider.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/app_time.dart';
import 'features/auth/viewmodels/auth_viewmodel.dart';
import 'features/auth/views/login_screen.dart';
import 'features/home/viewmodels/home_viewmodel.dart';
import 'features/notifications/viewmodels/notification_viewmodel.dart';
import 'features/profile/viewmodels/profile_viewmodel.dart';
import 'features/template/viewmodels/template_viewmodel.dart';
import 'features/timeblock/viewmodels/timeblock_viewmodel.dart';
import 'features/tribe/viewmodels/tribe_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nạp múi giờ, ngôn ngữ, giao diện đã lưu TRƯỚC khi vẽ UI
  AppTime.ensureInitialized();
  final profileViewModel = ProfileViewModel();
  final localeProvider = LocaleProvider();
  final themeProvider = ThemeProvider();
  await Future.wait([
    profileViewModel.init(),
    localeProvider.load(),
    themeProvider.load(),
  ]);

  // Lịch nhóm gửi thông báo vào tab Thông báo của người dùng hiện tại
  final notificationViewModel = NotificationViewModel();
  final tribeViewModel = TribeViewModel(
    notificationSink: notificationViewModel.push,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: notificationViewModel),
        ChangeNotifierProvider.value(value: tribeViewModel),
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

class TimeTribeApp extends StatelessWidget {
  const TimeTribeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>().locale;

    return MaterialApp(
      title: 'TimeTribe',
      debugShowCheckedModeBanner: false,
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
      home: const LoginScreen(),
    );
  }
}
