import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/time_grid_calculator.dart';
import '../../utils/app_time.dart';
import '../../theme/app_theme.dart';
import 'time_grid.dart';

class CurrentTimeLine extends StatefulWidget {
  const CurrentTimeLine({super.key});

  @override
  State<CurrentTimeLine> createState() => _CurrentTimeLineState();
}

class _CurrentTimeLineState extends State<CurrentTimeLine> {
  Timer? _timer;

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

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    AppTime.changes.removeListener(_refresh);
    super.dispose();
  }

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
