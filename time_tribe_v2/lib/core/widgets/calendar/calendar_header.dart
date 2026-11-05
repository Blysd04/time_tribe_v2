import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_time.dart';

/// Phần đầu lịch: "Tháng 11, 2026" + dòng phụ + nút mở lịch tháng.
class CalendarHeader extends StatelessWidget {
  final DateTime selectedDate;
  final String subtitle;
  final bool expanded;
  final VoidCallback onToggle;

  const CalendarHeader({
    super.key,
    required this.selectedDate,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.monthYear(selectedDate),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: context.l10n.monthView,
            child: GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: expanded
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : cs.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: expanded
                        ? Colors.transparent
                        : cs.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.calendar_month_rounded,
                  color: expanded ? AppColors.primary : cs.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trang trí cho 1 ô ngày: màu trạng thái (vạch dưới + viền) và số hoạt động.
class DayDecoration {
  final Color? statusColor;
  final int badge;
  const DayDecoration({this.statusColor, this.badge = 0});
}

/// Thanh chọn ngày cuộn ngang (15 ngày, ngày đang chọn ở giữa).
class DayStrip extends StatefulWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  final DayDecoration Function(DateTime day)? decorate;
  final DateTime? firstDay;

  const DayStrip({
    super.key,
    required this.selected,
    required this.onSelected,
    this.decorate,
    this.firstDay,
  });

  @override
  State<DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<DayStrip> {
  static const double _extent = 66;
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _center(animate: false),
    );
  }

  @override
  void didUpdateWidget(DayStrip old) {
    super.didUpdateWidget(old);
    if (!_same(old.selected, widget.selected)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _center());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<DateTime> get _days {
    final s = widget.selected;
    final first = widget.firstDay;
    return [for (int i = -7; i <= 7; i++) DateTime(s.year, s.month, s.day + i)]
        .where(
          (d) =>
              first == null ||
              !d.isBefore(DateTime(first.year, first.month, first.day)),
        )
        .toList();
  }

  void _center({bool animate = true}) {
    if (!mounted || !_controller.hasClients) return;
    final index = _days.indexWhere((d) => _same(d, widget.selected));
    if (index < 0) return;
    final width = MediaQuery.of(context).size.width;
    final target = (index * _extent - width / 2 + _extent / 2 + 16).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    animate
        ? _controller.animateTo(
            target,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          )
        : _controller.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = context.l10n;
    final today = AppTime.today();
    final days = _days;

    return SizedBox(
      height: 84,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        itemExtent: _extent,
        itemBuilder: (context, i) {
          final d = days[i];
          final deco = widget.decorate?.call(d) ?? const DayDecoration();
          final status = deco.statusColor;
          final selected = _same(d, widget.selected);
          final isToday = _same(d, today);
          final base = status ?? cs.onSurface.withValues(alpha: 0.12);

          return GestureDetector(
            onTap: () => widget.onSelected(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, bottom: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : (status == null
                          ? cs.surface
                          : status.withValues(alpha: 0.12)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : (isToday
                            ? AppColors.primary
                            : base.withValues(
                                alpha: status == null ? 1 : 0.45,
                              )),
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : cs.onSurface,
                          ),
                        ),
                        Text(
                          l.weekdayShort(d.weekday),
                          style: TextStyle(
                            fontSize: 11,
                            color: selected
                                ? Colors.white70
                                : cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        if (status != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 18,
                            height: 4,
                            decoration: BoxDecoration(
                              color: selected ? Colors.white : status,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (deco.badge > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? Colors.white : AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${deco.badge}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: selected ? AppColors.primary : Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Lịch tháng gọn (mở ra khi bấm nút lịch ở header).
class MonthCalendar extends StatelessWidget {
  final DateTime selected;
  final DateTime firstDate;
  final ValueChanged<DateTime> onSelected;

  const MonthCalendar({
    super.key,
    required this.selected,
    required this.firstDate,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final last = DateTime(AppTime.now().year + 10);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CalendarDatePicker(
        initialDate: selected.isBefore(firstDate) ? firstDate : selected,
        firstDate: firstDate,
        lastDate: last,
        currentDate: AppTime.today(),
        onDateChanged: onSelected,
      ),
    );
  }
}

/// Tiêu đề lịch + thanh ngày + lịch tháng có hiệu ứng chuyển đổi.
class CalendarPanel extends StatelessWidget {
  final DateTime selected;
  final String subtitle;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<DateTime> onSelected;
  final DayDecoration Function(DateTime day)? decorate;
  final DateTime firstDate;

  const CalendarPanel({
    super.key,
    required this.selected,
    required this.subtitle,
    required this.expanded,
    required this.onToggle,
    required this.onSelected,
    required this.firstDate,
    this.decorate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CalendarHeader(
          selectedDate: selected,
          subtitle: subtitle,
          expanded: expanded,
          onToggle: onToggle,
        ),
        AnimatedCrossFade(
          firstChild: DayStrip(
            selected: selected,
            onSelected: onSelected,
            decorate: decorate,
            firstDay: firstDate,
          ),
          secondChild: MonthCalendar(
            selected: selected,
            firstDate: firstDate,
            onSelected: (d) {
              onToggle();
              onSelected(d);
            },
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeInOutCubic,
        ),
      ],
    );
  }
}
