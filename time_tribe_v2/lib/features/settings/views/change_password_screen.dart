import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/session/app_reset.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/login_screen.dart';
import '../../profile/viewmodels/profile_viewmodel.dart';

/// AU-05: đổi mật khẩu sau khi đã đăng nhập (mở từ Cài đặt > Tài khoản).
/// Tài khoản Google chưa có mật khẩu thì màn hình thành "Tạo mật khẩu", không hỏi mật khẩu hiện tại.
/// Đổi xong server đăng xuất mọi thiết bị và huỷ yêu cầu đổi email đang chờ, nên app quay về đăng nhập.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false;
  bool _showNext = false;
  String? _currentError;
  String? _nextError;
  String? _confirmError;
  bool _saving = false;

  /// Dọn controller khi đóng màn hình.
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Kiểm tra ở máy trước, hỏi xác nhận rồi gửi lên server.
  Future<void> _submit(bool hasPassword) async {
    final l = context.l10n;
    final current = _current.text;
    final next = _next.text;
    final confirm = _confirm.text;
    setState(() {
      _currentError = hasPassword && current.isEmpty ? l.errorPasswordRequired : null;
      _nextError = next.isEmpty
          ? l.errorPasswordRequired
          : next.length < 6
          ? l.errorPasswordTooShort
          : (hasPassword && next == current)
          ? l.errorSamePassword
          : null;
      _confirmError = confirm != next ? l.errorPasswordMismatch : null;
    });
    if (_currentError != null || _nextError != null || _confirmError != null) {
      return;
    }

    final title = hasPassword ? l.changePassword : l.setPassword;
    final ok = await AppDialogs.confirm(
      context,
      title: title,
      message: l.changePasswordNote,
      confirmLabel: title,
    );
    if (!ok || !mounted) return;

    setState(() => _saving = true);
    final err = await context.read<AuthViewModel>().changePassword(
      current: hasPassword ? current : null,
      next: next,
      confirm: confirm,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (err == null) {
      // Server đã đăng xuất mọi thiết bị: xoá dữ liệu trên máy rồi về màn hình đăng nhập
      AppData.clearAll(context);
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      messenger.showSnackBar(SnackBar(content: Text(l.passwordChangedRelogin)));
      return;
    }
    setState(() {
      switch (err) {
        case ChangePasswordError.currentRequired:
          _currentError = l.errorPasswordRequired;
        case ChangePasswordError.wrongCurrent:
          _currentError = l.errorWrongCurrentPassword;
        case ChangePasswordError.samePassword:
          _nextError = l.errorSamePassword;
        case ChangePasswordError.tooShort:
          _nextError = l.errorPasswordTooShort;
        case ChangePasswordError.mismatch:
          _confirmError = l.errorPasswordMismatch;
        case ChangePasswordError.network:
        case ChangePasswordError.server:
          break;
      }
    });
    if (err == ChangePasswordError.network || err == ChangePasswordError.server) {
      AppSnack.show(
        context,
        err == ChangePasswordError.network ? l.errorNetwork : l.errorServer,
        type: AppSnackType.error,
      );
    }
  }

  /// Ô nhập mật khẩu có nút ẩn/hiện.
  Widget _field({
    required TextEditingController controller,
    required String label,
    required String? error,
    required bool visible,
    VoidCallback? onToggle,
    required VoidCallback onEdited,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    String? autofill,
  }) {
    return TextField(
      controller: controller,
      obscureText: !visible,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: action,
      onSubmitted: onSubmitted,
      autofillHints: autofill == null ? null : [autofill],
      onChanged: (_) => onEdited(),
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: onToggle == null
            ? null
            : IconButton(
                icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
                onPressed: onToggle,
              ),
      ),
    );
  }

  /// Dựng giao diện màn hình đổi mật khẩu.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = context.watch<ProfileViewModel>();
    final hasPassword = profile.hasPassword;
    final pending = profile.pendingEmail;

    return Scaffold(
      appBar: AppBar(title: Text(hasPassword ? l.changePassword : l.setPassword)),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            if (hasPassword) ...[
              _field(
                controller: _current,
                label: l.currentPassword,
                error: _currentError,
                visible: _showCurrent,
                onToggle: () => setState(() => _showCurrent = !_showCurrent),
                onEdited: () {
                  if (_currentError != null) setState(() => _currentError = null);
                },
                autofill: AutofillHints.password,
              ),
              const SizedBox(height: 16),
            ],
            _field(
              controller: _next,
              label: l.newPassword,
              error: _nextError,
              visible: _showNext,
              onToggle: () => setState(() => _showNext = !_showNext),
              onEdited: () {
                if (_nextError != null) setState(() => _nextError = null);
              },
              autofill: AutofillHints.newPassword,
            ),
            const SizedBox(height: 16),
            _field(
              controller: _confirm,
              label: l.confirmNewPassword,
              error: _confirmError,
              visible: _showNext,
              onEdited: () {
                if (_confirmError != null) setState(() => _confirmError = null);
              },
              action: TextInputAction.done,
              onSubmitted: (_) => _saving ? null : _submit(hasPassword),
              autofill: AutofillHints.newPassword,
            ),
            const SizedBox(height: 20),
            InfoBanner(text: l.changePasswordNote),
            if (pending != null) ...[
              const SizedBox(height: 10),
              InfoBanner(
                text: l.changePasswordPendingEmail(pending),
                color: AppColors.warning,
                icon: Icons.mark_email_unread_outlined,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusField),
                ),
              ),
              onPressed: _saving ? null : () => _submit(hasPassword),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(hasPassword ? l.changePassword : l.setPassword),
            ),
          ],
        ),
      ),
    );
  }
}
