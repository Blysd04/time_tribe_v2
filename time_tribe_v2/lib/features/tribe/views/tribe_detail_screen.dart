import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_time.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/overlap_layout.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/calendar/calendar_header.dart';
import '../../../core/widgets/calendar/current_time_line.dart';
import '../../../core/widgets/calendar/time_grid.dart';
import '../../../core/widgets/calendar/timeblock_card.dart';
import '../../timeblock/models/timeblock_model.dart';
import '../../timeblock/viewmodels/timeblock_viewmodel.dart';
import '../models/tribe_block_model.dart';
import '../models/tribe_model.dart';
import '../services/availability_calculator.dart';
import '../viewmodels/tribe_viewmodel.dart';
import 'add_edit_tribe_block_screen.dart';
import 'tribe_members_drawer.dart';
import 'widgets/hatch_painter.dart';
import 'widgets/tribe_block_sheet.dart';

/// COM-08: lịch chung của nhóm.
///
/// - Cột trái "Lịch thành viên": khung xám = có người bận (hiện ai bận),
///   càng nhiều người bận càng đậm. Bật "Giờ rảnh chung" để chỉ thấy các
///   khung xanh lá mà tất cả đều rảnh.
/// - Cột phải "Hoạt động nhóm": các tribe_block (trùng giờ thì chia cột).
/// - Mọi mốc giờ được quy đổi về múi giờ trong Profile của người xem.
class TribeDetailScreen extends StatefulWidget {
  final String tribeId;
  const TribeDetailScreen({super.key, required this.tribeId});

  /// Tạo phần state giữ dữ liệu thay đổi của trang lịch nhóm.
  @override
  State<TribeDetailScreen> createState() => _TribeDetailScreenState();
}

class _TribeDetailScreenState extends State<TribeDetailScreen> {
  /// Tỉ lệ độ rộng cột "Lịch thành viên".
  static const double _busyLaneRatio = 0.46;

  final _gridController = ScrollController();
  late DateTime _selectedDate = AppTime.today();
  bool _calendarExpanded = false;
  bool _onlyFree = false;
  bool _closing = false;

  /// Chạy một lần lúc trang lịch nhóm vừa được tạo, chuẩn bị dữ liệu ban đầu.
  @override
  void initState() {
    super.initState();
    AppTime.changes.addListener(_onTimezoneChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollGridToFocus();
      _loadAround(_selectedDate);
    });
  }

  /// Tải giờ bận của thành viên và hoạt động nhóm quanh ngày đang xem (đã có thì bỏ qua).
  void _loadAround(DateTime date) {
    final vm = context.read<TribeViewModel>();
    vm.ensureBusyLoaded(widget.tribeId, date);
    vm.ensureBlocksLoaded(date);
  }

  /// Dọn controller, listener khi trang lịch nhóm bị đóng để không rò bộ nhớ.
  @override
  void dispose() {
    AppTime.changes.removeListener(_onTimezoneChanged);
    _gridController.dispose();
    super.dispose();
  }

  /// Đổi múi giờ thì vẽ lại và cuộn lưới về giờ phù hợp.
  void _onTimezoneChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollGridToFocus());
  }

  /// Hai mốc thời gian có cùng một ngày không.
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Chọn ngày khác trên thanh ngày.
  void _selectDate(DateTime date) {
    setState(() => _selectedDate = DateTime(date.year, date.month, date.day));
    _loadAround(_selectedDate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollGridToFocus());
  }

  /// Giờ cần đưa vào tầm nhìn: hôm nay -> giờ hiện tại (thanh thời gian);
  /// ngày khác -> hoạt động đầu tiên (hoặc 7h).
  double _focusHour(TribeViewModel vm) {
    if (_isSameDay(_selectedDate, AppTime.now())) {
      final now = AppTime.now();
      return now.hour + now.minute / 60;
    }
    final blocks = vm.blocksInWindow(
      widget.tribeId,
      TribeViewModel.dayWindow(_selectedDate),
    );
    if (blocks.isNotEmpty) {
      final local = AppTime.fromUtc(blocks.first.startUtc);
      return _isSameDay(local, _selectedDate)
          ? local.hour + local.minute / 60
          : 0;
    }
    return 7;
  }

  /// Cuộn lưới tới giờ cần xem (dùng khi đổi ngày, đổi múi giờ).
  void _scrollGridToFocus() {
    if (!mounted) return;
    TimeGrid.scrollToHour(
      _gridController,
      _focusHour(context.read<TribeViewModel>()),
    );
  }

  /// Phút tính từ 00:00 của ngày đang xem (theo giờ người xem).
  double _minuteOf(DateTime utc, TimeRange day) {
    if (!utc.isAfter(day.start)) return 0;
    if (!utc.isBefore(day.end)) return 24 * 60;
    final local = AppTime.fromUtc(utc);
    return local.hour * 60.0 + local.minute;
  }

  /// Chữ khoảng giờ "08:00 - 09:00" đã đổi sang giờ người xem.
  String _range(DateTime startUtc, DateTime endUtc) =>
      Fmt.range(context, AppTime.fromUtc(startUtc), AppTime.fromUtc(endUtc));

  /// Mở màn hình tạo hoạt động nhóm, có thể điền sẵn giờ bắt đầu và kết thúc.
  void _openAddBlock({DateTime? startUtc, DateTime? endUtc}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTribeBlockScreen(
          tribeId: widget.tribeId,
          initialDate: _selectedDate,
          initialStartUtc: startUtc,
          initialEndUtc: endUtc,
        ),
      ),
    );
  }

  /// Gợi ý khung tạo hoạt động: tối đa 1 tiếng trong khoảng [range].
  void _openAddInRange(TimeRange range) {
    final now = DateTime.now().toUtc();
    final start = range.start.isBefore(now) ? null : range.start;
    final oneHour = (start ?? range.start).add(const Duration(hours: 1));
    _openAddBlock(
      startUtc: start,
      endUtc: start == null
          ? null
          : (oneHour.isBefore(range.end) ? oneHour : range.end),
    );
  }

  /// Dựng giao diện trang lịch nhóm.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<TribeViewModel>();
    final personal = context.watch<TimeblockViewModel>().tasks;
    final tribe = vm.tribeById(widget.tribeId);
    final cs = Theme.of(context).colorScheme;

    // Nhóm đã bị giải tán / mình đã rời -> đóng trang
    if (tribe == null) {
      if (!_closing) {
        _closing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final route = ModalRoute.of(context);
          if (mounted && route != null && route.isActive) {
            Navigator.of(context).removeRoute(route);
          }
        });
      }
      return const Scaffold();
    }

    final canManage = TribePermissions.canManageBlocks(tribe.roleOf(vm.me));
    final day = TribeViewModel.dayWindow(_selectedDate);
    final busy = vm.busyByMember(tribe, day, myPersonalBlocks: personal);
    final dayBlocks = vm.blocksInWindow(tribe.id, day);
    final memberById = {for (final m in tribe.members) m.userId: m};
    final nowUtc = DateTime.now().toUtc();

    return Scaffold(
      endDrawer: TribeMembersDrawer(tribeId: tribe.id),
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tribe.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              l.tribeSubtitle(
                tribe.members.length,
                AppTime.formatOffset(AppTime.currentOffset),
              ),
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              tooltip: l.members,
              icon: const Icon(Icons.people_alt_outlined),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              tooltip: l.createGroupActivity,
              onPressed: () => _openAddBlock(),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          CalendarPanel(
            selected: _selectedDate,
            subtitle: l.groupActivitiesToday(
              dayBlocks.length,
              Fmt.date(context, AppTime.now()),
            ),
            expanded: _calendarExpanded,
            onToggle: () =>
                setState(() => _calendarExpanded = !_calendarExpanded),
            onSelected: _selectDate,
            firstDate: DateTime(AppTime.now().year - 1),
            decorate: (d) => _decorateDay(vm, tribe, personal, d),
          ),
          _buildLegendAndFilter(cs),
          const Divider(height: 1),
          _buildLaneHeader(cs),
          Expanded(
            child: TimeGrid(
              controller: _gridController,
              // Lưới tự cuộn tới giờ hiện tại ngay khi trang mở ra
              focusHour: _focusHour(vm),
              focusKey: _selectedDate,
              onTapHour: canManage
                  ? (h) {
                      final start = AppTime.toUtc(
                        DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          h,
                        ),
                      );
                      _openAddBlock(
                        startUtc: start,
                        endUtc: start.add(const Duration(hours: 1)),
                      );
                    }
                  : null,
              layersBuilder: (width) {
                final busyLane = width * _busyLaneRatio;
                final blockLeft = TimeGrid.labelWidth + busyLane + 6;
                final blockWidth = width - busyLane - 6;
                final segments = AvailabilityCalculator.segments(day, busy);
                final freeSlots = AvailabilityCalculator.commonFreeSlots(
                  day,
                  busy,
                ).where((s) => s.end.isAfter(nowUtc)).toList();
                final blockSlots = OverlapLayout.compute([
                  for (final b in dayBlocks)
                    (_minuteOf(b.startUtc, day), _minuteOf(b.endUtc, day)),
                ]);

                return [
                  // Cột trái: lịch thành viên
                  if (!_onlyFree)
                    for (final s in segments.where(
                      (s) => s.busyUserIds.isNotEmpty,
                    ))
                      gridBlock(
                        startMinute: _minuteOf(s.range.start, day),
                        endMinute: _minuteOf(s.range.end, day),
                        left: TimeGrid.labelWidth,
                        width: busyLane,
                        minHeight: 14,
                        child: _BusySegmentCard(
                          busyUsers: [
                            for (final id in s.busyUserIds)
                              if (memberById[id] != null) memberById[id]!.user,
                          ],
                          total: tribe.members.length,
                          timeLabel: _range(s.range.start, s.range.end),
                          onTap: () => _showSegmentSheet(tribe, s),
                        ),
                      )
                  else
                    for (final slot in freeSlots)
                      gridBlock(
                        startMinute: _minuteOf(slot.start, day),
                        endMinute: _minuteOf(slot.end, day),
                        left: TimeGrid.labelWidth,
                        width: busyLane,
                        child: _FreeSlotCard(
                          timeLabel: _range(slot.start, slot.end),
                          canCreate: canManage,
                          onTap: () => canManage
                              ? _openAddInRange(slot)
                              : _showSegmentSheet(
                                  tribe,
                                  AvailabilitySegment(slot, {}),
                                ),
                        ),
                      ),

                  // Cột phải: hoạt động nhóm
                  for (int i = 0; i < dayBlocks.length; i++)
                    gridBlock(
                      startMinute: _minuteOf(dayBlocks[i].startUtc, day),
                      endMinute: _minuteOf(dayBlocks[i].endUtc, day),
                      left: blockLeft,
                      width: blockWidth,
                      column: blockSlots[i].column,
                      columns: blockSlots[i].columns,
                      child: TribeBlockTile(
                        block: dayBlocks[i],
                        myStatus: dayBlocks[i].statusOf(vm.me),
                        timeLabel: _range(
                          dayBlocks[i].startUtc,
                          dayBlocks[i].endUtc,
                        ),
                      ),
                    ),

                  if (_isSameDay(_selectedDate, AppTime.now()))
                    const CurrentTimeLine(),

                  if (_onlyFree && freeSlots.isEmpty)
                    Positioned(
                      top: 12,
                      left: TimeGrid.labelWidth,
                      width: busyLane,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          l.noCommonFreeTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                ];
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Màu ô ngày theo số thành viên bận trong khung 7h-22h (giờ người xem).
  DayDecoration _decorateDay(
    TribeViewModel vm,
    TribeModel tribe,
    List<TimeblockModel> personal,
    DateTime d,
  ) {
    final window = TimeRange(
      AppTime.toUtc(DateTime(d.year, d.month, d.day, 7)),
      AppTime.toUtc(DateTime(d.year, d.month, d.day, 22)),
    );
    final busy = vm.busyByMember(tribe, window, myPersonalBlocks: personal);
    final load = AvailabilityCalculator.dayLoad(
      AvailabilityCalculator.busyMemberShare(
        window,
        tribe.members.map((m) => m.userId).toList(),
        busy,
      ),
    );
    return DayDecoration(
      statusColor: switch (load) {
        DayLoad.free => AppColors.success,
        DayLoad.half => AppColors.warning,
        DayLoad.busy => AppColors.danger,
        DayLoad.neutral => Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.35),
      },
      badge: vm.blocksInWindow(tribe.id, TribeViewModel.dayWindow(d)).length,
    );
  }

  /// Dòng chú thích màu Rảnh / Nửa bận / Bận và nút lọc giờ rảnh chung.
  Widget _buildLegendAndFilter(ColorScheme cs) {
    final l = context.l10n;
    Widget dot(Color c, String label) => Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  dot(AppColors.success, l.legendFree),
                  dot(AppColors.warning, l.legendHalf),
                  dot(AppColors.danger, l.legendBusy),
                ],
              ),
            ),
          ),
          FilterChip(
            selected: _onlyFree,
            showCheckmark: false,
            avatar: Icon(
              Icons.event_available,
              size: 16,
              color: _onlyFree ? Colors.white : AppColors.success,
            ),
            label: Text(
              l.commonFreeTime,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _onlyFree ? Colors.white : cs.onSurface,
              ),
            ),
            selectedColor: AppColors.success,
            backgroundColor: cs.surface,
            side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            visualDensity: VisualDensity.compact,
            onSelected: (v) => setState(() => _onlyFree = v),
          ),
        ],
      ),
    );
  }

  /// Tiêu đề hai cột: Lịch thành viên và Hoạt động nhóm.
  Widget _buildLaneHeader(ColorScheme cs) {
    final l = context.l10n;
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: cs.onSurface.withValues(alpha: 0.45),
      letterSpacing: 0.3,
    );
    return LayoutBuilder(
      builder: (context, c) {
        final available =
            c.maxWidth - TimeGrid.labelWidth - TimeGrid.rightPadding;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const SizedBox(width: TimeGrid.labelWidth),
              SizedBox(
                width: available * _busyLaneRatio,
                child: Text(
                  (_onlyFree ? l.commonFreeTime : l.membersSchedule)
                      .toUpperCase(),
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.groupActivities.toUpperCase(),
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Chi tiết 1 khung giờ: ai bận, ai rảnh, giờ địa phương của từng người.
  void _showSegmentSheet(TribeModel tribe, AvailabilitySegment segment) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final me = context.read<TribeViewModel>().me;
    final busy = tribe.sortedMembers
        .where((m) => segment.busyUserIds.contains(m.userId))
        .toList();
    final free = tribe.sortedMembers
        .where((m) => !segment.busyUserIds.contains(m.userId))
        .toList();
    final canManage = TribePermissions.canManageBlocks(tribe.roleOf(me));

    Widget row(TribeMember m, bool isBusy) {
      final tzId = m.userId == me ? null : m.user.timezone;
      final s = AppTime.fromUtc(segment.range.start, timezoneId: tzId);
      final e = AppTime.fromUtc(segment.range.end, timezoneId: tzId);
      final night = s.hour < 7 || s.hour >= 23;
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: UserAvatar(user: m.user, size: 34),
        title: Text(
          m.userId == me ? l.you : m.user.nickName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${l.theirTime}: ${Fmt.range(context, s, e)}${tzId == null ? '' : ' (${AppTime.offsetLabelOf(tzId)})'}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (night)
              const Icon(
                Icons.bedtime_outlined,
                size: 16,
                color: AppColors.night,
              ),
            const SizedBox(width: 6),
            Text(
              isBusy ? l.busy : l.free,
              style: TextStyle(
                color: isBusy ? AppColors.danger : AppColors.success,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            children: [
              Text(
                _range(segment.range.start, segment.range.end),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                busy.isEmpty
                    ? l.everyoneFree(tribe.members.length)
                    : l.someBusy(busy.length, tribe.members.length),
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              for (final m in busy) row(m, true),
              for (final m in free) row(m, false),
              if (canManage &&
                  segment.range.end.isAfter(DateTime.now().toUtc()))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(l.createInThisSlot),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openAddInRange(segment.range);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ hoạt động nhóm trên lưới (dùng ở lịch nhóm). Bấm -> sheet xác nhận nhanh.
class TribeBlockTile extends StatelessWidget {
  final TribeBlockModel block;
  final AttendanceStatus myStatus;
  final String timeLabel;
  final String? caption;

  const TribeBlockTile({
    super.key,
    required this.block,
    required this.myStatus,
    required this.timeLabel,
    this.caption,
  });

  /// Dựng giao diện ô hoạt động nhóm trên lưới giờ.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final accepted = block.userIdsWith(AttendanceStatus.accepted).length;
    final declined = block.userIdsWith(AttendanceStatus.declined).length;
    final pending = block.attendance.length - accepted - declined;
    final isPast = block.endUtc.isBefore(DateTime.now().toUtc());
    // Làm mờ giống lịch cá nhân: chỉ khi hoạt động thuộc ngày đã qua (theo múi giờ đang dùng)
    final isPastDay = !block.endUtc.isAfter(AppTime.toUtc(AppTime.today()));

    return TimeblockCard(
      title: block.task,
      timeLabel: timeLabel,
      caption: caption,
      color: block.flutterColor,
      icon: Icons.groups_rounded,
      // Mình chưa xác nhận -> viền nét; mình không tham gia / đã qua -> mờ
      outlined: myStatus == AttendanceStatus.pending && !isPast,
      dimmed: isPastDay || myStatus == AttendanceStatus.declined,
      done: isPastDay && myStatus == AttendanceStatus.accepted,
      footer: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check),
          Text(' $accepted  '),
          const Icon(Icons.close),
          Text(' $declined  '),
          if (pending > 0) ...[const Icon(Icons.schedule), Text(' $pending')],
        ],
      ),
      badge: myStatus == AttendanceStatus.pending && !isPast
          ? CardBadge(
              l.waitingForYou,
              color: block.flutterColor,
              inverted: true,
            )
          : null,
      onTap: () => showTribeBlockSheet(context, block.id),
    );
  }
}

/// Khối xám: có người bận. Càng nhiều người bận càng đậm.
class _BusySegmentCard extends StatelessWidget {
  final List<AppUser> busyUsers;
  final int total;
  final String timeLabel;
  final VoidCallback onTap;

  const _BusySegmentCard({
    required this.busyUsers,
    required this.total,
    required this.timeLabel,
    required this.onTap,
  });

  /// Dựng giao diện ô giờ bận của thành viên.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final ratio = total == 0 ? 0.0 : busyUsers.length / total;
    final everyone = busyUsers.length == total;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          painter: HatchPainter(
            color: onSurface.withValues(alpha: 0.05 + 0.10 * ratio),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: (everyone ? AppColors.danger : onSurface).withValues(
                alpha: everyone ? 0.10 : 0.04 + 0.10 * ratio,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: onSurface.withValues(alpha: 0.08)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: LayoutBuilder(
              builder: (context, c) {
                if (c.maxHeight < 22) return const SizedBox.shrink();
                return ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    maxHeight: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AvatarStack(users: busyUsers, size: 18),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                l.busyCount(busyUsers.length, total),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (c.maxHeight >= 44)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              timeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Khối xanh lá: tất cả mọi người đều rảnh.
class _FreeSlotCard extends StatelessWidget {
  final String timeLabel;
  final bool canCreate;
  final VoidCallback onTap;

  const _FreeSlotCard({
    required this.timeLabel,
    required this.canCreate,
    required this.onTap,
  });

  /// Dựng giao diện ô giờ rảnh chung.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.6)),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            if (c.maxHeight < 20) return const SizedBox.shrink();
            return ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxHeight: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 13,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            timeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (c.maxHeight >= 42)
                      Text(
                        canCreate ? l.freeSlotTapToCreate : l.everyoneIsFree,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.success,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
