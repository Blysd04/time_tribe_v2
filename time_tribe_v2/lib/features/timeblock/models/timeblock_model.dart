import 'package:flutter/material.dart';

/// Một hoạt động cá nhân, khớp bảng timeblocks.
/// date, start_time, end_time tính theo múi giờ của chính người dùng.
class TimeblockModel {
  final String id;
  final String userId;
  final String task;
  final String? description;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String colorCode;

  /// Các ngày đã nhân bản từ hoạt động này (cột repeating_dates).
  final List<DateTime> repeatingDates;
  final int remind;
  final DateTime createdAt;

  TimeblockModel({
    required this.id,
    required this.userId,
    required this.task,
    this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.colorCode,
    this.repeatingDates = const [],
    this.remind = 15,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Đổi mã màu "#RRGGBB" thành Color để vẽ.
  Color get flutterColor => Color(int.parse(colorCode.replaceAll('#', '0xFF')));

  /// Đọc JSON từ backend Go.
  factory TimeblockModel.fromJson(Map<String, dynamic> json) {
    return TimeblockModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      task: json['task'] ?? '',
      description: json['description'],
      date: json['date'] != null ? parseDate(json['date']) : DateTime.now(),
      startTime: parseTime(json['start_time'] ?? '00:00:00'),
      endTime: parseTime(json['end_time'] ?? '01:00:00'),
      colorCode: json['color_code'] ?? '#3A86FF',
      repeatingDates: [
        for (final d in (json['repeating_dates'] as List? ?? const []))
          parseDate(d.toString()),
      ],
      remind: json['remind'] ?? 15,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  /// Body gửi lên khi tạo hoặc sửa. duplicateDates là các ngày muốn nhân bản thêm.
  Map<String, dynamic> toRequest({List<DateTime> duplicateDates = const []}) {
    return {
      'task': task,
      'description': description,
      'date': formatDate(date),
      'start_time': formatTime(startTime),
      'end_time': formatTime(endTime),
      'color_code': colorCode,
      'remind': remind,
      'repeating_dates': [for (final d in duplicateDates) formatDate(d)],
    };
  }

  /// "2026-11-05" -> DateTime(2026, 11, 5), không dính múi giờ.
  static DateTime parseDate(String s) {
    final p = s.substring(0, 10).split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  /// DateTime -> "2026-11-05".
  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Chuyển chuỗi "HH:mm:ss" thành TimeOfDay, chuỗi lỗi thì trả 00:00 cho khỏi crash.
  static TimeOfDay parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  /// TimeOfDay -> "HH:mm:00".
  static String formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }
}
