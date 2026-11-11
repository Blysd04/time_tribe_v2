import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/api_errors.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/form_widgets.dart';
import '../../../timeblock/viewmodels/timeblock_viewmodel.dart';
import '../../models/template_model.dart';
import '../../viewmodels/template_viewmodel.dart';

/// Chép lịch mẫu vào lịch cá nhân trong N tuần tới.
/// Trả về `{'added': n, 'overwritten': m}` khi áp dụng xong.
class ApplyTemplateDialog extends StatefulWidget {
  final TemplateModel template;

  const ApplyTemplateDialog({super.key, required this.template});

  /// Tạo phần state giữ dữ liệu thay đổi của hộp thoại áp dụng lịch mẫu.
  @override
  State<ApplyTemplateDialog> createState() => _ApplyTemplateDialogState();
}

class _ApplyTemplateDialogState extends State<ApplyTemplateDialog> {
  late final List<int> _availableDays =
      widget.template.blocks.map((b) => b.dayIndex).toSet().toList()..sort();
  late final List<int> _selectedDays = List.of(_availableDays);
  int _weeks = 1;
  bool _applying = false;

  /// Bấm Áp dụng: gọi server, nếu bị trùng giờ thì hỏi có thay thế không rồi gọi lại.
  /// Xong thì tải lại lịch cá nhân và đóng hộp thoại đúng một lần.
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

    final templates = context.read<TemplateViewModel>();
    final timeblocks = context.read<TimeblockViewModel>();
    final days = List.of(_selectedDays)..sort();

    var res = await templates.applyTemplate(
      widget.template.id,
      days: days,
      weeks: _weeks,
      replace: false,
    );
    if (!mounted) return;

    // Trùng giờ -> hỏi xác nhận xoá đè
    if (res.hasConflict) {
      final dates = res.conflictDates
          .map((d) => Fmt.date(context, d))
          .join(', ');
      final ok = await AppDialogs.confirm(
        context,
        title: l.conflictTitle,
        message: l.conflictMessage(res.conflictCount, dates),
        confirmLabel: l.replaceAndAdd,
        destructive: true,
      );
      if (!mounted) return;
      if (!ok) {
        setState(() => _applying = false);
        return;
      }
      res = await templates.applyTemplate(
        widget.template.id,
        days: days,
        weeks: _weeks,
        replace: true,
      );
      if (!mounted) return;
    }

    if (res.error != null) {
      setState(() => _applying = false);
      AppSnack.show(context, l.apiError(res.error), type: AppSnackType.error);
      return;
    }
    await timeblocks.reload();
    if (mounted) {
      Navigator.of(
        context,
      ).pop({'added': res.added, 'overwritten': res.overwritten});
    }
  }

  /// Dựng giao diện hộp thoại áp dụng lịch mẫu.
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
