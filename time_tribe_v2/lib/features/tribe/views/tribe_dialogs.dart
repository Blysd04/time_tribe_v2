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
        icon: Icons.link_rounded,
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
    onSubmit: (value) {
      final res = vm.createTribe(value);
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

/// COM-11: tham gia bằng đường link mời.
Future<void> showJoinTribeDialog(BuildContext context) async {
  final l = context.l10n;
  final vm = context.read<TribeViewModel>();
  bool joinedNew = false;
  final tribeId = await showInputDialog<String>(
    context,
    title: l.joinTribe,
    description: l.joinTribeDescription,
    hint: 'timetribe.app/tribe/ABC123',
    confirmLabel: l.join,
    confirmColor: AppColors.success,
    prefixIcon: Icons.link,
    onSubmit: (value) {
      final res = vm.joinByLink(value);
      switch (res.result) {
        case TribeResult.success:
          joinedNew = true;
          return InputOutcome.done(res.tribe!.id);
        case TribeResult.alreadyMember:
          // Không phải lỗi: báo rõ là đã ở trong nhóm, cho mở nhanh
          return InputOutcome.info(
            l.infoAlreadyMemberOf(res.tribe!.name),
            actionLabel: l.openTribe,
            actionValue: res.tribe!.id,
          );
        case TribeResult.tribeFull:
          return InputOutcome.error(
            l.errorTribeFullNamed(
              res.tribe!.name,
              TribeLimits.maxMembersPerTribe,
            ),
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
    onSubmit: (value) {
      final res = vm.renameTribe(tribe.id, value);
      return res == TribeResult.success
          ? const InputOutcome.done(true)
          : InputOutcome.error(l.tribeResult(res));
    },
  );
  if (ok == true && context.mounted) AppSnack.show(context, l.tribeRenamed);
}

/// COM-18: chia sẻ đường link mời.
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
                      Icons.link,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tribe.inviteLink,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
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
                          ClipboardData(text: tribe.inviteLink),
                        );
                        Navigator.pop(ctx);
                        AppSnack.show(context, l.linkCopied);
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

/// COM-09: đổi màu nhóm (trưởng & phó nhóm).
void showTribeColorSheet(BuildContext context, TribeModel tribe) {
  final l = context.l10n;
  showModalBottomSheet(
    context: context,
    builder: (ctx) {
      String color = tribe.backgroundColor ?? AppColors.palette.first;
      return StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.tribeColor,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ColorDotPicker(
                  colors: AppColors.palette,
                  selected: color,
                  size: 40,
                  onSelected: (c) => setState(() => color = c),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final res = context.read<TribeViewModel>().updateColor(
                        tribe.id,
                        color,
                      );
                      Navigator.pop(ctx);
                      res == TribeResult.success
                          ? AppSnack.show(context, l.tribeColorUpdated)
                          : AppSnack.show(
                              context,
                              l.tribeResult(res),
                              type: AppSnackType.error,
                            );
                    },
                    child: Text(l.save),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
