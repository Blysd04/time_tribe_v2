import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../auth/views/login_screen.dart';
import '../../notifications/viewmodels/notification_viewmodel.dart';
import '../../tribe/models/tribe_model.dart';
import '../../tribe/viewmodels/tribe_viewmodel.dart';

enum _Reason { notUsing, otherApp, privacy, other }

/// Xoá tài khoản: chọn lý do (lưu vào `user_securities.delete_reason`),
/// xem trước ảnh hưởng tới các nhóm, xác nhận 2 bước.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _otherController = TextEditingController();
  _Reason? _reason;
  bool _understood = false;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  String _label(AppLocalizations l, _Reason r) => switch (r) {
    _Reason.notUsing => l.reasonNotUsing,
    _Reason.otherApp => l.reasonOtherApp,
    _Reason.privacy => l.reasonPrivacy,
    _Reason.other => l.reasonOther,
  };

  bool get _canSubmit =>
      _reason != null &&
      _understood &&
      (_reason != _Reason.other || _otherController.text.trim().isNotEmpty);

  Future<void> _submit() async {
    final l = context.l10n;
    final ok = await AppDialogs.confirm(
      context,
      title: l.deleteAccountFinalTitle,
      message: l.deleteAccountFinalMessage,
      confirmLabel: l.deleteAccount,
      destructive: true,
    );
    if (!ok || !mounted) return;

    final reason = _reason == _Reason.other
        ? _otherController.text.trim()
        : _reason!.name;
    final auth = context.read<AuthViewModel>();
    final tribes = context.read<TribeViewModel>();
    final notifications = context.read<NotificationViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await auth.deleteAccount(reason);
    tribes.leaveAllForAccountDeletion();
    notifications.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      // Giữ lại cài đặt ngôn ngữ / giao diện của máy, xoá dữ liệu cá nhân
      for (final key in prefs.getKeys().where(
        (k) => k.startsWith('profile.'),
      )) {
        await prefs.remove(key);
      }
    } catch (_) {}

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text(l.accountDeleted),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final tribeVm = context.watch<TribeViewModel>();
    final loading = context.watch<AuthViewModel>().isLoading;
    final leaderOf = tribeVm.tribes
        .where((t) => t.roleOf(tribeVm.me) == TribeRole.leader)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.deleteAccount)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          8,
          AppSpacing.page,
          32,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.deleteAccountWarningTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final line in [
                  l.deleteConsequence1,
                  l.deleteConsequence2,
                  l.deleteConsequence3,
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•  ',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.8),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (leaderOf.isNotEmpty) ...[
            const SizedBox(height: 20),
            SectionLabel(l.tribesYouLead),
            for (final t in leaderOf)
              AppCard(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: t.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.members.length > 1
                            ? l.leadershipGoesTo(
                                t.name,
                                t.sortedMembers
                                    .firstWhere((m) => m.userId != tribeVm.me)
                                    .user
                                    .nickName,
                              )
                            : l.tribeWillBeDissolved(t.name),
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 20),
          SectionLabel(l.deleteReasonTitle),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final r in _Reason.values)
                  ListTile(
                    onTap: () => setState(() => _reason = r),
                    leading: Icon(
                      _reason == r
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: _reason == r ? AppColors.danger : Colors.grey,
                    ),
                    title: Text(_label(l, r)),
                  ),
                if (_reason == _Reason.other)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _otherController,
                      maxLength: 255,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: l.reasonOtherHint,
                        fillColor: cs.onSurface.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          CheckboxListTile(
            value: _understood,
            onChanged: (v) => setState(() => _understood = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.danger,
            title: Text(
              l.deleteUnderstand,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: !_canSubmit || loading ? null : _submit,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.delete_forever_outlined),
            label: Text(l.deleteAccountPermanently),
          ),
          const SizedBox(height: 8),
          if (!_canSubmit)
            InfoBanner(
              text: l.deleteAccountHint,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
        ],
      ),
    );
  }
}
