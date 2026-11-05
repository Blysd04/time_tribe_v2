import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_time.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../timeblock/models/timeblock_model.dart';
import '../../../timeblock/viewmodels/timeblock_viewmodel.dart';
import '../../models/template_model.dart';

/// Chép lịch mẫu vào lịch cá nhân trong N tuần tới.
/// Trả về `{'added': n, 'overwritten': m}` khi áp dụng xong.
class ApplyTemplateDialog extends StatefulWidget {
  final TemplateModel template;

  const ApplyTemplateDialog({super.key, required this.template});

  @override
  State<ApplyTemplateDialog> createState() => _ApplyTemplateDialogState();
}

class _ApplyTemplateDialogState extends State<ApplyTemplateDialog> {
  late final List<int> _availableDays =
      widget.template.blocks.map((b) => b.dayIndex).toSet().toList()..sort();
  late final List<int> _selectedDays = List.of(_availableDays);
  int _weeks = 1;
  bool _applying = false;

  Future<void> _apply() async {
    final l = context.l10n;
    if (_applying) return;
    if (_selectedDays.isEmpty) {
      AppSnack.show(
        context,
        l.errorPickAtLeastOneDay,
        type: AppSnackType.error,
      );
      return;
    }
    setState(() => _applying = true);

    final vm = context.read<TimeblockViewModel>();
    final today = AppTime.today();

    // 1. Tạo đủ danh sách block mới (chưa đụng tới Navigator)
    final toAdd = <TimeblockModel>[];
    for (final day in _selectedDays) {
      var offset = day - today.weekday;
      if (offset < 0) offset += 7;
      for (int w = 0; w < _weeks; w++) {
        final date = DateTime(
          today.year,
          today.month,
          today.day + offset + w * 7,
        );
        for (final tb in widget.template.blocks.where(
          (b) => b.dayIndex == day,
        )) {
          toAdd.add(
            TimeblockModel(
              id: const Uuid().v4(),
              userId: widget.template.userId,
              task: tb.title,
              description: tb.description ?? '',
              date: date,
              startTime: tb.startTime,
              endTime: tb.endTime,
              colorCode: tb.colorCode,
              remind: tb.remind,
            ),
          );
        }
      }
    }

    // 2. Kiểm tra trùng lịch 1 lần cho toàn bộ
    final conflicts = <String, TimeblockModel>{};
    final conflictDates = <DateTime>{};
    for (final b in toAdd) {
      final c = vm.getConflictingBlocks(b);
      if (c.isNotEmpty) {
        for (final x in c) {
          conflicts[x.id] = x;
        }
        conflictDates.add(DateTime(b.date.year, b.date.month, b.date.day));
      }
    }

    // 3. Trùng -> hỏi xác nhận xoá đè
    if (conflicts.isNotEmpty) {
      final dates = (conflictDates.toList()..sort())
          .map((d) => Fmt.date(context, d))
          .join(', ');
      final ok = await AppDialogs.confirm(
        context,
        title: l.conflictTitle,
        message: l.conflictMessage(conflicts.length, dates),
        confirmLabel: l.replaceAndAdd,
        destructive: true,
      );
      if (!mounted) return;
      if (!ok) {
        setState(() => _applying = false);
        return;
      }
      vm.deleteTimeblocks(conflicts.keys.toList());
    }

    // 4. Thêm và đóng hộp thoại ĐÚNG 1 LẦN
    vm.addTimeblocks(toAdd);
    if (mounted) {
      Navigator.of(
        context,
      ).pop({'added': toAdd.length, 'overwritten': conflicts.length});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(l.applyTemplate)),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.applyTemplateDescription,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int d = 1; d <= 7; d++)
                Opacity(
                  opacity: _availableDays.contains(d) ? 1 : 0.35,
                  child: AppFilterChip(
                    label: l.weekdayShort(d),
                    selected: _selectedDays.contains(d),
                    onTap: () {
                      if (!_availableDays.contains(d)) return;
                      setState(
                        () => _selectedDays.contains(d)
                            ? _selectedDays.remove(d)
                            : _selectedDays.add(d),
                      );
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.repeatWeeks,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _weeks > 1
                          ? () => setState(() => _weeks--)
                          : null,
                    ),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$_weeks',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _weeks < 12
                          ? () => setState(() => _weeks++)
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InfoBanner(text: l.applyTemplateNote, color: AppColors.primary),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _availableDays.isEmpty || _applying ? null : _apply,
            child: _applying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(l.applyNow),
          ),
        ),
      ],
    );
  }
}
