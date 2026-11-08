import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../models/tribe_block_model.dart';
import '../../viewmodels/tribe_viewmodel.dart';
import '../tribe_texts.dart';

/// Hai nút "Tham gia" / "Không tham gia". Dùng trong thông báo, lịch cá nhân,
/// lịch nhóm và trang chi tiết. Người dùng đổi lựa chọn được bất cứ lúc nào.
class TribeBlockResponseButtons extends StatelessWidget {
  final String blockId;
  final VoidCallback? onResponded;
  final bool expanded;

  const TribeBlockResponseButtons({
    super.key,
    required this.blockId,
    this.onResponded,
    this.expanded = false,
  });

  /// Dựng giao diện hai nút Tham gia / Không tham gia.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<TribeViewModel>();
    final block = vm.blockById(blockId);
    if (block == null) {
      // Hoạt động nằm ngoài khoảng ngày đã tải thì hỏi server một lần
      if (vm.ensureBlock(blockId)) {
        return const Padding(
          padding: EdgeInsets.only(top: 8),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          l.activityCancelled,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    final isPast = block.endUtc.isBefore(DateTime.now().toUtc());
    final status = block.statusOf(vm.me);

    // Bấm Tham gia / Không tham gia: gửi lên server, lỗi thì báo lại
    Future<void> answer(AttendanceStatus s) async {
      final res = await vm.respond(blockId, s);
      if (!context.mounted) return;
      if (res != TribeResult.success) {
        AppSnack.show(
          context,
          context.l10n.tribeResult(res),
          type: AppSnackType.error,
        );
        return;
      }
      onResponded?.call();
      AppSnack.show(
        context,
        s == AttendanceStatus.accepted
            ? l.respondedAccepted
            : l.respondedDeclined,
        type: s == AttendanceStatus.accepted
            ? AppSnackType.success
            : AppSnackType.info,
      );
    }

    Widget button(AttendanceStatus s, IconData icon, Color color) {
      final selected = status == s;
      final child = Padding(
        padding: const EdgeInsets.only(right: 8),
        child: OutlinedButton.icon(
          onPressed: isPast ? null : () => answer(s),
          icon: Icon(
            selected ? Icons.check_circle : icon,
            size: 16,
            color: selected ? Colors.white : color,
          ),
          label: Text(
            l.attendanceLabel(s),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: selected ? Colors.white : color,
            ),
          ),
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? color : Colors.transparent,
            side: BorderSide(
              color: color.withValues(alpha: selected ? 1 : 0.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 38),
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
      return expanded ? Expanded(child: child) : child;
    }

    if (isPast) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          l.activityEnded,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          button(AttendanceStatus.accepted, Icons.check, AppColors.success),
          button(AttendanceStatus.declined, Icons.close, AppColors.danger),
        ],
      ),
    );
  }
}
