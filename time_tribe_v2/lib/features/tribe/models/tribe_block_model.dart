import 'package:flutter/painting.dart';

/// enum `tribe_blocks.block_type` — giữ trong model cho khớp database,
/// giao diện không cho chọn (mặc định `work`).
enum TribeBlockType {
  work('work'),
  entertainment('entertainment'),
  study('study'),
  meeting('meeting'),
  other('other');

  final String value;
  const TribeBlockType(this.value);

  static TribeBlockType fromValue(String? value) => TribeBlockType.values
      .firstWhere((t) => t.value == value, orElse: () => TribeBlockType.work);
}

/// enum `tribe_block_attendance.status`
enum AttendanceStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined');

  final String value;
  const AttendanceStatus(this.value);

  static AttendanceStatus fromValue(String? value) =>
      AttendanceStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => AttendanceStatus.pending,
      );
}

/// Một dòng `tribe_block_attendance`.
class TribeBlockAttendance {
  final String id;
  final String tribeBlockId;
  final String userId;
  final AttendanceStatus status;
  final DateTime updatedAt;

  TribeBlockAttendance({
    required this.id,
    required this.tribeBlockId,
    required this.userId,
    this.status = AttendanceStatus.pending,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  TribeBlockAttendance copyWith({AttendanceStatus? status}) =>
      TribeBlockAttendance(
        id: id,
        tribeBlockId: tribeBlockId,
        userId: userId,
        status: status ?? this.status,
        updatedAt: DateTime.now(),
      );
}

/// Hoạt động nhóm — bảng `tribe_blocks`.
///
/// QUY ƯỚC MÚI GIỜ: `date`, `start_time`, `end_time` của hoạt động nhóm được
/// lưu theo **UTC**. Vì thành viên có thể ở nhiều múi giờ khác nhau, mỗi người
/// sẽ thấy hoạt động được quy đổi sang múi giờ trong Profile của chính họ.
/// (Khác với `timeblocks` cá nhân — lưu theo múi giờ của chủ sở hữu.)
class TribeBlockModel {
  /// Hoạt động nhóm không lặp lại và luôn nhắc trước 1 tiếng.
  static const int defaultRemindMinutes = 60;

  final String id;
  final String tribeId;
  final String createdBy;
  final String? parentBlockId;
  final String task;
  final String? description;
  final TribeBlockType blockType;
  final DateTime startUtc;
  final DateTime endUtc;
  final String colorCode;
  final String repeating;
  final int remind;
  final DateTime createdAt;
  final List<TribeBlockAttendance> attendance;

  TribeBlockModel({
    required this.id,
    required this.tribeId,
    required this.createdBy,
    this.parentBlockId,
    required this.task,
    this.description,
    this.blockType = TribeBlockType.work,
    required DateTime startUtc,
    required DateTime endUtc,
    this.colorCode = '#3A86FF',
    this.repeating = 'none',
    this.remind = defaultRemindMinutes,
    DateTime? createdAt,
    this.attendance = const [],
  }) : startUtc = startUtc.toUtc(),
       endUtc = endUtc.toUtc(),
       createdAt = createdAt ?? DateTime.now();

  Color get flutterColor => Color(int.parse(colorCode.replaceAll('#', '0xFF')));

  AttendanceStatus statusOf(String userId) {
    for (final a in attendance) {
      if (a.userId == userId) return a.status;
    }
    return AttendanceStatus.pending;
  }

  List<String> userIdsWith(AttendanceStatus status) =>
      attendance.where((a) => a.status == status).map((a) => a.userId).toList();

  bool overlaps(DateTime startUtc, DateTime endUtc) =>
      this.startUtc.isBefore(endUtc) && this.endUtc.isAfter(startUtc);

  TribeBlockModel copyWith({
    String? task,
    String? description,
    TribeBlockType? blockType,
    DateTime? startUtc,
    DateTime? endUtc,
    String? colorCode,
    List<TribeBlockAttendance>? attendance,
  }) => TribeBlockModel(
    id: id,
    tribeId: tribeId,
    createdBy: createdBy,
    parentBlockId: parentBlockId,
    task: task ?? this.task,
    description: description ?? this.description,
    blockType: blockType ?? this.blockType,
    startUtc: startUtc ?? this.startUtc,
    endUtc: endUtc ?? this.endUtc,
    colorCode: colorCode ?? this.colorCode,
    repeating: repeating,
    remind: remind,
    createdAt: createdAt,
    attendance: attendance ?? this.attendance,
  );

  /// JSON đúng cấu trúc bảng (date/start_time/end_time theo UTC).
  Map<String, dynamic> toJson() {
    String two(int v) => v.toString().padLeft(2, '0');
    return {
      'id': id,
      'tribe_id': tribeId,
      'created_by': createdBy,
      'parent_block_id': parentBlockId,
      'task': task,
      'description': description,
      'block_type': blockType.value,
      'date': '${startUtc.year}-${two(startUtc.month)}-${two(startUtc.day)}',
      'start_time': '${two(startUtc.hour)}:${two(startUtc.minute)}:00',
      'end_time': '${two(endUtc.hour)}:${two(endUtc.minute)}:00',
      'color_code': colorCode,
      'repeating': repeating,
      'remind': remind,
    };
  }

  factory TribeBlockModel.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date']);
    DateTime at(String hms) {
      final p = hms.split(':');
      return DateTime.utc(
        date.year,
        date.month,
        date.day,
        int.parse(p[0]),
        int.parse(p[1]),
      );
    }

    final start = at(json['start_time'] ?? '00:00:00');
    var end = at(json['end_time'] ?? '01:00:00');
    // Qua nửa đêm UTC
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    return TribeBlockModel(
      id: json['id'] ?? '',
      tribeId: json['tribe_id'] ?? '',
      createdBy: json['created_by'] ?? '',
      parentBlockId: json['parent_block_id'],
      task: json['task'] ?? '',
      description: json['description'],
      blockType: TribeBlockType.fromValue(json['block_type']),
      startUtc: start,
      endUtc: end,
      colorCode: json['color_code'] ?? '#3A86FF',
      repeating: json['repeating'] ?? 'none',
      remind: json['remind'] ?? defaultRemindMinutes,
    );
  }
}
