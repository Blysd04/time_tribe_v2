import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/form_widgets.dart';
import '../models/template_model.dart';
import '../viewmodels/template_viewmodel.dart';
import 'template_detail_screen.dart';
import 'template_dialogs.dart';
import 'widgets/apply_template_dialog.dart';

/// Kho lịch mẫu — cùng bố cục với danh sách Tribe.
class TemplateScreen extends StatelessWidget {
  const TemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<TemplateViewModel>();

    if (vm.templates.isEmpty) {
      return EmptyState(
        icon: Icons.dashboard_customize_outlined,
        title: l.noTemplatesTitle,
        message: l.noTemplatesMessage,
        actions: [
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TemplateDetailScreen(isEditMode: true),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(l.createTemplate),
          ),
          OutlinedButton.icon(
            onPressed: () => showImportTemplateDialog(context),
            icon: const Icon(Icons.link),
            label: Text(l.importTemplate),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        4,
        AppSpacing.page,
        24,
      ),
      children: [
        SectionLabel(
          l.yourTemplates,
          trailing: CountPill(
            '${vm.templates.length}/${TemplateLimits.maxTemplates}',
          ),
          padding: const EdgeInsets.fromLTRB(4, 0, 0, 12),
        ),
        for (final t in vm.templates) _TemplateCard(template: t),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final TemplateModel template;
  const _TemplateCard({required this.template});

  Future<void> _apply(BuildContext context) async {
    final l = context.l10n;
    final result = await showDialog(
      context: context,
      builder: (_) => ApplyTemplateDialog(template: template),
    );
    if (result is Map && context.mounted) {
      final added = result['added'] as int? ?? 0;
      final overwritten = result['overwritten'] as int? ?? 0;
      if (added > 0) {
        AppSnack.show(
          context,
          overwritten > 0
              ? l.templateAppliedReplaced(added, overwritten)
              : l.templateApplied(added),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final color = template.blocks.isNotEmpty
        ? template.blocks.first.flutterColor
        : AppColors.primary;
    final days = template.blocks.map((b) => b.dayIndex).toSet().toList()
      ..sort();

    return AppCard(
      accent: color,
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TemplateDetailScreen(template: template),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.dashboard_customize_outlined, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.templateName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.activitiesCount(template.blocks.length),
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (days.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final d in days)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            l.weekdayShort(d),
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
                onSelected: (v) async {
                  switch (v) {
                    case 'edit':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TemplateDetailScreen(
                            template: template,
                            isEditMode: true,
                          ),
                        ),
                      );
                    case 'share':
                      showShareTemplateSheet(context, template);
                    case 'delete':
                      final ok = await AppDialogs.confirm(
                        context,
                        title: l.deleteTemplateTitle,
                        message: l.deleteTemplateMessage(template.templateName),
                        confirmLabel: l.delete,
                        destructive: true,
                      );
                      if (ok && context.mounted) {
                        context.read<TemplateViewModel>().deleteTemplate(
                          template.id,
                        );
                        AppSnack.show(context, l.templateDeleted);
                      }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text(l.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        const Icon(Icons.share_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text(l.share),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l.delete,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: template.blocks.isEmpty
                      ? null
                      : () => _apply(context),
                  child: Text(l.apply),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
