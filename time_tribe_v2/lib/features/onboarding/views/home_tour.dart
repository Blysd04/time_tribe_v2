import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';

/// Các GlobalKey gắn vào những nút trên trang chủ để hướng dẫn làm nổi lên.
class HomeTourKeys {
  final menu = GlobalKey(debugLabel: 'tour.menu');
  final content = GlobalKey(debugLabel: 'tour.content');
  final add = GlobalKey(debugLabel: 'tour.add');
  final notifications = GlobalKey(debugLabel: 'tour.notifications');
  final profile = GlobalKey(debugLabel: 'tour.profile');
  final settings = GlobalKey(debugLabel: 'tour.settings');
}

/// Hướng dẫn từng bước trên trang chủ (dùng tutorial_coach_mark):
/// làm tối màn hình, khoét sáng từng nút và hiện thẻ giải thích ngay cạnh.
class HomeTour {
  HomeTour._();

  static TutorialCoachMark? _current;

  /// Hướng dẫn có đang hiện không.
  static bool get isShowing => _current?.isShowing ?? false;

  /// Bắt đầu hướng dẫn. Nút nào chưa được vẽ (không tìm thấy key) thì bỏ qua bước đó.
  static void show(BuildContext context, HomeTourKeys keys, {VoidCallback? onDone}) {
    if (isShowing) return;
    final l = context.l10n;
    final size = MediaQuery.of(context).size;

    final steps =
        <
              (
                GlobalKey,
                IconData,
                String,
                String,
                ContentAlign,
                ShapeLightFocus,
              )
            >[
              (
                keys.menu,
                Icons.menu,
                l.tourMenuTitle,
                l.tourMenuBody,
                ContentAlign.bottom,
                ShapeLightFocus.Circle,
              ),
              (
                keys.content,
                Icons.view_timeline_outlined,
                l.tourContentTitle,
                l.tourContentBody,
                ContentAlign.custom,
                ShapeLightFocus.RRect,
              ),
              (
                keys.add,
                Icons.add_circle_outline,
                l.tourAddTitle,
                l.tourAddBody,
                ContentAlign.top,
                ShapeLightFocus.Circle,
              ),
              (
                keys.notifications,
                Icons.notifications_none_outlined,
                l.tourNotiTitle,
                l.tourNotiBody,
                ContentAlign.top,
                ShapeLightFocus.Circle,
              ),
              (
                keys.profile,
                Icons.person_outline,
                l.tourProfileTitle,
                l.tourProfileBody,
                ContentAlign.top,
                ShapeLightFocus.Circle,
              ),
              (
                keys.settings,
                Icons.settings_outlined,
                l.tourSettingsTitle,
                l.tourSettingsBody,
                ContentAlign.top,
                ShapeLightFocus.Circle,
              ),
            ]
            .where((s) => s.$1.currentContext != null)
            .toList();
    if (steps.isEmpty) return;

    final targets = <TargetFocus>[
      for (int i = 0; i < steps.length; i++)
        TargetFocus(
          identify: steps[i].$3,
          keyTarget: steps[i].$1,
          shape: steps[i].$6,
          radius: 20,
          paddingFocus: steps[i].$6 == ShapeLightFocus.Circle ? 6 : 0,
          enableOverlayTab: false,
          contents: [
            TargetContent(
              align: steps[i].$5,
              // Vùng lịch chiếm gần hết màn hình: đặt thẻ giải thích ở phía dưới vùng sáng
              customPosition: steps[i].$5 == ContentAlign.custom
                  ? CustomTargetContentPosition(left: 0, bottom: size.height * 0.16)
                  : null,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              builder: (context, controller) => _TourCard(
                icon: steps[i].$2,
                title: steps[i].$3,
                body: steps[i].$4,
                step: i + 1,
                total: steps.length,
                controller: controller,
              ),
            ),
          ],
        ),
    ];

    void finished() {
      _current = null;
      onDone?.call();
    }

    _current = TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF0B1A33),
      opacityShadow: 0.86,
      hideSkip: true, // Thẻ giải thích đã có nút Bỏ qua
      paddingFocus: 8,
      pulseEnable: true,
      onFinish: finished,
      onSkip: () {
        finished();
        return true;
      },
    )..show(context: context);
  }
}

/// Thẻ giải thích của một bước: icon, tiêu đề, mô tả, số bước, nút Bỏ qua / Tiếp tục.
class _TourCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final int step;
  final int total;
  final TutorialCoachMarkController controller;

  const _TourCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.step,
    required this.total,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final last = step == total;

    return Material(
      color: cs.surface,
      elevation: 8,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Text(
                  '$step/$total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: cs.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Thanh tiến trình nhỏ
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: step / total,
                minHeight: 3,
                color: AppColors.primary,
                backgroundColor: cs.onSurface.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (!last)
                  TextButton(
                    onPressed: controller.skip,
                    child: Text(
                      l.onbSkip,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                const Spacer(),
                if (step > 1)
                  IconButton(
                    tooltip: l.onbBack,
                    onPressed: controller.previous,
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: controller.next,
                  child: Text(last ? l.tourDone : l.onbNext),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
