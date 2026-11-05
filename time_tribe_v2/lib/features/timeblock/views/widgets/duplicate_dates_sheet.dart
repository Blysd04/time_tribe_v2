import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_time.dart';

/// Lý do một ngày không chọn được để nhân bản.
enum DuplicateBlockReason { past, sameDay, conflict }

/// Lịch tháng cho phép chọn NHIỀU ngày để nhân bản một lịch cá nhân.
/// - Chỉ chọn được từ hôm nay trở đi.
/// - Ngày đang có lịch trùng khung giờ (hoặc chính ngày gốc) bị khoá.
Future<Set<DateTime>?> showDuplicateDatesSheet(
  BuildContext context, {
  required Set<DateTime> initial,
  required DuplicateBlockReason? Function(DateTime day) blockedReason,
}) {
  return showModalBottomSheet<Set<DateTime>>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _DuplicateDatesSheet(initial: initial, blockedReason: blockedReason),
  );
}

class _DuplicateDatesSheet extends StatefulWidget {
  final Set<DateTime> initial;
  final DuplicateBlockReason? Function(DateTime day) blockedReason;

  const _DuplicateDatesSheet({
    required this.initial,
    required this.blockedReason,
  });

  @override
  State<_DuplicateDatesSheet> createState() => _DuplicateDatesSheetState();
}

class _DuplicateDatesSheetState extends State<_DuplicateDatesSheet> {
  late final Set<DateTime> _selected = {...widget.initial};
  late DateTime _month;
  final DateTime _today = AppTime.today();

  @override
  void initState() {
    super.initState();
    _month = DateTime(_today.year, _today.month);
  }

  DateTime _key(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final firstWeekday = DateTime(
      _month.year,
      _month.month,
      1,
    ).weekday; // 1 = T2
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final canGoBack = _month.isAfter(DateTime(_today.year, _today.month));

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.duplicateTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              l.duplicateDescription,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: canGoBack
                      ? () => setState(
                          () =>
                              _month = DateTime(_month.year, _month.month - 1),
                        )
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    l.monthYear(_month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(
                    () => _month = DateTime(_month.year, _month.month + 1),
                  ),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Row(
              children: [
                for (int w = 1; w <= 7; w++)
                  Expanded(
                    child: Center(
                      child: Text(
                        l.weekdayShort(w),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.05,
              children: [
                for (int i = 1; i < firstWeekday; i++) const SizedBox.shrink(),
                for (int d = 1; d <= daysInMonth; d++)
                  _dayCell(DateTime(_month.year, _month.month, d), cs),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _legend(cs, AppColors.primary, l.selected),
                _legend(cs, AppColors.danger, l.conflictingDay),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_selected.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(_selected.clear),
                    child: Text(l.clearAll),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: Text(
                    _selected.isEmpty
                        ? l.done
                        : l.selectedDays(_selected.length),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(ColorScheme cs, Color c, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: cs.onSurface.withValues(alpha: 0.6),
        ),
      ),
    ],
  );

  Widget _dayCell(DateTime day, ColorScheme cs) {
    final reason = day.isBefore(_today)
        ? DuplicateBlockReason.past
        : widget.blockedReason(day);
    final selected = _selected.contains(_key(day));
    final isToday = day == _today;
    final disabled = reason != null;

    return GestureDetector(
      onTap: disabled
          ? null
          : () => setState(
              () => selected
                  ? _selected.remove(_key(day))
                  : _selected.add(_key(day)),
            ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday && !selected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (disabled
                          ? cs.onSurface.withValues(alpha: 0.22)
                          : cs.onSurface),
                decoration: reason == DuplicateBlockReason.conflict
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            if (reason == DuplicateBlockReason.conflict)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
