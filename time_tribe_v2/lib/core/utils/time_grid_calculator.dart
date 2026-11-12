import 'package:flutter/material.dart';

// import '../../features/timeblock/models/timeblock_model.dart';

class TimeGridCalculator {
  static const double hourRowHeight = 80.0; // Định mức chiều cao 1 giờ

  // Tính khoảng cách từ đỉnh (Top Offset) dựa vào startTime
  static double calculateTopOffset(TimeOfDay startTime) {
    return (startTime.hour * hourRowHeight) +
        ((startTime.minute / 60.0) * hourRowHeight);
  }

  // Tính độ cao của thẻ công việc (Height)
  static double calculateHeight(TimeOfDay startTime, TimeOfDay endTime) {
    int startMinutes = startTime.hour * 60 + startTime.minute;
    int endMinutes = endTime.hour * 60 + endTime.minute;

    // Xử lý trường hợp xuyên đêm (nếu có)
    if (endMinutes <= startMinutes) {
      endMinutes += 24 * 60;
    }

    return ((endMinutes - startMinutes) / 60.0) * hourRowHeight;
  }
}
