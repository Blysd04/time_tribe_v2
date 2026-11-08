import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/time_grid_calculator.dart';
import '../../utils/app_time.dart';
import '../../theme/app_theme.dart';
import 'time_grid.dart';

class CurrentTimeLine extends StatefulWidget {
  const CurrentTimeLine({super.key});

  /// Tạo phần state giữ dữ liệu thay đổi của vạch giờ hiện tại.
  @override
  State<CurrentTimeLine> createState() => _CurrentTimeLineState();
}

class _CurrentTimeLineState extends State<CurrentTimeLine> {
  Timer? _timer;

  /// Chạy một lần lúc vạch giờ hiện tại vừa được tạo, chuẩn bị dữ liệu ban đầu.
  @override
  void initState() {
    super.initState();
    AppTime.changes.addListener(_refresh);
    _scheduleNextTick();
  }

  // Căn đúng đầu mỗi phút để thanh thời gian không bị trễ
  void _scheduleNextTick() {
    final now = AppTime.now();
    final untilNextMinute = Duration(
      seconds: 60 - now.second,
      milliseconds: -now.millisecond,
    );
    _timer = Timer(untilNextMinute, () {
      _refresh();
      _scheduleNextTick();
    });
  }

  /// Mỗi phút vẽ lại để vạch giờ hiện tại chạy theo đồng hồ.
  void _refresh() {
    if (mounted) setState(() {});
  }

  /// Dọn controller, listener khi vạch giờ hiện tại bị đóng để không rò bộ nhớ.
  @override
  void dispose() {
    _timer?.cancel();
    AppTime.changes.removeListener(_refresh);
    super.dispose();
  }

  /// Dựng giao diện vạch giờ hiện tại.
  @override
  Widget build(BuildContext context) {
    // Gọi AppTime để xác định giờ hiện tại theo cấu hình của người dùng
    DateTime currentAppTime = AppTime.now();

    // Tính toán vị trí top (Toạ độ Y) dựa vào giờ và phút hiện tại
    double relativeHour = currentAppTime.hour + (currentAppTime.minute / 60.0);
    double topOffset = relativeHour * TimeGridCalculator.hourRowHeight;

    return Positioned(
      top: topOffset - 4.0,
      left: TimeGrid.labelWidth - 5,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
