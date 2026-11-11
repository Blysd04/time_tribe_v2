import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/email_check.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'profile_screen.dart';

enum EditField { name, email }

/// Sửa tên hiển thị hoặc email.
class EditTextScreen extends StatefulWidget {
  final EditField field;
  final String initialValue;

  const EditTextScreen({
    super.key,
    required this.field,
    required this.initialValue,
  });

  /// Tạo phần state giữ dữ liệu thay đổi của màn hình sửa tên hoặc email.
  @override
  State<EditTextScreen> createState() => _EditTextScreenState();
}

class _EditTextScreenState extends State<EditTextScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  String? _error;
  // Email gợi ý khi phát hiện gõ nhầm tên miền, hiện nút "Dùng ..." để sửa nhanh
  String? _suggestion;
  bool _saving = false;

  /// Màn hình này đang sửa email (true) hay tên hiển thị (false).
  bool get _isEmail => widget.field == EditField.email;

  /// Dọn controller, listener khi màn hình sửa tên hoặc email bị đóng để không rò bộ nhớ.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Kiểm tra dữ liệu, hỏi xác nhận rồi gửi lên server. Lỗi từ server hiện dưới ô nhập.
  Future<void> _save() async {
    final l = context.l10n;
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(
        () => _error = _isEmail
            ? l.errorEmailRequired
            : l.errorDisplayNameRequired,
      );
      return;
    }
    if (_isEmail) {
      if (!EmailCheck.isValid(value)) {
        setState(() => _error = l.errorEmailInvalid);
        return;
      }
      final suggestion = EmailCheck.suggest(value);
      if (suggestion != null) {
        setState(() {
          _suggestion = suggestion;
          _error = l.errorEmailTypo(suggestion);
        });
        return;
      }
    }
    final ok = await AppDialogs.confirm(
      context,
      title: l.confirmSaveTitle,
      message: l.confirmSaveMessage,
      confirmLabel: l.save,
    );
    if (!ok || !mounted) return;
    final vm = context.read<ProfileViewModel>();
    setState(() => _saving = true);
    final err = _isEmail
        ? await vm.updateEmail(value)
        : await vm.updateName(value);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      // Lỗi trùng email/tên thì hiện ngay dưới ô nhập để người dùng sửa
      setState(() {
        _suggestion = err == ProfileError.emailTypo ? vm.emailSuggestion : null;
        _error = l.profileError(err, suggestion: _suggestion);
      });
      return;
    }
    Navigator.pop(context);
    final pending = vm.pendingEmail;
    if (_isEmail && pending != null && pending == value.toLowerCase()) {
      // Email chưa đổi ngay, server đã gửi link xác nhận tới địa chỉ mới
      AppSnack.show(context, l.emailVerifySent(pending), type: AppSnackType.info);
    } else {
      AppSnack.show(context, l.saved);
    }
  }

  /// Dựng giao diện màn hình sửa tên hoặc email.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final label = _isEmail ? l.email : l.displayName;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l.editField(label)),
        actions: [
          TextButton(onPressed: _saving ? null : _save, child: Text(l.save)),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              keyboardType: _isEmail
                  ? TextInputType.emailAddress
                  : TextInputType.name,
              onChanged: (_) {
                if (_error != null || _suggestion != null) {
                  setState(() {
                    _error = null;
                    _suggestion = null;
                  });
                }
              },
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: label,
                errorText: _error,
                errorMaxLines: 3,
                prefixIcon: Icon(
                  _isEmail ? Icons.email_outlined : Icons.badge_outlined,
                ),
              ),
            ),
            if (_suggestion != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                  label: Text(l.useSuggestion(_suggestion!)),
                  onPressed: () => setState(() {
                    _controller.text = _suggestion!;
                    _controller.selection = TextSelection.collapsed(
                      offset: _suggestion!.length,
                    );
                    _error = null;
                    _suggestion = null;
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
