import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_time.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/form_widgets.dart';
import '../models/timeblock_model.dart';
import '../viewmodels/timeblock_viewmodel.dart';
import 'widgets/duplicate_dates_sheet.dart';

/// Thêm / sửa lịch cá nhân. Thay cho "Lặp lại", người dùng tự chọn các ngày
/// muốn nhân bản trên lịch tháng.
class AddEditTimeblockScreen extends StatefulWidget {
  final TimeblockModel? timeblock; // null -> Thêm mới
  final DateTime? initialDate;
  final TimeOfDay? initialStart;

  const AddEditTimeblockScreen({
    super.key,
    this.timeblock,
    this.initialDate,
    this.initialStart,
  });

  @override
  State<AddEditTimeblockScreen> createState() => _AddEditTimeblockScreenState();
}

class _AddEditTimeblockScreenState extends State<AddEditTimeblockScreen> {
  static const remindOptions = [0, 5, 10, 15, 30, 60];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _taskController;
  late final TextEditingController _descController;
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late String _color;
  late int _remind;
  Set<DateTime> _duplicateDates = {};

  bool get _isEditing => widget.timeblock != null;

  @override
  void initState() {
    super.initState();
    final b = widget.timeblock;
    _taskController = TextEditingController(text: b?.task ?? '');
    _descController = TextEditingController(text: b?.description ?? '');
    final d = b?.date ?? widget.initialDate ?? AppTime.today();
    _date = DateTime(d.year, d.month, d.day);
    _start = b?.startTime ?? widget.initialStart ?? AppTime.timeOfDayNow();
    _end =
        b?.endTime ??
        TimeOfDay(
          hour: (_start.hour + 1).clamp(0, 23),
          minute: _start.hour >= 23 ? 59 : _start.minute,
        );
    _color = b?.colorCode ?? '';
    _remind = remindOptions.contains(b?.remind) ? b!.remind : 15;
  }

  @override
  void dispose() {
    _taskController.dispose();
    _descController.dispose();
    super.dispose();
  }

  int _m(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pickTime(bool isStart) async {
    final l = context.l10n;
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    final s = isStart ? picked : _start;
    final e = isStart ? _end : picked;
    if (_m(e) <= _m(s)) {
      if (!mounted) return;
      AppSnack.show(context, l.errorEndBeforeStart, type: AppSnackType.error);
      return;
    }
    if (_m(e) - _m(s) < 5) {
      if (!mounted) return;
      AppSnack.show(context, l.errorMinDuration, type: AppSnackType.error);
      return;
    }
    setState(() {
      isStart ? _start = picked : _end = picked;
      // Đổi giờ -> bỏ các ngày nhân bản giờ bị trùng
      final vm = context.read<TimeblockViewModel>();
      _duplicateDates.removeWhere((d) => vm.conflictsOn(d, _start, _end));
    });
  }

  Future<void> _pickDate() async {
    final vm = context.read<TimeblockViewModel>();
    final today = AppTime.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: DateTime(today.year + 10),
      currentDate: today,
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _duplicateDates.removeWhere((d) => d == picked);
        _duplicateDates.removeWhere((d) => vm.conflictsOn(d, _start, _end));
      });
    }
  }

  Future<void> _pickDuplicateDates() async {
    final vm = context.read<TimeblockViewModel>();
    final result = await showDuplicateDatesSheet(
      context,
      initial: _duplicateDates,
      blockedReason: (day) {
        if (day == _date) return DuplicateBlockReason.sameDay;
        if (vm.conflictsOn(day, _start, _end)) {
          return DuplicateBlockReason.conflict;
        }
        return null;
      },
    );
    if (result != null) setState(() => _duplicateDates = result);
  }

  void _save() {
    final l = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    if (_date.isBefore(AppTime.today())) {
      AppSnack.show(context, l.errorPastDate, type: AppSnackType.error);
      return;
    }
    final vm = context.read<TimeblockViewModel>();
    if (_color.isEmpty) _color = vm.userColors.first;

    final block = TimeblockModel(
      id: widget.timeblock?.id ?? const Uuid().v4(),
      userId: widget.timeblock?.userId ?? 'current-user-id',
      task: _taskController.text.trim(),
      description: _descController.text.trim(),
      date: _date,
      startTime: _start,
      endTime: _end,
      colorCode: _color,
      remind: _remind,
    );
    if (vm.isOverlapping(block)) {
      AppSnack.show(context, l.errorOverlap, type: AppSnackType.error);
      return;
    }
    _isEditing ? vm.updateTimeblock(block) : vm.addTimeblock(block);

    // Nhân bản sang các ngày đã chọn (bỏ qua ngày vừa bị trùng)
    final copies = <TimeblockModel>[
      for (final d in _duplicateDates.toList()..sort())
        if (!vm.conflictsOn(d, _start, _end))
          TimeblockModel(
            id: const Uuid().v4(),
            userId: block.userId,
            parentBlockId: block.id, // liên kết về lịch gốc
            task: block.task,
            description: block.description,
            date: d,
            startTime: _start,
            endTime: _end,
            colorCode: _color,
            remind: _remind,
          ),
    ];
    if (copies.isNotEmpty) vm.addTimeblocks(copies);
    // TODO(backend): POST /timeblocks (+ /timeblocks/batch cho các bản nhân)

    Navigator.pop(context);
    AppSnack.show(
      context,
      copies.isEmpty ? l.saved : l.savedWithCopies(copies.length),
    );
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await AppDialogs.confirm(
      context,
      title: l.deleteActivityTitle,
      message: l.deleteActivityMessage(widget.timeblock!.task),
      confirmLabel: l.delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    context.read<TimeblockViewModel>().deleteTimeblock(widget.timeblock!.id);
    Navigator.pop(context);
    AppSnack.show(context, l.activityDeleted);
  }

  void _editColorSlot(int index, String currentHex, TimeblockViewModel vm) {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.pickNewColor),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: AppColors.fromHex(currentHex),
            onColorChanged: (color) {
              final hex =
                  '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
              Navigator.pop(ctx);
              if (vm.isColorDuplicate(hex, index)) {
                AppSnack.show(
                  context,
                  l.errorColorDuplicate,
                  type: AppSnackType.error,
                );
              } else {
                vm.updateUserColor(index, hex);
                setState(() => _color = hex);
              }
            },
          ),
        ),
      ),
    );
  }

  String _remindLabel(int m) =>
      m == 0 ? context.l10n.remindOnTime : context.l10n.remindBefore(m);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<TimeblockViewModel>();
    final cs = Theme.of(context).colorScheme;
    if (_color.isEmpty) _color = vm.userColors.first;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEditing ? l.editActivity : l.newActivity),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: l.delete,
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _delete,
            ),
          TextButton(onPressed: _save, child: Text(l.save)),
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
              TextFormField(
                controller: _taskController,
                maxLength: 100,
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
                onTap: _pickDate,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PickerTile(
                      icon: Icons.play_circle_outline,
                      label: l.start,
                      value: Fmt.tod(context, _start),
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PickerTile(
                      icon: Icons.stop_circle_outlined,
                      label: l.end,
                      value: Fmt.tod(context, _end),
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PickerTile(
                icon: Icons.copy_all_outlined,
                label: l.duplicateToOtherDays,
                value: _duplicateDates.isEmpty
                    ? l.duplicateNone
                    : (_duplicateDates.toList()..sort())
                          .map((d) => Fmt.dayMonth(context, d))
                          .join(', '),
                trailing: Icon(
                  Icons.chevron_right,
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
                onTap: _pickDuplicateDates,
              ),
              const SizedBox(height: 20),
              FieldLabel(l.color, hint: l.colorLongPressHint),
              ColorDotPicker(
                colors: vm.userColors,
                selected: _color,
                size: 40,
                onSelected: (c) => setState(() => _color = c),
                onLongPress: (i, hex) => _editColorSlot(i, hex, vm),
              ),
              const SizedBox(height: 20),
              FieldLabel(l.reminder),
              DropdownButtonFormField<int>(
                initialValue: _remind,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.notifications_active_outlined),
                ),
                items: [
                  for (final m in remindOptions)
                    DropdownMenuItem(value: m, child: Text(_remindLabel(m))),
                ],
                onChanged: (v) => setState(() => _remind = v ?? _remind),
              ),
              const SizedBox(height: 20),
              FieldLabel(l.note),
              TextFormField(
                controller: _descController,
                maxLength: 300,
                maxLines: 3,
                decoration: InputDecoration(hintText: l.noteHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
