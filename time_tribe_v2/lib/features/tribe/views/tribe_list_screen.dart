import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_time.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/form_widgets.dart';
import '../models/tribe_model.dart';
import '../viewmodels/tribe_viewmodel.dart';
import 'tribe_dialogs.dart';
import 'widgets/tribe_widgets.dart';

/// COM-01: danh sách các nhóm đang tham gia.
class TribeListScreen extends StatelessWidget {
  const TribeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<TribeViewModel>();
    final tribes = vm.tribes;

    if (tribes.isEmpty) {
      return EmptyState(
        icon: Icons.groups_outlined,
        title: l.noTribesTitle,
        message: l.noTribesMessage,
        actions: [
          ElevatedButton.icon(
            onPressed: () => showCreateTribeDialog(context),
            icon: const Icon(Icons.add),
            label: Text(l.createTribe),
          ),
          OutlinedButton.icon(
            onPressed: () => showJoinTribeDialog(context),
            icon: const Icon(Icons.link),
            label: Text(l.joinTribe),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        4,
        AppSpacing.page,
        24,
      ),
      children: [
        SectionLabel(
          l.yourTribes,
          trailing: CountPill(
            '${tribes.length}/${TribeLimits.maxTribesPerUser}',
          ),
          padding: const EdgeInsets.fromLTRB(4, 0, 0, 12),
        ),
        for (final tribe in tribes) _TribeCard(tribe: tribe),
      ],
    );
  }
}

class _TribeCard extends StatelessWidget {
  final TribeModel tribe;
  const _TribeCard({required this.tribe});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<TribeViewModel>();
    final cs = Theme.of(context).colorScheme;
    final role = tribe.roleOf(vm.me) ?? TribeRole.member;
    final pending = vm.pendingCountForMe(tribe.id);
    final next = vm.nextBlockOf(tribe.id);

    return AppCard(
      accent: tribe.color,
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
      onTap: () => openTribeDetail(context, tribe.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TribeAvatar(tribe: tribe),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tribe.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    RoleBadge(role: role),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AvatarStack(
                      users: tribe.sortedMembers.map((m) => m.user).toList(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.membersCount(
                        tribe.members.length,
                        TribeLimits.maxMembersPerTribe,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _NextActivity(
                  color: tribe.color,
                  task: next?.task,
                  startUtc: next?.startUtc,
                ),
                if (pending > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l.pendingForYou(pending),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _TribeMenu(tribe: tribe, role: role),
        ],
      ),
    );
  }
}

class _NextActivity extends StatelessWidget {
  final Color color;
  final String? task;
  final DateTime? startUtc;
  const _NextActivity({required this.color, this.task, this.startUtc});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.5);
    if (task == null) {
      return Text(
        l.noUpcomingActivity,
        style: TextStyle(fontSize: 12, color: muted),
      );
    }

    final local = AppTime.fromUtc(startUtc!);
    final diff = DateTime(
      local.year,
      local.month,
      local.day,
    ).difference(AppTime.today()).inDays;
    final day = switch (diff) {
      0 => l.today,
      1 => l.tomorrow,
      _ => Fmt.dayMonth(context, local),
    };
    return Row(
      children: [
        Icon(Icons.event_outlined, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$day ${Fmt.time(context, local)} · $task',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Menu 3 chấm — hiện mục theo chức vụ.
class _TribeMenu extends StatelessWidget {
  final TribeModel tribe;
  final TribeRole role;
  const _TribeMenu({required this.tribe, required this.role});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;

    PopupMenuItem<String> item(
      String value,
      IconData icon,
      String label, {
      Color? color,
    }) => PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, color: cs.onSurface.withValues(alpha: 0.4)),
      onSelected: (value) async {
        switch (value) {
          case 'invite':
            showInviteSheet(context, tribe);
          case 'rename':
            showRenameTribeDialog(context, tribe);
          case 'color':
            showTribeColorSheet(context, tribe);
          case 'dissolve':
            final ok = await AppDialogs.confirm(
              context,
              title: l.dissolveTribeTitle,
              message: l.dissolveTribeMessage(tribe.name),
              confirmLabel: l.dissolve,
              destructive: true,
            );
            if (ok && context.mounted) {
              context.read<TribeViewModel>().dissolveTribe(tribe.id);
              AppSnack.show(context, l.tribeDissolved(tribe.name));
            }
        }
      },
      itemBuilder: (_) => [
        item('invite', Icons.person_add_alt_1_outlined, l.inviteShareLink),
        if (TribePermissions.canRename(role))
          item('rename', Icons.edit_outlined, l.renameTribe),
        if (TribePermissions.canChangeColor(role))
          item('color', Icons.palette_outlined, l.tribeColor),
        if (TribePermissions.canDissolve(role))
          item(
            'dissolve',
            Icons.delete_outline,
            l.dissolveTribe,
            color: AppColors.danger,
          ),
      ],
    );
  }
}
