import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/app_time.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/overlap_layout.dart';
import '../../../core/widgets/calendar/calendar_header.dart';
import '../../../core/widgets/calendar/current_time_line.dart';
import '../../../core/widgets/calendar/time_grid.dart';
import '../../../core/widgets/calendar/timeblock_card.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../tribe/viewmodels/tribe_viewmodel.dart';
import '../../tribe/views/tribe_detail_screen.dart' show TribeBlockTile;
import '../models/timeblock_model.dart';
import '../viewmodels/timeblock_viewmodel.dart';
import 'add_edit_timeblock_screen.dart';

/// Trang chủ Lịch cá nhân: lịch riêng + hoạt động nhóm (đã/đang chờ xác nhận).
/// Các khối trùng giờ được chia cột để không đè lên nhau.
class TimeblockHomeTab extends StatefulWidget {
  const TimeblockHomeTab({super.key});

  @override
  State<TimeblockHomeTab> createState() => _TimeblockHomeTabState();
}

/// Một mục trên lưới: lịch cá nhân hoặc hoạt động nhóm.
class _GridItem {
  final double startMin;
  final double endMin;
  final TimeblockModel? personal;
  final LocalTribeBlock? tribe;
  _GridItem.personal(this.personal, this.startMin, this.endMin) : tribe = null;
  _GridItem.tribe(this.tribe, this.startMin, this.endMin) : personal = null;
}

class _TimeblockHomeTabState extends State<TimeblockHomeTab> {
  final _gridController = ScrollController();
  bool _pendingScroll = true;
  DateTime? _lastDate;

  @override
  void initState() {
    super.initState();
    AppTime.changes.addListener(_onTimezoneChanged);
  }

  @override
  void dispose() {
    AppTime.changes.removeListener(_onTimezoneChanged);
    _gridController.dispose();
    super.dispose();
  }

  void _onTimezoneChanged() {
    if (mounted) setState(() => _pendingScroll = true);
  }

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<_GridItem> _items(TimeblockViewModel vm, TribeViewModel tribeVm) {
    final day = vm.selectedDate;
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = DateTime(day.year, day.month, day.day + 1);
    double minutesOf(DateTime local) {
      if (!local.isAfter(dayStart)) return 0;
      if (!local.isBefore(dayEnd)) return 24 * 60;
      return local.hour * 60.0 + local.minute;
    }

    return [
      if (vm.filter != ScheduleFilter.group)
        for (final t in vm.tasks.where((t) => _same(t.date, day)))
          _GridItem.personal(
            t,
            t.startTime.hour * 60.0 + t.startTime.minute,
            (t.endTime.hour * 60.0 + t.endTime.minute) <=
                    (t.startTime.hour * 60.0 + t.startTime.minute)
                ? 24 * 60
                : t.endTime.hour * 60.0 + t.endTime.minute,
          ),
      if (vm.filter != ScheduleFilter.personal)
        for (final b in tribeVm.tribeBlocksForMe(day))
          _GridItem.tribe(b, minutesOf(b.localStart), minutesOf(b.localEnd)),
    ];
  }

  /// Hôm nay -> giờ hiện tại; ngày khác -> mục đầu tiên (hoặc 7h).
  void _scrollToFocus(List<_GridItem> items, DateTime day) {
    double hour = 7;
    if (_same(day, AppTime.now())) {
      final now = AppTime.now();
      hour = now.hour + now.minute / 60;
    } else if (items.isNotEmpty) {
      hour = items.map((i) => i.startMin).reduce((a, b) => a < b ? a : b) / 60;
    }
    TimeGrid.scrollToHour(_gridController, hour);
  }

  void _openAdd(DateTime date, {int? hour}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTimeblockScreen(
          initialDate: date,
          initialStart: hour == null ? null : TimeOfDay(hour: hour, minute: 0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<TimeblockViewModel>();
    final tribeVm = context.watch<TribeViewModel>();
    final now = AppTime.now();
    final today = AppTime.today();
    final items = _items(vm, tribeVm);

    if (_lastDate == null || !_same(_lastDate!, vm.selectedDate)) {
      _lastDate = vm.selectedDate;
      _pendingScroll = true;
    }
    if (_pendingScroll && !vm.isLoading) {
      _pendingScroll = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToFocus(items, vm.selectedDate);
      });
    }

    final slots = OverlapLayout.compute([
      for (final i in items) (i.startMin, i.endMin),
    ]);
    final isPastDay = DateTime(
      vm.selectedDate.year,
      vm.selectedDate.month,
      vm.selectedDate.day,
    ).isBefore(today);

    return Column(
      children: [
        CalendarPanel(
          selected: vm.selectedDate,
          subtitle: l.itemsTodaySubtitle(items.length, Fmt.date(context, now)),
          expanded: vm.isCalendarExpanded,
          onToggle: vm.toggleCalendar,
          onSelected: vm.changeSelectedDate,
          firstDate: vm.accountCreatedAt,
          decorate: (d) {
            final count =
                vm.tasks.where((t) => _same(t.date, d)).length +
                tribeVm.tribeBlocksForMe(d).length;
            return DayDecoration(badge: count);
          },
        ),
        // BỘ LỌC: Tất cả / Cá nhân / Nhóm
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            children: [
              for (final (f, label, icon) in [
                (ScheduleFilter.all, l.filterAll, Icons.view_agenda_outlined),
                (
                  ScheduleFilter.personal,
                  l.filterPersonal,
                  Icons.person_outline,
                ),
                (ScheduleFilter.group, l.filterGroup, Icons.groups_outlined),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppFilterChip(
                    label: label,
                    icon: icon,
                    selected: vm.filter == f,
                    onTap: () => vm.setFilter(f),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TimeGrid(
                  controller: _gridController,
                  onTapHour: isPastDay || vm.filter == ScheduleFilter.group
                      ? null
                      : (h) => _openAdd(vm.selectedDate, hour: h),
                  layersBuilder: (width) => [
                    for (int i = 0; i < items.length; i++)
                      gridBlock(
                        startMinute: items[i].startMin,
                        endMinute: items[i].endMin,
                        left: TimeGrid.labelWidth,
                        width: width,
                        column: slots[i].column,
                        columns: slots[i].columns,
                        child: items[i].personal != null
                            ? _personalCard(items[i].personal!, isPastDay)
                            : TribeBlockTile(
                                block: items[i].tribe!.block,
                                myStatus: items[i].tribe!.myStatus,
                                caption: items[i].tribe!.tribe.name,
                                timeLabel: Fmt.range(
                                  context,
                                  items[i].tribe!.localStart,
                                  items[i].tribe!.localEnd,
                                ),
                              ),
                      ),
                    if (_same(vm.selectedDate, now)) const CurrentTimeLine(),
                    if (items.isEmpty)
                      Positioned(
                        top: TimeGrid.yOfMinutes(
                          (_same(vm.selectedDate, now) ? now.hour : 7) * 60.0 +
                              10,
                        ),
                        left: TimeGrid.labelWidth,
                        right: TimeGrid.rightPadding,
                        child: IgnorePointer(
                          child: Text(
                            vm.filter == ScheduleFilter.group
                                ? l.noGroupActivitiesDay
                                : l.emptyDayHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _personalCard(TimeblockModel t, bool isPastDay) {
    return TimeblockCard(
      title: t.task,
      timeLabel: Fmt.todRange(context, t.startTime, t.endTime),
      color: t.flutterColor,
      dimmed: isPastDay,
      done: isPastDay,
      onTap: isPastDay
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditTimeblockScreen(timeblock: t),
              ),
            ),
    );
  }
}
