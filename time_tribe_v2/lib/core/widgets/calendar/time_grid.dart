import 'package:flutter/material.dart';

import '../../utils/formatters.dart';
import '../../utils/time_grid_calculator.dart';

/// Lưới 24 giờ dùng chung cho Lịch cá nhân, Lịch nhóm và Lịch mẫu.
///
/// [layersBuilder] nhận độ rộng phần nội dung (bên phải cột giờ) và trả về
/// các widget `Positioned` đặt lên lưới.
class TimeGrid extends StatelessWidget {
  static const double labelWidth = 80;
  static const double rightPadding = 12;
  static const double totalHeight = 24 * TimeGridCalculator.hourRowHeight;

  final ScrollController? controller;
  final List<Widget> Function(double contentWidth) layersBuilder;
  final ValueChanged<int>? onTapHour;
  final EdgeInsets padding;

  const TimeGrid({
    super.key,
    this.controller,
    required this.layersBuilder,
    this.onTapHour,
    this.padding = const EdgeInsets.only(bottom: 96),
  });

  /// Toạ độ Y của một mốc (tính bằng phút từ 00:00).
  static double yOfMinutes(double minutes) =>
      minutes / 60 * TimeGridCalculator.hourRowHeight;

  /// Cuộn sao cho [hour] nằm ở khoảng 1/3 màn hình.
  static void scrollToHour(ScrollController controller, double hour) {
    if (!controller.hasClients) return;
    final p = controller.position;
    final offset =
        hour * TimeGridCalculator.hourRowHeight - p.viewportDimension / 3;
    controller.jumpTo(offset.clamp(p.minScrollExtent, p.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - labelWidth - rightPadding;
        return SingleChildScrollView(
          controller: controller,
          padding: padding,
          child: SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                Column(
                  children: List.generate(24, (h) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTapHour == null ? null : () => onTapHour!(h),
                      child: Container(
                        height: TimeGridCalculator.hourRowHeight,
                        padding: const EdgeInsets.only(left: 16, top: 8),
                        alignment: Alignment.topLeft,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: cs.onSurface.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        child: Text(
                          Fmt.hourLabel(context, h),
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                ...layersBuilder(contentWidth),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Đặt một khối lên lưới theo phút bắt đầu/kết thúc và cột (khi bị trùng).
Widget gridBlock({
  required double startMinute,
  required double endMinute,
  required double left,
  required double width,
  required Widget child,
  int column = 0,
  int columns = 1,
  double gap = 4,
  double minHeight = 18,
}) {
  final top = TimeGrid.yOfMinutes(startMinute);
  final height = (TimeGrid.yOfMinutes(endMinute) - top).clamp(
    minHeight,
    double.infinity,
  );
  final colWidth = (width - gap * (columns - 1)) / columns;
  return Positioned(
    top: top + 1,
    left: left + column * (colWidth + gap),
    width: colWidth,
    height: height - 2,
    child: child,
  );
}
