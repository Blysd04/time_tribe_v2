import 'package:flutter/material.dart';

class TimeblockModel {
  final String id;
  final String userId;
  final String? parentBlockId;
  final String task;
  final String? description;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String colorCode;
  final String repeating;
  final DateTime? repeatingDateStart;
  final DateTime? repeatingDateEnd;
  final int remind;
  final DateTime createdAt;

  TimeblockModel({
    required this.id,
    required this.userId,
    this.parentBlockId,
    required this.task,
    this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.colorCode,
    this.repeating = 'none',
    this.repeatingDateStart,
    this.repeatingDateEnd,
    this.remind = 15,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Color get flutterColor => Color(int.parse(colorCode.replaceAll('#', '0xFF')));

  // Chuyển JSON từ Go Backend thành Model
  factory TimeblockModel.fromJson(Map<String, dynamic> json) {
    return TimeblockModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      parentBlockId: json['parent_block_id'],
      task: json['task'] ?? 'Chưa có tên',
      description: json['description'],
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      startTime: _parseTime(json['start_time'] ?? '00:00:00'),
      endTime: _parseTime(json['end_time'] ?? '01:00:00'),
      colorCode: json['color_code'] ?? '#3A86FF',
      repeating: json['repeating'] ?? 'none',
      repeatingDateStart: json['repeating_date_start'] != null
          ? DateTime.parse(json['repeating_date_start'])
          : null,
      repeatingDateEnd: json['repeating_date_end'] != null
          ? DateTime.parse(json['repeating_date_end'])
          : null,
      remind: json['remind'] ?? 15,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'parent_block_id': parentBlockId,
      'task': task,
      'description': description,
      'date':
          "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
      'start_time': _formatTime(startTime),
      'end_time': _formatTime(endTime),
      'color_code': colorCode,
      'repeating': repeating,
      'repeating_date_start': repeatingDateStart?.toIso8601String(),
      'repeating_date_end': repeatingDateEnd?.toIso8601String(),
      'remind': remind,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper chuyển chuỗi "HH:mm:ss" của MySQL thành TimeOfDay
  static TimeOfDay _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(
        hour: 0,
        minute: 0,
      ); // Tránh crash app nếu parse lỗi
    }
  }

  static String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m:00";
  }
}
