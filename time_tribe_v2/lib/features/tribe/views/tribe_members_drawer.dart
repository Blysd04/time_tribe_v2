import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_time.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../models/tribe_model.dart';
import '../viewmodels/tribe_viewmodel.dart';
import 'tribe_dialogs.dart';
import 'tribe_texts.dart';
import 'widgets/tribe_widgets.dart';

/// Danh sách thành viên, trượt ra từ bên phải (COM-02).
class TribeMembersDrawer extends StatelessWidget {
  final String tribeId;
  const TribeMembersDrawer({super.key, required this.tribeId});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<TribeViewModel>();
    final tribe = vm.tribeById(tribeId);
    final cs = Theme.of(context).colorScheme;
    if (tribe == null) return const Drawer();

    final myRole = tribe.roleOf(vm.me);
    final members = tribe.sortedMembers;
    final leaders = members.where((m) => m.role == TribeRole.leader).toList();
    final vices = members.where((m) => m.role == TribeRole.viceLeader).toList();
    final normal = members.where((m) => m.role == TribeRole.member).toList();

    Widget section(String title) =>
        SectionLabel(title, padding: const EdgeInsets.fromLTRB(20, 16, 20, 6));

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.members,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${l.membersCount(tribe.members.length, TribeLimits.maxMembersPerTribe)} · ${tribe.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(l.inviteMembers),
                onPressed:
                    tribe.members.length >= TribeLimits.maxMembersPerTribe
                    ? null
                    : () => showInviteSheet(context, tribe),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  section(l.roleLeader),
                  for (final m in leaders)
                    _MemberTile(tribe: tribe, member: m, myRole: myRole),
                  if (vices.isNotEmpty) ...[
                    section(
                      '${l.roleVice} (${vices.length}/${TribeLimits.maxViceLeaders})',
                    ),
                    for (final m in vices)
                      _MemberTile(tribe: tribe, member: m, myRole: myRole),
                  ],
                  if (normal.isNotEmpty) ...[
                    section(l.roleMember),
                    for (final m in normal)
                      _MemberTile(tribe: tribe, member: m, myRole: myRole),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  minimumSize: const Size.fromHeight(46),
                  backgroundColor: AppColors.danger.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: Text(l.leaveTribe),
                onPressed: () => _leave(context, tribe),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// COM-12 / COM-13
  Future<void> _leave(BuildContext context, TribeModel tribe) async {
    final l = context.l10n;
    final vm = context.read<TribeViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final isLeader = tribe.roleOf(vm.me) == TribeRole.leader;

    if (isLeader && tribe.members.length > 1) {
      // Bắt buộc chọn trưởng nhóm mới trước khi rời
      final successor = await _pickSuccessor(context, tribe);
      if (successor == null || !context.mounted) return;
      final ok = await AppDialogs.confirm(
        context,
        title: l.leaveTribeTitle,
        message: l.leaveAsLeaderMessage(successor.user.nickName, tribe.name),
        confirmLabel: l.leaveTribe,
        destructive: true,
      );
      if (!ok) return;
      vm.transferLeader(tribe.id, successor.userId);
      vm.leaveTribe(tribe.id);
    } else {
      final alone = isLeader && tribe.members.length == 1;
      final ok = await AppDialogs.confirm(
        context,
        title: l.leaveTribeTitle,
        message: alone
            ? l.leaveAloneMessage(tribe.name)
            : l.leaveTribeMessage(tribe.name),
        confirmLabel: alone ? l.dissolve : l.leaveTribe,
        destructive: true,
      );
      if (!ok) return;
      vm.leaveTribe(tribe.id);
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.leftTribe(tribe.name))));
  }

  Future<TribeMember?> _pickSuccessor(BuildContext context, TribeModel tribe) {
    final l = context.l10n;
    final candidates = tribe.sortedMembers
        .where((m) => m.role != TribeRole.leader)
        .toList();
    TribeMember? selected = candidates.first;
    return showDialog<TribeMember>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.chooseNewLeader),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.chooseNewLeaderMessage,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final m in candidates)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () => setState(() => selected = m),
                          leading: UserAvatar(user: m.user, size: 32),
                          title: Text(m.user.nickName),
                          subtitle: Text(
                            l.roleLabel(m.role),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Icon(
                            selected == m
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected == m
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: Text(l.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(64, 42)),
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(ctx, selected),
              child: Text(l.continueLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final TribeModel tribe;
  final TribeMember member;
  final TribeRole? myRole;

  const _MemberTile({
    required this.tribe,
    required this.member,
    required this.myRole,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.read<TribeViewModel>();
    final cs = Theme.of(context).colorScheme;
    final isMe = member.userId == vm.me;
    final canManage =
        !isMe && TribePermissions.canManageMember(myRole, member.role);

    // Giờ địa phương của thành viên -> dễ hẹn giờ khi khác múi giờ
    final localNow = isMe ? AppTime.now() : AppTime.nowIn(member.user.timezone);
    final offset = isMe
        ? AppTime.formatOffset(AppTime.currentOffset)
        : AppTime.offsetLabelOf(member.user.timezone);
    final night = localNow.hour < 7 || localNow.hour >= 23;

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 20, right: 8),
      leading: UserAvatar(user: member.user, size: 40),
      title: Row(
        children: [
          Flexible(
            child: Text(
              isMe
                  ? '${member.user.nickName} (${l.you})'
                  : member.user.nickName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          const SizedBox(width: 6),
          RoleBadge(role: member.role),
        ],
      ),
      subtitle: Row(
        children: [
          Icon(
            night ? Icons.bedtime_outlined : Icons.schedule,
            size: 13,
            color: cs.onSurface.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${Fmt.time(context, localNow)} · $offset',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
      trailing: canManage
          ? _MemberMenu(tribe: tribe, member: member, myRole: myRole)
          : null,
    );
  }
}

class _MemberMenu extends StatelessWidget {
  final TribeModel tribe;
  final TribeMember member;
  final TribeRole? myRole;

  const _MemberMenu({
    required this.tribe,
    required this.member,
    required this.myRole,
  });

  Future<void> _done(
    BuildContext context,
    TribeResult result,
    String successMessage,
  ) async {
    if (result != TribeResult.success) {
      AppSnack.show(
        context,
        context.l10n.tribeResult(result),
        type: AppSnackType.error,
      );
      return;
    }
    // Pop-up báo thành công theo yêu cầu COM-15/16/17
    await AppDialogs.success(context, successMessage);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.read<TribeViewModel>();
    final name = member.user.nickName;
    final isLeader = myRole == TribeRole.leader;
    final viceFull = tribe.viceLeaders.length >= TribeLimits.maxViceLeaders;

    PopupMenuItem<String> item(
      String value,
      IconData icon,
      String label, {
      Color? color,
      bool enabled = true,
      String? hint,
    }) => PopupMenuItem(
      value: value,
      enabled: enabled,
      child: Row(
        children: [
          Icon(icon, size: 20, color: enabled ? color : Colors.grey),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: enabled ? color : Colors.grey),
                ),
                if (hint != null)
                  Text(
                    hint,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) async {
        switch (value) {
          case 'vice':
            await _done(
              context,
              vm.appointVice(tribe.id, member.userId),
              l.appointedVice(name),
            );
          case 'dismiss':
            final ok = await AppDialogs.confirm(
              context,
              title: l.dismissViceTitle,
              message: l.dismissViceMessage(name),
              confirmLabel: l.dismiss,
            );
            if (ok && context.mounted) {
              await _done(
                context,
                vm.dismissVice(tribe.id, member.userId),
                l.dismissedVice(name),
              );
            }
          case 'leader':
            final willBeVice =
                tribe.viceLeaders
                    .where((v) => v.userId != member.userId)
                    .length <
                TribeLimits.maxViceLeaders;
            final ok = await AppDialogs.confirm(
              context,
              title: l.transferLeaderTitle,
              message: willBeVice
                  ? l.transferLeaderToVice(name)
                  : l.transferLeaderToMember(name),
              confirmLabel: l.appoint,
            );
            if (ok && context.mounted) {
              await _done(
                context,
                vm.transferLeader(tribe.id, member.userId),
                l.appointedLeader(name),
              );
            }
          case 'kick':
            final ok = await AppDialogs.confirm(
              context,
              title: l.kickTitle,
              message: l.kickMessage(name, tribe.name),
              confirmLabel: l.kick,
              destructive: true,
            );
            if (ok && context.mounted) {
              final res = vm.kickMember(tribe.id, member.userId);
              res == TribeResult.success
                  ? AppSnack.show(context, l.kicked(name))
                  : AppSnack.show(
                      context,
                      l.tribeResult(res),
                      type: AppSnackType.error,
                    );
            }
        }
      },
      itemBuilder: (_) => [
        if (isLeader && member.role == TribeRole.member)
          item(
            'vice',
            Icons.shield_outlined,
            l.appointVice,
            enabled: !viceFull,
            hint: viceFull
                ? l.errorViceLimit(TribeLimits.maxViceLeaders)
                : null,
          ),
        if (isLeader && member.role == TribeRole.viceLeader)
          item('dismiss', Icons.remove_moderator_outlined, l.dismissVice),
        if (isLeader)
          item('leader', Icons.workspace_premium_outlined, l.appointLeader),
        item(
          'kick',
          Icons.person_remove_outlined,
          l.kick,
          color: AppColors.danger,
        ),
      ],
    );
  }
}
