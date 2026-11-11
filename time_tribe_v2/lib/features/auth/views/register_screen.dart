import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'widgets/app_logo.dart';
import 'widgets/auth_texts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  /// Tạo phần state giữ dữ liệu thay đổi của màn hình đăng ký.
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  /// Bấm Đăng ký: lỗi từng ô hiện ngay dưới ô đó, lỗi chung (mất mạng...) hiện snackbar.
  Future<void> _handleRegister() async {
    final l = context.l10n;
    final vm = context.read<AuthViewModel>();
    final success = await vm.register(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
      _confirmController.text,
    );
    if (!mounted) return;
    if (success) {
      AppSnack.show(context, l.registerSuccess);
      Navigator.pop(context);
    } else if (vm.generalError != null) {
      AppSnack.show(
        context,
        l.authError(vm.generalError)!,
        type: AppSnackType.error,
      );
    }
  }

  /// Dọn controller, listener khi màn hình đăng ký bị đóng để không rò bộ nhớ.
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Dựng giao diện màn hình đăng ký.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<AuthViewModel>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: AppLogo(height: 90)),
              const SizedBox(height: 24),
              Text(
                l.createAccount,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.createAccountSubtitle,
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: l.displayName,
                  errorText: l.authError(vm.nameError),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: l.email,
                  errorText:
                      vm.emailError == AuthError.emailTypo &&
                          vm.emailSuggestion != null
                      ? l.errorEmailTypo(vm.emailSuggestion!)
                      : l.authError(vm.emailError),
                  errorMaxLines: 3,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              if (vm.emailError == AuthError.emailTypo &&
                  vm.emailSuggestion != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                    label: Text(l.useSuggestion(vm.emailSuggestion!)),
                    onPressed: () {
                      _emailController.text = vm.emailSuggestion!;
                      vm.clearEmailError();
                    },
                  ),
                ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  hintText: l.passwordHint,
                  errorText: l.authError(vm.passwordError),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                onSubmitted: (_) => _handleRegister(),
                decoration: InputDecoration(
                  hintText: l.confirmPasswordHint,
                  errorText: l.authError(vm.confirmPasswordError),
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: vm.isLoading ? null : _handleRegister,
                child: vm.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(l.register),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
