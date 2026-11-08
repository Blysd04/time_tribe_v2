import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/api_errors.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/session/session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/overlap_layout.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/calendar/time_grid.dart';
import '../../../core/widgets/calendar/timeblock_card.dart';
import '../models/template_model.dart';
import '../viewmodels/template_viewmodel.dart';
import 'add_edit_template_block_screen.dart';

/// Xem / sửa một lịch mẫu theo tuần (Thứ Hai -> Chủ Nhật).
/// Thoát ngang khi đang sửa sẽ được lưu nháp tự động.
class TemplateDetailScreen extends StatefulWidget {
  final TemplateModel? template; // null = tạo mới
  final bool isEditMode;

  const TemplateDetailScreen({
    super.key,
    this.template,
    this.isEditMode = false,
  });

  /// Tạo phần state giữ dữ liệu thay đổi của màn hình chi tiết lịch mẫu.
  @override
  State<TemplateDetailScreen> createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  late List<TemplateBlockModel> _blocks;
  late final TextEditingController _nameController;
  final _gridController = ScrollController();
  int _day = 1;
  bool _savedOfficially = false;
  bool _saving = false;

  /// Chạy một lần lúc màn hình chi tiết lịch mẫu vừa được tạo, chuẩn bị dữ liệu ban đầu.
  @override
  void initState() {
    super.initState();
    final vm = context.read<TemplateViewModel>();
    final source = widget.template ?? vm.draftTemplate;
    _blocks = source?.blocks.toList() ?? [];
    _nameController = TextEditingController(text: source?.templateName ?? '');
    final days = _blocks.map((b) => b.dayIndex).toList()..sort();
    if (days.isNotEmpty) _day = days.first;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFirst());
  }

  /// Dọn controller, listener khi màn hình chi tiết lịch mẫu bị đóng để không rò bộ nhớ.
  @override
  void dispose() {
    _nameController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  /// Cuộn lưới giờ tới hoạt động sớm nhất của thứ đang xem.
  void _scrollToFirst() {
    final dayBlocks = _blocks.where((b) => b.dayIndex == _day).toList();
    final hour = dayBlocks.isEmpty
        ? 7.0
        : dayBlocks
              .map((b) => b.startTime.hour + b.startTime.minute / 60)
              .reduce((a, b) => a < b ? a : b);
    TimeGrid.scrollToHour(_gridController, hour);
  }

  /// Bấm Lưu: gửi tên và toàn bộ khối lên server. Mẫu mới thì tạo, mẫu cũ thì ghi đè.
  Future<void> _saveOfficial() async {
    final l = context.l10n;
    if (_saving) return;
    if (_nameController.text.trim().isEmpty) {
      AppSnack.show(
        context,
        l.errorTemplateNameEmpty,
        type: AppSnackType.error,
      );
      return;
    }
    setState(() => _saving = true);
    final err = await context.read<TemplateViewModel>().saveTemplate(
      TemplateModel(
        id: widget.template?.id ?? '',
        userId: widget.template?.userId ?? Session.currentUserId,
        templateName: _nameController.text.trim(),
        blocks: _blocks,
      ),
      isNew: widget.template == null,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      final msg = err == 'limit_exceeded'
          ? l.errorTemplateLimit(TemplateLimits.maxTemplates)
          : l.apiError(err);
      AppSnack.show(context, msg, type: AppSnackType.error);
      return;
    }
    _savedOfficially = true; // Đã lưu thật thì không lưu nháp khi đóng trang
    Navigator.pop(context);
    AppSnack.show(context, l.saved);
  }

  /// Thoát trang khi chưa bấm Lưu thì giữ lại bản nháp trên máy.
  void _autoDraft() {
    if (!widget.isEditMode || _savedOfficially) return;
    context.read<TemplateViewModel>().saveDraft(
      TemplateModel(
        id: widget.template?.id ?? 'draft_id',
        userId: Session.currentUserId,
        templateName: _nameController.text.trim(),
        blocks: _blocks,
      ),
    );
  }

  /// Mở màn hình thêm/sửa một hoạt động trong mẫu, xong thì cập nhật danh sách khối.
  Future<void> _openBlock({TemplateBlockModel? block, int? hour}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTemplateBlockScreen(
          block: block,
          dayIndex: _day,
          initialStartTime: hour == null
              ? null
              : TimeOfDay(hour: hour, minute: 0),
          initialEndTime: hour == null
              ? null
              : TimeOfDay(
                  hour: (hour + 1).clamp(0, 23),
                  minute: hour >= 23 ? 59 : 0,
                ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (result == 'delete' && block != null) {
        _blocks.removeWhere((b) => b.id == block.id);
      } else if (result is TemplateBlockModel) {
        final i = _blocks.indexWhere((b) => b.id == result.id);
        i == -1 ? _blocks.add(result) : _blocks[i] = result;
        _day = result.dayIndex;
      }
    });
  }

  /// Dựng giao diện màn hình chi tiết lịch mẫu.
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final dayBlocks = _blocks.where((b) => b.dayIndex == _day).toList();
    double m(TimeOfDay t) => t.hour * 60.0 + t.minute;
    final slots = OverlapLayout.compute([
      for (final b in dayBlocks) (m(b.startTime), m(b.endTime)),
    ]);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _autoDraft();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: widget.isEditMode
              ? TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: l.templateNameHint,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                )
              : Text(_nameController.text),
          actions: [
            if (widget.isEditMode)
              TextButton(onPressed: _saveOfficial, child: Text(l.save)),
            const SizedBox(width: 4),
          ],
        ),
        floatingActionButton: widget.isEditMode
            ? FloatingActionButton(
                onPressed: () => _openBlock(),
                tooltip: l.addActivity,
                child: const Icon(Icons.add),
              )
            : null,
        body: Column(
          children: [
            // Thanh chọn thứ trong tuần
            SizedBox(
              height: 62,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                itemCount: 7,
                itemBuilder: (context, i) {
                  final d = i + 1;
                  final selected = _day == d;
                  final count = _blocks.where((b) => b.dayIndex == d).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _day = d);
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToFirst(),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : cs.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : cs.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              l.weekdayShort(d),
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: selected ? Colors.white : cs.onSurface,
                              ),
                            ),
                            if (count > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: selected
                                        ? AppColors.primary
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: TimeGrid(
                controller: _gridController,
                onTapHour: widget.isEditMode
                    ? (h) => _openBlock(hour: h)
                    : null,
                layersBuilder: (width) => [
                  for (int i = 0; i < dayBlocks.length; i++)
                    gridBlock(
                      startMinute: m(dayBlocks[i].startTime),
                      endMinute:
                          m(dayBlocks[i].endTime) <= m(dayBlocks[i].startTime)
                          ? 24 * 60
                          : m(dayBlocks[i].endTime),
                      left: TimeGrid.labelWidth,
                      width: width,
                      column: slots[i].column,
                      columns: slots[i].columns,
                      child: TimeblockCard(
                        title: dayBlocks[i].title,
                        timeLabel: Fmt.todRange(
                          context,
                          dayBlocks[i].startTime,
                          dayBlocks[i].endTime,
                        ),
                        color: dayBlocks[i].flutterColor,
                        onTap: widget.isEditMode
                            ? () => _openBlock(block: dayBlocks[i])
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
