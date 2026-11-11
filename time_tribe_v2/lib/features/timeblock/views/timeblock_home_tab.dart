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

  /// Tạo phần state giữ dữ liệu thay đổi của trang Lịch cá nhân.
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
  // Tăng khi đổi múi giờ để lưới cuộn lại tới giờ hiện tại mới
  int _tzVersion = 0;

  /// Chạy một lần lúc trang Lịch cá nhân vừa được tạo, chuẩn bị dữ liệu ban đầu.
  @override
  void initState() {
    super.initState();
    AppTime.changes.addListener(_onTimezoneChanged);
  }

  /// Dọn controller, listener khi trang Lịch cá nhân bị đóng để không rò bộ nhớ.
  @override
  void dispose() {
    AppTime.changes.removeListener(_onTimezoneChanged);
    _gridController.dispose();
    super.dispose();
  }

  /// Đổi múi giờ thì vẽ lại lưới giờ và cuộn lại tới giờ hiện tại.
  void _onTimezoneChanged() {
    if (mounted) setState(() => _tzVersion++);
  }

  /// Hai mốc thời gian có cùng một ngày không.
  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Gom hoạt động cá nhân và hoạt động nhóm của ngày đang chọn theo bộ lọc để vẽ lên lưới.
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

  /// Giờ cần đưa vào tầm nhìn: hôm nay -> giờ hiện tại (thanh thời gian);
  /// ngày khác -> hoạt động đầu tiên (hoặc 7h).
  double _focusHour(List<_GridItem> items, DateTime day) {
    if (_same(day, AppTime.now())) {
      final now = AppTime.now();
      return now.hour + now.minute / 60;
    }
    if (items.isNotEmpty) {
      return items.map((i) => i.startMin).reduce((a, b) => a < b ? a : b) / 60;
    }
    return 7;
  }

  /// Mở màn hình thêm hoạt động, chạm vào ô giờ nào thì điền sẵn giờ đó.
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

  /// Dựng giao diện trang Lịch cá nhân.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<TimeblockViewModel>();
    final tribeVm = context.watch<TribeViewModel>();
    final now = AppTime.now();
    final today = AppTime.today();
    final items = _items(vm, tribeVm);


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
          onSelected: (d) {
            vm.changeSelectedDate(d);
            tribeVm.ensureBlocksLoaded(d);
          },
          firstDate: vm.accountCreatedAt,
          decorate: (d) {
            final count =
                vm.tasks.where((t) => _same(t.date, d)).length +
                tribeVm.tribeBlocksForMe(d).length;
            return DayDecoration(badge: count);
          },
        ),
        // Bộ lọc: Tất cả / Cá nhân / Nhóm
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
                  // Lưới tự cuộn tới giờ hiện tại ngay khi hiện ra (kể cả sau vòng xoay tải dữ liệu),
                  // và cuộn lại khi đổi ngày, đổi múi giờ hoặc khi ngày đó vừa có dữ liệu
                  focusHour: _focusHour(items, vm.selectedDate),
                  focusKey:
                      '${vm.selectedDate}|${items.isEmpty}|$_tzVersion',
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

  /// Thẻ một hoạt động cá nhân trên lưới, chạm vào để sửa (ngày đã qua thì không cho sửa).
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
