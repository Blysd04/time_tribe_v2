import 'package:flutter/material.dart';

class TemplateBlockModel {
  final String id;
  final String templateId;
  final int dayIndex;
  final String title;
  final String? description;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String colorCode;
  final int remind;

  TemplateBlockModel({
    required this.id,
    required this.templateId,
    required this.dayIndex,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.colorCode,
    this.remind = 15,
  });

  /// Đổi mã màu "#RRGGBB" thành Color để vẽ.
  Color get flutterColor => Color(int.parse(colorCode.replaceAll('#', '0xFF')));

  /// Đọc một dòng template_blocks từ JSON backend.
  factory TemplateBlockModel.fromJson(Map<String, dynamic> json) {
    return TemplateBlockModel(
      id: json['id'] ?? '',
      templateId: json['template_id'] ?? '',
      dayIndex: json['day_index'] ?? 1,
      title: json['title'] ?? '',
      description: json['description'],
      startTime: _parseTime(json['start_time']),
      endTime: _parseTime(json['end_time']),
      colorCode: json['color_code'] ?? '#3A86FF',
      remind: json['remind'] ?? 15,
    );
  }

  /// Body của một khối khi gửi lên server (server tự sinh id mới).
  Map<String, dynamic> toJson() {
    return {
      'day_index': dayIndex,
      'title': title,
      'description': description,
      'start_time': _formatTime(startTime),
      'end_time': _formatTime(endTime),
      'color_code': colorCode,
      'remind': remind,
    };
  }

  /// "HH:mm:ss" -> TimeOfDay.
  static TimeOfDay _parseTime(String? timeString) {
    if (timeString == null) return const TimeOfDay(hour: 0, minute: 0);
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// TimeOfDay -> "HH:mm:00".
  static String _formatTime(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00";
  }
}

class TemplateModel {
  final String id;
  final String userId;
  final String? originalTemplateId;
  final String templateName;

  /// Mã chia sẻ (share_code), null là chưa chia sẻ.
  final String? shareCode;
  final DateTime dateModified;
  final DateTime createdAt;
  final List<TemplateBlockModel> blocks;

  TemplateModel({
    required this.id,
    required this.userId,
    this.originalTemplateId,
    required this.templateName,
    this.shareCode,
    DateTime? dateModified,
    DateTime? createdAt,
    required this.blocks,
  }) : dateModified = dateModified ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  /// Đọc lịch mẫu kèm danh sách khối (blocks) từ JSON backend.
  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    var blockList = json['blocks'] as List? ?? [];
    List<TemplateBlockModel> parsedBlocks = blockList
        .map((i) => TemplateBlockModel.fromJson(i))
        .toList();

    return TemplateModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      originalTemplateId: json['original_template_id'],
      templateName: json['template_name'] ?? '',
      shareCode: json['share_code'],
      dateModified: json['date_modified'] != null
          ? DateTime.parse(json['date_modified'])
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      blocks: parsedBlocks,
    );
  }

  /// Body gửi lên khi tạo hoặc sửa: tên và toàn bộ danh sách khối.
  Map<String, dynamic> toJson() {
    return {
      'template_name': templateName,
      'blocks': blocks.map((b) => b.toJson()).toList(),
    };
  }
}
