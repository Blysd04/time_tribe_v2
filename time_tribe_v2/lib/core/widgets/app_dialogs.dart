import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

enum AppSnackType { success, error, info }

/// Thông báo nhanh ở cuối màn hình, dùng chung một kiểu cho toàn app.
class AppSnack {
  AppSnack._();

  /// Hiện snackbar ở cuối màn hình với màu theo loại: thành công, lỗi, thông tin.
  static void show(
    BuildContext context,
    String message, {
    AppSnackType type = AppSnackType.success,
  }) {
    final (color, icon) = switch (type) {
      AppSnackType.success => (AppColors.success, Icons.check_circle),
      AppSnackType.error => (AppColors.danger, Icons.error_outline),
      AppSnackType.info => (const Color(0xFF334155), Icons.info_outline),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

/// Hộp thoại dùng chung.
class AppDialogs {
  AppDialogs._();

  /// Hỏi xác nhận. Trả về true khi người dùng đồng ý.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message, style: const TextStyle(height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: Text(ctx.l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: destructive
                  ? AppColors.danger
                  : AppColors.primary,
              minimumSize: const Size(64, 42),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// Pop-up báo thành công (dấu tích xanh).
  static Future<void> success(BuildContext context, String message) =>
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 52,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.ok),
            ),
          ],
        ),
      );
}

/// Một lựa chọn trong bottom sheet.
class SheetOption {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const SheetOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color = AppColors.primary,
    this.enabled = true,
  });
}

/// Bottom sheet chứa danh sách lựa chọn (VD: nút "+" ở thanh điều hướng).
Future<void> showOptionsSheet(
  BuildContext context, {
  String? title,
  Widget? header,
  required List<SheetOption> options,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (header != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: header,
                ),
              for (final o in options)
                ListTile(
                  enabled: o.enabled,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 2,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: o.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      o.icon,
                      color: o.enabled ? o.color : Colors.grey,
                    ),
                  ),
                  title: Text(
                    o.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  subtitle: o.subtitle == null
                      ? null
                      : Text(
                          o.subtitle!,
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                  onTap: () {
                    Navigator.pop(ctx);
                    o.onTap();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Kết quả xử lý trong [showInputDialog].
class InputOutcome<T> {
  final T? value;
  final String? message;
  final bool isError;
  final String? actionLabel;
  final T? actionValue;

  /// Thành công -> đóng hộp thoại và trả về [value].
  const InputOutcome.done(this.value)
    : message = null,
      isError = false,
      actionLabel = null,
      actionValue = null;

  /// Lỗi -> hiện chữ đỏ dưới ô nhập, giữ hộp thoại mở để sửa.
  const InputOutcome.error(this.message)
    : value = null,
      isError = true,
      actionLabel = null,
      actionValue = null;

  /// Thông tin (không phải lỗi), có thể kèm nút hành động (VD: "Mở nhóm").
  const InputOutcome.info(this.message, {this.actionLabel, this.actionValue})
    : value = null,
      isError = false;

  /// Kết quả là xong (đóng hộp thoại) hay còn thông báo cần hiện.
  bool get isDone => message == null;
}

/// Hộp thoại có 1 ô nhập. Hộp thoại tự quản lý TextEditingController nên
/// không bị lỗi "controller đã bị huỷ" khi đóng (nguyên nhân màn hình đỏ).
Future<T?> showInputDialog<T>(
  BuildContext context, {
  required String title,
  String? description,
  String? hint,
  String initialValue = '',
  required String confirmLabel,
  Color confirmColor = AppColors.primary,
  int? maxLength,
  IconData? prefixIcon,
  required FutureOr<InputOutcome<T>> Function(String value) onSubmit,
}) {
  return showDialog<T>(
    context: context,
    builder: (_) => _InputDialog<T>(
      title: title,
      description: description,
      hint: hint,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      confirmColor: confirmColor,
      maxLength: maxLength,
      prefixIcon: prefixIcon,
      onSubmit: onSubmit,
    ),
  );
}

class _InputDialog<T> extends StatefulWidget {
  final String title;
  final String? description;
  final String? hint;
  final String initialValue;
  final String confirmLabel;
  final Color confirmColor;
  final int? maxLength;
  final IconData? prefixIcon;
  final FutureOr<InputOutcome<T>> Function(String value) onSubmit;

  const _InputDialog({
    required this.title,
    required this.description,
    required this.hint,
    required this.initialValue,
    required this.confirmLabel,
    required this.confirmColor,
    required this.maxLength,
    required this.prefixIcon,
    required this.onSubmit,
  });

  /// Tạo phần state giữ dữ liệu thay đổi của hộp thoại có một ô nhập.
  @override
  State<_InputDialog<T>> createState() => _InputDialogState<T>();
}

class _InputDialogState<T> extends State<_InputDialog<T>> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  InputOutcome<T>? _feedback;
  bool _busy = false;

  /// Dọn controller, listener khi hộp thoại có một ô nhập bị đóng để không rò bộ nhớ.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Bấm nút xác nhận: gọi hàm xử lý, xong thì đóng hộp thoại, lỗi thì hiện ngay dưới ô nhập.
  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    final outcome = await widget.onSubmit(_controller.text);
    if (!mounted) return;
    if (outcome.isDone) {
      Navigator.pop(context, outcome.value);
      return;
    }
    setState(() {
      _busy = false;
      _feedback = outcome;
    });
  }

  /// Dựng giao diện hộp thoại có một ô nhập.
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fb = _feedback;
    final infoColor = fb != null && !fb.isError ? AppColors.primary : null;

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.description != null) ...[
            Text(
              widget.description!,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: widget.maxLength,
            enabled: !_busy,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_feedback != null) setState(() => _feedback = null);
            },
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: widget.hint,
              counterText: '',
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Icon(widget.prefixIcon),
              fillColor: cs.onSurface.withValues(alpha: 0.05),
              errorText: fb != null && fb.isError ? fb.message : null,
              errorMaxLines: 3,
            ),
          ),
          if (fb != null && !fb.isError) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: infoColor!.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: infoColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fb.message!,
                      style: TextStyle(
                        fontSize: 13,
                        color: infoColor,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: Text(context.l10n.cancel),
        ),
        if (fb != null && fb.actionLabel != null)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, fb.actionValue),
            style: ElevatedButton.styleFrom(minimumSize: const Size(64, 42)),
            child: Text(fb.actionLabel!),
          )
        else
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.confirmColor,
              minimumSize: const Size(64, 42),
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(widget.confirmLabel),
          ),
      ],
    );
  }
}
