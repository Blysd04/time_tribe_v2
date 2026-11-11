import 'package:flutter/material.dart';

import '../../utils/formatters.dart';
import '../../utils/time_grid_calculator.dart';

/// Lưới 24 giờ dùng chung cho Lịch cá nhân, Lịch nhóm và Lịch mẫu.
///
/// [layersBuilder] nhận độ rộng phần nội dung (bên phải cột giờ) và trả về
/// các widget `Positioned` đặt lên lưới.
class TimeGrid extends StatefulWidget {
  static const double labelWidth = 80;
  static const double rightPadding = 12;
  static const double totalHeight = 24 * TimeGridCalculator.hourRowHeight;

  final ScrollController? controller;
  final List<Widget> Function(double contentWidth) layersBuilder;
  final ValueChanged<int>? onTapHour;
  final EdgeInsets padding;

  /// Giờ cần đưa vào tầm nhìn (VD giờ hiện tại khi xem hôm nay), tính bằng giờ có phần lẻ.
  /// Lưới tự cuộn tới đây ngay khi được vẽ ra, và mỗi lần [focusKey] đổi.
  final double? focusHour;

  /// Đổi giá trị này (VD ngày đang xem) để lưới cuộn lại tới [focusHour].
  final Object? focusKey;

  const TimeGrid({
    super.key,
    this.controller,
    required this.layersBuilder,
    this.onTapHour,
    this.padding = const EdgeInsets.only(bottom: 96),
    this.focusHour,
    this.focusKey,
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
  State<TimeGrid> createState() => _TimeGridState();
}

class _TimeGridState extends State<TimeGrid> {
  ScrollController? _own;

  ScrollController get _controller =>
      widget.controller ?? (_own ??= ScrollController());

  /// Lưới vừa được vẽ ra (mở trang, hoặc tải xong dữ liệu thay cho vòng xoay):
  /// cuộn ngay tới giờ cần xem, không để người dùng thấy lưới đứng ở 0 giờ.
  @override
  void initState() {
    super.initState();
    _scheduleFocus();
  }

  @override
  void didUpdateWidget(TimeGrid old) {
    super.didUpdateWidget(old);
    if (widget.focusKey != old.focusKey) _scheduleFocus();
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  /// Chờ lưới dựng xong (đã biết chiều cao màn hình) rồi mới cuộn; chưa sẵn sàng thì thử lại vài khung hình.
  void _scheduleFocus([int attempt = 0]) {
    final hour = widget.focusHour;
    if (hour == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final c = _controller;
      if (!c.hasClients || c.position.maxScrollExtent <= 0) {
        if (attempt < 5) _scheduleFocus(attempt + 1);
        return;
      }
      TimeGrid.scrollToHour(c, widget.focusHour ?? hour);
    });
  }

  /// Dựng giao diện lưới 24 giờ.
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onTapHour = widget.onTapHour;
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth =
            constraints.maxWidth - TimeGrid.labelWidth - TimeGrid.rightPadding;
        return SingleChildScrollView(
          controller: _controller,
          padding: widget.padding,
          child: SizedBox(
            height: TimeGrid.totalHeight,
            child: Stack(
              children: [
                Column(
                  children: List.generate(24, (h) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTapHour == null ? null : () => onTapHour(h),
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
                ...widget.layersBuilder(contentWidth),
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
