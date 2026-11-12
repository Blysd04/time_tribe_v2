import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/session/app_reset.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/login_screen.dart';
import '../../home/viewmodels/home_viewmodel.dart';
import '../../onboarding/onboarding_service.dart';
import '../../profile/viewmodels/profile_viewmodel.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  /// Mở bảng chọn ngôn ngữ Việt / Anh / Pháp.
  void _pickLanguage(BuildContext context) {
    final l = context.l10n;
    final provider = context.read<LocaleProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l.language,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (final locale in LocaleProvider.supported)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Text(
                  LocaleProvider.flag(locale),
                  style: const TextStyle(fontSize: 26),
                ),
                title: Text(
                  LocaleProvider.nativeName(locale),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: provider.locale == locale
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : const Icon(Icons.circle_outlined, color: Colors.grey),
                onTap: () {
                  provider.setLocale(locale);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// AU-06: đăng xuất. Server xoá phiên và fcm_token, máy xoá sạch dữ liệu của tài khoản
  /// để người khác đăng nhập trên máy này không thấy dữ liệu cũ.
  Future<void> _logout(BuildContext context) async {
    final l = context.l10n;
    final ok = await AppDialogs.confirm(
      context,
      title: l.logout,
      message: l.logoutConfirm,
      confirmLabel: l.logout,
    );
    if (!ok || !context.mounted) return;
    await context.read<AuthViewModel>().logout();
    if (!context.mounted) return;
    AppData.clearAll(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  /// Dựng giao diện tab Cài đặt.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.watch<LocaleProvider>().locale;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          8,
          AppSpacing.page,
          24,
        ),
        children: [
          AppSection(
            title: l.appearance,
            children: [
              AppListTile(
                icon: Icons.dark_mode_outlined,
                color: const Color(0xFF6A4C93),
                title: l.darkMode,
                trailing: Switch(
                  value: isDark,
                  onChanged: (v) =>
                      context.read<ThemeProvider>().toggleTheme(v),
                ),
              ),
              AppListTile(
                icon: Icons.translate,
                color: AppColors.success,
                title: l.language,
                subtitle:
                    '${LocaleProvider.flag(locale)}  ${LocaleProvider.nativeName(locale)}',
                onTap: () => _pickLanguage(context),
              ),
            ],
          ),
          AppSection(
            title: l.help,
            children: [
              AppListTile(
                icon: Icons.tips_and_updates_outlined,
                color: AppColors.primary,
                title: l.replayTour,
                subtitle: l.replayTourSubtitle,
                // Trang chủ thấy cờ này sẽ tự chạy hướng dẫn khi vẽ lại
                onTap: () {
                  Onboarding.pendingTour = true;
                  context.read<HomeViewModel>().changeTab(1);
                },
              ),
            ],
          ),
          AppSection(
            title: l.account,
            children: [
              // Tài khoản Google chưa có mật khẩu thì hiện "Tạo mật khẩu"
              Builder(
                builder: (context) {
                  final hasPassword = context.select<ProfileViewModel, bool>(
                    (vm) => vm.hasPassword,
                  );
                  return AppListTile(
                    icon: Icons.lock_reset_outlined,
                    title: hasPassword ? l.changePassword : l.setPassword,
                    subtitle: hasPassword
                        ? l.changePasswordSubtitle
                        : l.setPasswordSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    ),
                  );
                },
              ),
              AppListTile(
                icon: Icons.logout,
                color: AppColors.warning,
                title: l.logout,
                onTap: () => _logout(context),
              ),
              AppListTile(
                icon: Icons.delete_forever_outlined,
                title: l.deleteAccount,
                subtitle: l.deleteAccountSubtitle,
                destructive: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DeleteAccountScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'TimeTribe v2.0.0',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.35),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
