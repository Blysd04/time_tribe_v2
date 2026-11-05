import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../viewmodels/profile_viewmodel.dart';

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

  @override
  State<EditTextScreen> createState() => _EditTextScreenState();
}

class _EditTextScreenState extends State<EditTextScreen> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );
  String? _error;

  bool get _isEmail => widget.field == EditField.email;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    if (_isEmail && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      setState(() => _error = l.errorEmailInvalid);
      return;
    }
    final ok = await AppDialogs.confirm(
      context,
      title: l.confirmSaveTitle,
      message: l.confirmSaveMessage,
      confirmLabel: l.save,
    );
    if (!ok || !mounted) return;
    final vm = context.read<ProfileViewModel>();
    _isEmail ? vm.updateEmail(value) : vm.updateName(value);
    Navigator.pop(context);
    AppSnack.show(context, l.saved);
  }

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
          TextButton(onPressed: _save, child: Text(l.save)),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: _isEmail
              ? TextInputType.emailAddress
              : TextInputType.name,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: label,
            errorText: _error,
            prefixIcon: Icon(
              _isEmail ? Icons.email_outlined : Icons.badge_outlined,
            ),
          ),
        ),
      ),
    );
  }
}
