import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/form_widgets.dart';
import '../models/template_model.dart';
import '../viewmodels/template_viewmodel.dart';
import 'template_detail_screen.dart';

/// Nút "+" ở thanh điều hướng khi đang ở mục Lịch Mẫu.
void showTemplateAddOptions(BuildContext context) {
  final l = context.l10n;
  final full =
      context.read<TemplateViewModel>().templates.length >=
      TemplateLimits.maxTemplates;
  showOptionsSheet(
    context,
    title: l.templates,
    header: full
        ? InfoBanner(
            text: l.errorTemplateLimit(TemplateLimits.maxTemplates),
            color: AppColors.warning,
          )
        : null,
    options: [
      SheetOption(
        icon: Icons.add_box_outlined,
        title: l.createTemplate,
        subtitle: l.createTemplateHint,
        enabled: !full,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TemplateDetailScreen(isEditMode: true),
          ),
        ),
      ),
      SheetOption(
        icon: Icons.vpn_key_outlined,
        color: AppColors.success,
        title: l.importTemplate,
        subtitle: l.importTemplateHint,
        enabled: !full,
        onTap: () => showImportTemplateDialog(context),
      ),
    ],
  );
}

/// Nhập lịch mẫu bằng mã chia sẻ. Lỗi hiện ngay trong hộp thoại.
Future<void> showImportTemplateDialog(BuildContext context) async {
  final l = context.l10n;
  final vm = context.read<TemplateViewModel>();
  final result = await showInputDialog<TemplateImportResult>(
    context,
    title: l.importTemplate,
    description: l.importTemplateCodeHint,
    hint: 'GYM4DAY',
    confirmLabel: l.importAction,
    confirmColor: AppColors.success,
    prefixIcon: Icons.vpn_key_outlined,
    onSubmit: (value) async {
      if (value.trim().isEmpty) return InputOutcome.error(l.errorCodeEmpty);
      final res = await vm.importByCode(value);
      return switch (res) {
        TemplateImportResult.invalidCode => InputOutcome.error(
          l.errorCodeEmpty,
        ),
        TemplateImportResult.notFound => InputOutcome.error(
          l.errorTemplateNotFound,
        ),
        TemplateImportResult.duplicate => InputOutcome.error(
          l.errorTemplateDuplicate,
        ),
        TemplateImportResult.limitExceeded => InputOutcome.error(
          l.errorTemplateLimit(TemplateLimits.maxTemplates),
        ),
        TemplateImportResult.failed => InputOutcome.error(l.errorServer),
        TemplateImportResult.success => const InputOutcome.done(
          TemplateImportResult.success,
        ),
      };
    },
  );
  if (result == TemplateImportResult.success && context.mounted) {
    AppSnack.show(context, l.templateImported);
  }
}

/// TP-08: chia sẻ lịch mẫu bằng mã. Lấy mã từ server rồi hiện kèm nút sao chép.
Future<void> showShareTemplateSheet(
  BuildContext context,
  TemplateModel template,
) async {
  final l = context.l10n;
  final code = await context.read<TemplateViewModel>().shareCodeOf(template);
  if (!context.mounted) return;
  if (code == null) {
    AppSnack.show(context, l.errorServer, type: AppSnackType.error);
    return;
  }
  await showModalBottomSheet(
    context: context,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.shareTemplate,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.shareTemplateDescription,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(
                  left: 14,
                  right: 6,
                  top: 6,
                  bottom: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.vpn_key_outlined,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SelectableText(
                        code,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: code));
                        Navigator.pop(ctx);
                        AppSnack.show(context, l.codeCopied);
                      },
                      child: Text(l.copy),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
