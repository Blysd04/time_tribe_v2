import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_time.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/form_widgets.dart';
import '../../timeblock/viewmodels/timeblock_viewmodel.dart';
import '../models/template_model.dart';

/// Thêm / sửa một hoạt động trong lịch mẫu. Trả về [TemplateBlockModel]
/// khi lưu, hoặc chuỗi 'delete' khi xoá.
class AddEditTemplateBlockScreen extends StatefulWidget {
  final TemplateBlockModel? block;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final int? dayIndex;

  const AddEditTemplateBlockScreen({
    super.key,
    this.block,
    this.initialStartTime,
    this.initialEndTime,
    required this.dayIndex,
  });

  /// Tạo phần state giữ dữ liệu thay đổi của màn hình thêm/sửa hoạt động trong lịch mẫu.
  @override
  State<AddEditTemplateBlockScreen> createState() =>
      _AddEditTemplateBlockScreenState();
}

class _AddEditTemplateBlockScreenState
    extends State<AddEditTemplateBlockScreen> {
  static const remindOptions = [0, 5, 10, 15, 30, 60];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _taskController;
  late final TextEditingController _descController;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late int _day;
  late String _color;
  late int _remind;

  /// Chạy một lần lúc màn hình thêm/sửa hoạt động trong lịch mẫu vừa được tạo, chuẩn bị dữ liệu ban đầu.
  @override
  void initState() {
    super.initState();
    final b = widget.block;
    _taskController = TextEditingController(text: b?.title ?? '');
    _descController = TextEditingController(text: b?.description ?? '');
    _start = b?.startTime ?? widget.initialStartTime ?? AppTime.timeOfDayNow();
    _end =
        b?.endTime ??
        widget.initialEndTime ??
        TimeOfDay(
          hour: (_start.hour + 1).clamp(0, 23),
          minute: _start.hour >= 23 ? 59 : _start.minute,
        );
    _color = b?.colorCode ?? AppColors.palette.first;
    _remind = remindOptions.contains(b?.remind) ? b!.remind : 15;
    _day = b?.dayIndex ?? widget.dayIndex ?? 1;
  }

  /// Dọn controller, listener khi màn hình thêm/sửa hoạt động trong lịch mẫu bị đóng để không rò bộ nhớ.
  @override
  void dispose() {
    _taskController.dispose();
    _descController.dispose();
    super.dispose();
  }

  /// Đổi giờ thành số phút tính từ 0 giờ.
  int _m(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Chọn giờ bắt đầu hoặc kết thúc cho hoạt động trong mẫu.
  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null || !mounted) return;
    final s = isStart ? picked : _start;
    final e = isStart ? _end : picked;
    if (_m(e) <= _m(s)) {
      AppSnack.show(
        context,
        context.l10n.errorEndBeforeStart,
        type: AppSnackType.error,
      );
      return;
    }
    setState(() => isStart ? _start = picked : _end = picked);
  }

  /// Kiểm tra form rồi trả hoạt động về màn hình lịch mẫu (chưa gọi server, bấm Lưu mẫu mới gửi).
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      TemplateBlockModel(
        id: widget.block?.id ?? const Uuid().v4(),
        templateId: widget.block?.templateId ?? '',
        dayIndex: _day,
        title: _taskController.text.trim(),
        description: _descController.text.trim(),
        startTime: _start,
        endTime: _end,
        colorCode: _color,
        remind: _remind,
      ),
    );
  }

  /// Hỏi xác nhận rồi báo màn hình lịch mẫu bỏ hoạt động này.
  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await AppDialogs.confirm(
      context,
      title: l.deleteActivityTitle,
      message: l.deleteActivityMessage(widget.block!.title),
      confirmLabel: l.delete,
      destructive: true,
    );
    if (ok && mounted) Navigator.pop(context, 'delete');
  }

  /// Dựng giao diện màn hình thêm/sửa hoạt động trong lịch mẫu.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final colors = context.read<TimeblockViewModel>().userColors;
    final isEditing = widget.block != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? l.editActivity : l.newActivity),
        actions: [
          if (isEditing)
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
                validator: (v) =>
                    v == null || v.trim().isEmpty ? l.errorNameRequired : null,
              ),
              const SizedBox(height: 16),
              FieldLabel(l.dayOfWeek),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int d = 1; d <= 7; d++)
                    AppFilterChip(
                      label: l.weekdayShort(d),
                      selected: _day == d,
                      onTap: () => setState(() => _day = d),
                    ),
                ],
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 20),
              FieldLabel(l.color),
              ColorDotPicker(
                colors: colors,
                selected: _color,
                size: 40,
                onSelected: (c) => setState(() => _color = c),
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
                    DropdownMenuItem(
                      value: m,
                      child: Text(m == 0 ? l.remindOnTime : l.remindBefore(m)),
                    ),
                ],
                onChanged: (v) => setState(() => _remind = v ?? _remind),
              ),
              const SizedBox(height: 20),
              FieldLabel(l.note),
              TextFormField(
                controller: _descController,
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
