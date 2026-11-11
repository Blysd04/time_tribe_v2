import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/form_widgets.dart';
import '../models/tribe_model.dart';
import '../viewmodels/tribe_viewmodel.dart';
import 'tribe_detail_screen.dart';
import 'tribe_texts.dart';

/// Mở trang lịch của một nhóm.
void openTribeDetail(BuildContext context, String tribeId) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => TribeDetailScreen(tribeId: tribeId)),
  );
}

/// Nút "+" ở thanh điều hướng khi đang ở mục Lịch Nhóm.
void showTribeAddOptions(BuildContext context) {
  final l = context.l10n;
  final vm = context.read<TribeViewModel>();
  showOptionsSheet(
    context,
    title: l.tribes,
    header: vm.canCreateOrJoin
        ? null
        : InfoBanner(
            text: l.errorTribeLimit(TribeLimits.maxTribesPerUser),
            color: AppColors.warning,
          ),
    options: [
      SheetOption(
        icon: Icons.group_add_outlined,
        title: l.createTribe,
        subtitle: l.createTribeHint,
        enabled: vm.canCreateOrJoin,
        onTap: () => showCreateTribeDialog(context),
      ),
      SheetOption(
        icon: Icons.vpn_key_outlined,
        color: AppColors.success,
        title: l.joinTribe,
        subtitle: l.joinTribeHint,
        enabled: vm.canCreateOrJoin,
        onTap: () => showJoinTribeDialog(context),
      ),
    ],
  );
}

/// COM-03: tạo nhóm -> mở luôn trang lịch nhóm.
Future<void> showCreateTribeDialog(BuildContext context) async {
  final l = context.l10n;
  final vm = context.read<TribeViewModel>();
  final tribeId = await showInputDialog<String>(
    context,
    title: l.createTribe,
    hint: l.tribeNameHint,
    confirmLabel: l.create,
    maxLength: TribeLimits.maxNameLength,
    prefixIcon: Icons.groups_outlined,
    onSubmit: (value) async {
      final res = await vm.createTribe(value);
      return res.result == TribeResult.success
          ? InputOutcome.done(res.tribe!.id)
          : InputOutcome.error(l.tribeResult(res.result));
    },
  );
  if (tribeId != null && context.mounted) {
    AppSnack.show(context, l.tribeCreated);
    openTribeDetail(context, tribeId);
  }
}

/// COM-11: tham gia nhóm bằng mã mời.
Future<void> showJoinTribeDialog(BuildContext context) async {
  final l = context.l10n;
  final vm = context.read<TribeViewModel>();
  bool joinedNew = false;
  final tribeId = await showInputDialog<String>(
    context,
    title: l.joinTribe,
    description: l.joinTribeDescription,
    hint: 'NIC2026',
    confirmLabel: l.join,
    confirmColor: AppColors.success,
    prefixIcon: Icons.vpn_key_outlined,
    onSubmit: (value) async {
      final res = await vm.joinByCode(value);
      switch (res.result) {
        case TribeResult.success:
          joinedNew = true;
          return InputOutcome.done(res.tribe!.id);
        case TribeResult.alreadyMember when res.tribe != null:
          // Không phải lỗi: báo rõ là đã ở trong nhóm, cho mở nhanh
          return InputOutcome.info(
            l.infoAlreadyMemberOf(res.tribe!.name),
            actionLabel: l.openTribe,
            actionValue: res.tribe!.id,
          );
        default:
          return InputOutcome.error(l.tribeResult(res.result));
      }
    },
  );
  if (tribeId == null || !context.mounted) return;
  if (joinedNew) {
    AppSnack.show(context, l.joinedTribe(vm.tribeById(tribeId)?.name ?? ''));
  }
  openTribeDetail(context, tribeId);
}

/// Đổi tên nhóm (chỉ trưởng nhóm).
Future<void> showRenameTribeDialog(
  BuildContext context,
  TribeModel tribe,
) async {
  final l = context.l10n;
  final vm = context.read<TribeViewModel>();
  final ok = await showInputDialog<bool>(
    context,
    title: l.renameTribe,
    initialValue: tribe.name,
    confirmLabel: l.save,
    maxLength: TribeLimits.maxNameLength,
    onSubmit: (value) async {
      final res = await vm.renameTribe(tribe.id, value);
      return res == TribeResult.success
          ? const InputOutcome.done(true)
          : InputOutcome.error(l.tribeResult(res));
    },
  );
  if (ok == true && context.mounted) AppSnack.show(context, l.tribeRenamed);
}

/// COM-18: chia sẻ mã mời vào nhóm.
void showInviteSheet(BuildContext context, TribeModel tribe) {
  final l = context.l10n;
  showModalBottomSheet(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.inviteTo(tribe.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.inviteDescription(
                  TribeLimits.maxMembersPerTribe,
                  tribe.members.length,
                ),
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(
                  left: 14,
                  right: 6,
                  top: 6,
                  bottom: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.vpn_key_outlined,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SelectableText(
                        tribe.inviteCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: tribe.inviteCode),
                        );
                        Navigator.pop(ctx);
                        AppSnack.show(context, l.codeCopied);
                      },
                      child: Text(l.copy),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
