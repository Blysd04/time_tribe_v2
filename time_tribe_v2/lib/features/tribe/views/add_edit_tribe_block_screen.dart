import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_time.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../timeblock/viewmodels/timeblock_viewmodel.dart';
import '../models/tribe_block_model.dart';
import '../models/tribe_model.dart';
import '../services/availability_calculator.dart';
import '../viewmodels/tribe_viewmodel.dart';
import 'tribe_texts.dart';
import 'widgets/tribe_block_response_buttons.dart';

/// Tạo / xem / sửa hoạt động nhóm.
/// - Trưởng & phó nhóm: sửa được, xoá được.
/// - Thành viên: chỉ xem và chọn Tham gia / Không tham gia.
/// Không có lặp lại; nhắc nhở cố định trước 1 tiếng.
class AddEditTribeBlockScreen extends StatefulWidget {
  final String tribeId;
  final TribeBlockModel? block;
  final DateTime? initialDate;
  final DateTime? initialStartUtc;
  final DateTime? initialEndUtc;

  const AddEditTribeBlockScreen({
    super.key,
    required this.tribeId,
    this.block,
    this.initialDate,
    this.initialStartUtc,
    this.initialEndUtc,
  });

  @override
  State<AddEditTribeBlockScreen> createState() =>
      _AddEditTribeBlockScreenState();
}

class _AddEditTribeBlockScreenState extends State<AddEditTribeBlockScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late String _color;
  bool _showMemberTimes = false;

  bool get _isEditing => widget.block != null;

  @override
  void initState() {
    super.initState();
    final b = widget.block;
    _title = TextEditingController(text: b?.task ?? '');
    _desc = TextEditingController(text: b?.description ?? '');
    _color =
        b?.colorCode ??
        (context
                .read<TribeViewModel>()
                .tribeById(widget.tribeId)
                ?.backgroundColor ??
            AppColors.palette.first);

    final startUtc = b?.startUtc ?? widget.initialStartUtc;
    final endUtc = b?.endUtc ?? widget.initialEndUtc;
    if (startUtc != null) {
      final s = AppTime.fromUtc(startUtc);
      _date = DateTime(s.year, s.month, s.day);
      _start = TimeOfDay(hour: s.hour, minute: s.minute);
      final e = AppTime.fromUtc(
        endUtc ?? startUtc.add(const Duration(hours: 1)),
      );
      _end = _isSameDay(e, s)
          ? TimeOfDay(hour: e.hour, minute: e.minute)
          : const TimeOfDay(hour: 23, minute: 59);
    } else {
      final now = AppTime.now();
      _date = widget.initialDate ?? DateTime(now.year, now.month, now.day);
      final nextHour = (now.hour + 1).clamp(0, 22);
      _start = TimeOfDay(hour: nextHour, minute: 0);
      _end = TimeOfDay(hour: nextHour + 1, minute: 0);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime get _startUtc => AppTime.toUtc(
    DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute),
  );
  DateTime get _endUtc => AppTime.toUtc(
    DateTime(_date.year, _date.month, _date.day, _end.hour, _end.minute),
  );

  int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pickDate() async {
    final today = AppTime.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
      currentDate: today,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        final duration = _minutes(_end) - _minutes(_start);
        _start = picked;
        // Giữ nguyên độ dài khi đổi giờ bắt đầu
        final endMin = (_minutes(picked) + (duration > 0 ? duration : 60))
            .clamp(0, 23 * 60 + 59);
        _end = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _save(TribeViewModel vm, TribeModel tribe, int busyCount) async {
    final l = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    String? error;
    if (_minutes(_end) <= _minutes(_start)) {
      error = l.errorEndBeforeStart;
    } else if (_endUtc.isBefore(DateTime.now().toUtc())) {
      error = l.errorSlotInPast;
    }
    if (error != null) {
      AppSnack.show(context, error, type: AppSnackType.error);
      return;
    }

    // COM-05: hỏi lại trước khi lưu, kèm cảnh báo trùng giờ
    final conflicts = vm.conflictsOf(
      tribe.id,
      _startUtc,
      _endUtc,
      ignoreId: widget.block?.id,
    );
    final rescheduled =
        _isEditing &&
        (widget.block!.startUtc != _startUtc ||
            widget.block!.endUtc != _endUtc);
    final ok = await AppDialogs.confirm(
      context,
      title: _isEditing ? l.saveChangesTitle : l.createActivityTitle,
      message: [
        if (conflicts.isNotEmpty)
          l.warnOverlapsWith(conflicts.map((c) => '"${c.task}"').join(', ')),
        if (busyCount > 0) l.warnMembersBusy(busyCount),
        if (rescheduled) l.warnReconfirm,
        l.everyoneWillBeNotified,
      ].join('\n\n'),
      confirmLabel: l.save,
    );
    if (!ok || !mounted) return;

    final result = _isEditing
        ? vm.updateBlock(
            widget.block!.copyWith(
              task: _title.text.trim(),
              description: _desc.text.trim(),
              startUtc: _startUtc,
              endUtc: _endUtc,
              colorCode: _color,
            ),
          )
        : vm.createBlock(
            tribeId: tribe.id,
            task: _title.text,
            description: _desc.text,
            startUtc: _startUtc,
            endUtc: _endUtc,
            colorCode: _color,
          );
    if (!mounted) return;
    if (result != TribeResult.success) {
      AppSnack.show(context, l.tribeResult(result), type: AppSnackType.error);
      return;
    }
    Navigator.pop(context);
    AppSnack.show(context, l.savedAndNotified(tribe.members.length - 1));
  }

  Future<void> _delete(TribeViewModel vm) async {
    final l = context.l10n;
    final ok = await AppDialogs.confirm(
      context,
      title: l.deleteActivityTitle,
      message: l.deleteActivityMessage(widget.block!.task),
      confirmLabel: l.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final res = vm.deleteBlock(widget.block!.id);
    Navigator.pop(context);
    res == TribeResult.success
        ? AppSnack.show(context, l.activityDeleted)
        : AppSnack.show(context, l.tribeResult(res), type: AppSnackType.error);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<TribeViewModel>();
    final personal = context.watch<TimeblockViewModel>().tasks;
    final tribe = vm.tribeById(widget.tribeId);
    final cs = Theme.of(context).colorScheme;

    final block = _isEditing ? vm.blockById(widget.block!.id) : null;
    if (tribe == null || (_isEditing && block == null)) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.errorItemGone)),
      );
    }

    final canEdit = TribePermissions.canManageBlocks(tribe.roleOf(vm.me));
    final isPast =
        block != null && block.endUtc.isBefore(DateTime.now().toUtc());
    final editable = canEdit && !isPast;

    // Ai bận trong khung giờ đang chọn
    final valid = _minutes(_end) > _minutes(_start);
    final window = valid ? TimeRange(_startUtc, _endUtc) : null;
    final busyMap = window == null
        ? <String, List<TimeRange>>{}
        : vm.busyByMember(tribe, window, myPersonalBlocks: personal);
    final busyMembers = tribe.sortedMembers
        .where((m) => (busyMap[m.userId] ?? const []).isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          !_isEditing
              ? l.newGroupActivity
              : (editable ? l.editActivity : l.activityDetails),
        ),
        actions: [
          if (_isEditing && canEdit)
            IconButton(
              tooltip: l.delete,
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () => _delete(vm),
            ),
          if (editable)
            TextButton(
              onPressed: () => _save(vm, tribe, busyMembers.length),
              child: Text(l.save),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          8,
          AppSpacing.page,
          32,
        ),
        child: Form(
          key: _formKey,
          child: Column(
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
                  Text(
                    tribe.name,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                readOnly: !editable,
                maxLength: 255,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: l.activityNameHint,
                  counterText: '',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l.errorNameRequired;
                  if (v.trim().length < 2) return l.errorNameTooShort;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              PickerTile(
                icon: Icons.calendar_today_outlined,
                label: l.date,
                value: Fmt.longDate(context, _date),
                onTap: editable ? _pickDate : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PickerTile(
                      icon: Icons.play_circle_outline,
                      label: l.start,
                      value: Fmt.tod(context, _start),
                      onTap: editable ? () => _pickTime(true) : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PickerTile(
                      icon: Icons.stop_circle_outlined,
                      label: l.end,
                      value: Fmt.tod(context, _end),
                      onTap: editable ? () => _pickTime(false) : null,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  l.timezoneNote(AppTime.formatOffset(AppTime.currentOffset)),
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (window != null)
                _AvailabilityCard(
                  tribe: tribe,
                  busyMembers: busyMembers,
                  window: window,
                  expanded: _showMemberTimes,
                  onToggle: () =>
                      setState(() => _showMemberTimes = !_showMemberTimes),
                ),
              const SizedBox(height: 20),
              FieldLabel(l.color),
              ColorDotPicker(
                colors: AppColors.palette,
                selected: _color,
                onSelected: editable ? (c) => setState(() => _color = c) : null,
              ),
              const SizedBox(height: 20),
              LockedInfoRow(
                icon: Icons.notifications_active_outlined,
                label: l.reminder,
                value: l.oneHourBefore,
              ),
              const SizedBox(height: 20),
              FieldLabel(l.note),
              TextFormField(
                controller: _desc,
                readOnly: !editable,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: editable ? l.noteHintGroup : l.noNote,
                ),
              ),
              if (block != null) ...[
                const SizedBox(height: 24),
                FieldLabel(l.areYouJoining),
                TribeBlockResponseButtons(blockId: block.id, expanded: true),
                const SizedBox(height: 20),
                _AttendanceList(
                  tribe: tribe,
                  block: block,
                  status: AttendanceStatus.accepted,
                  color: AppColors.success,
                ),
                _AttendanceList(
                  tribe: tribe,
                  block: block,
                  status: AttendanceStatus.declined,
                  color: AppColors.danger,
                ),
                _AttendanceList(
                  tribe: tribe,
                  block: block,
                  status: AttendanceStatus.pending,
                  color: Colors.grey,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ "x/y thành viên rảnh" + giờ địa phương của từng người.
class _AvailabilityCard extends StatelessWidget {
  final TribeModel tribe;
  final List<TribeMember> busyMembers;
  final TimeRange window;
  final bool expanded;
  final VoidCallback onToggle;

  const _AvailabilityCard({
    required this.tribe,
    required this.busyMembers,
    required this.window,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final me = context.read<TribeViewModel>().me;
    final total = tribe.members.length;
    final free = total - busyMembers.length;
    final allFree = busyMembers.isEmpty;
    final color = allFree
        ? AppColors.success
        : (free * 2 >= total ? AppColors.warning : AppColors.danger);

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    allFree ? Icons.event_available : Icons.event_busy,
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          allFree
                              ? l.everyoneIsFree
                              : l.membersFreeCount(free, total),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        if (!allFree)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                AvatarStack(
                                  users: busyMembers
                                      .map((m) => m.user)
                                      .toList(),
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    l.areBusy,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    expanded ? l.hide : l.eachMembersTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: [
                  for (final m in tribe.sortedMembers)
                    Builder(
                      builder: (context) {
                        final tz = m.userId == me ? null : m.user.timezone;
                        final s = AppTime.fromUtc(window.start, timezoneId: tz);
                        final e = AppTime.fromUtc(window.end, timezoneId: tz);
                        final isBusy = busyMembers.contains(m);
                        final night = s.hour < 7 || s.hour >= 23;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              UserAvatar(user: m.user, size: 26),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  m.userId == me ? l.you : m.user.nickName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (night)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.bedtime_outlined,
                                    size: 14,
                                    color: AppColors.night,
                                  ),
                                ),
                              Text(
                                '${Fmt.range(context, s, e)}${s.day != e.day ? ' (+1)' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isBusy ? l.busy : l.free,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isBusy
                                      ? AppColors.danger
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Danh sách người theo trạng thái phản hồi (avatar + tên).
class _AttendanceList extends StatelessWidget {
  final TribeModel tribe;
  final TribeBlockModel block;
  final AttendanceStatus status;
  final Color color;

  const _AttendanceList({
    required this.tribe,
    required this.block,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final me = context.read<TribeViewModel>().me;
    final ids = block.userIdsWith(status).toSet();
    // Thành viên mới vào sau khi tạo hoạt động cũng tính là "chưa phản hồi"
    if (status == AttendanceStatus.pending) {
      for (final m in tribe.members) {
        if (!block.attendance.any((a) => a.userId == m.userId)) {
          ids.add(m.userId);
        }
      }
    }
    final people = tribe.sortedMembers
        .where((m) => ids.contains(m.userId))
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                '${l.attendanceLabel(status)} (${people.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (people.isEmpty)
            Text(
              l.nobodyYet,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in people)
                  Container(
                    padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UserAvatar(user: m.user, size: 24),
                        const SizedBox(width: 6),
                        Text(
                          m.userId == me ? l.you : m.user.nickName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
