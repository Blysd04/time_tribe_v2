import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_time.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../models/tribe_block_model.dart';
import '../../viewmodels/tribe_viewmodel.dart';
import '../add_edit_tribe_block_screen.dart';
import 'tribe_block_response_buttons.dart';

/// Bấm vào một hoạt động nhóm (ở lịch cá nhân hoặc lịch nhóm) -> mở sheet
/// này để xem nhanh và bấm Tham gia / Không tham gia ngay.
Future<void> showTribeBlockSheet(BuildContext context, String blockId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _TribeBlockSheet(blockId: blockId),
  );
}

class _TribeBlockSheet extends StatelessWidget {
  final String blockId;
  const _TribeBlockSheet({required this.blockId});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final vm = context.watch<TribeViewModel>();
    final block = vm.blockById(blockId);
    final tribe = block == null ? null : vm.tribeById(block.tribeId);
    if (block == null || tribe == null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l.errorItemGone),
        ),
      );
    }

    final start = AppTime.fromUtc(block.startUtc);
    final end = AppTime.fromUtc(block.endUtc);
    List<AppUser> usersWith(AttendanceStatus s) => tribe.sortedMembers
        .where((m) => block.statusOf(m.userId) == s)
        .map((m) => m.user)
        .toList();
    final accepted = usersWith(AttendanceStatus.accepted);
    final declined = usersWith(AttendanceStatus.declined);
    final pending = usersWith(AttendanceStatus.pending);

    Widget group(String label, List<AppUser> users, Color color) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label (${users.length})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          users.isEmpty
              ? Text(
                  '—',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
                )
              : AvatarStack(users: users, size: 24),
        ],
      ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: tribe.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tribe.name,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              block.task,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: block.flutterColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${Fmt.longDate(context, start)} · ${Fmt.range(context, start, end)}',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            if ((block.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                block.description!,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                group(l.attendanceAccepted, accepted, AppColors.success),
                group(l.attendanceDeclined, declined, AppColors.danger),
                group(
                  l.attendancePending,
                  pending,
                  cs.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l.areYouJoining,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TribeBlockResponseButtons(blockId: block.id, expanded: true),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditTribeBlockScreen(
                        tribeId: tribe.id,
                        block: block,
                      ),
                    ),
                  );
                },
                child: Text(l.viewDetails),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
