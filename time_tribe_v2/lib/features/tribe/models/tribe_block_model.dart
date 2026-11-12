import 'package:flutter/painting.dart';

import '../../../core/models/app_user.dart';

/// enum tribe_block_attendance.status
enum AttendanceStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined');

  final String value;
  const AttendanceStatus(this.value);

  /// Đổi chuỗi trong JSON thành enum, giá trị lạ thì coi như đang chờ.
  static AttendanceStatus fromValue(String? value) =>
      AttendanceStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => AttendanceStatus.pending,
      );
}

/// Một dòng tribe_block_attendance, kèm thông tin người trả lời để hiển thị.
class TribeBlockAttendance {
  final String id;
  final String tribeBlockId;
  final String userId;
  final AttendanceStatus status;
  final DateTime updatedAt;
  final AppUser? user;

  TribeBlockAttendance({
    required this.id,
    required this.tribeBlockId,
    required this.userId,
    this.status = AttendanceStatus.pending,
    DateTime? updatedAt,
    this.user,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Tạo bản sao với trạng thái mới.
  TribeBlockAttendance copyWith({AttendanceStatus? status}) =>
      TribeBlockAttendance(
        id: id,
        tribeBlockId: tribeBlockId,
        userId: userId,
        status: status ?? this.status,
        updatedAt: DateTime.now(),
        user: user,
      );

  /// Đọc JSON backend trả về trong danh sách attendance của một hoạt động.
  factory TribeBlockAttendance.fromJson(Map<String, dynamic> json) =>
      TribeBlockAttendance(
        id: json['id'] ?? '',
        tribeBlockId: json['tribe_block_id'] ?? '',
        userId: json['user_id'] ?? '',
        status: AttendanceStatus.fromValue(json['status']),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
        user: json['user'] is Map<String, dynamic>
            ? AppUser.fromJson(json['user'])
            : null,
      );
}

/// Hoạt động nhóm, bảng tribe_blocks.
///
/// Quy ước múi giờ: date, start_time, end_time của hoạt động nhóm lưu theo UTC.
/// Thành viên ở nhiều múi giờ khác nhau, mỗi người thấy giờ đã quy đổi theo múi giờ
/// trong hồ sơ của chính họ. Khác với timeblocks cá nhân lưu theo múi giờ chủ lịch.
class TribeBlockModel {
  /// Hoạt động nhóm mặc định nhắc trước 1 tiếng.
  static const int defaultRemindMinutes = 60;

  final String id;
  final String tribeId;
  final String createdBy;
  final String task;
  final String? description;
  final DateTime startUtc;
  final DateTime endUtc;
  final String colorCode;
  final int remind;
  final DateTime createdAt;
  final List<TribeBlockAttendance> attendance;

  TribeBlockModel({
    required this.id,
    required this.tribeId,
    required this.createdBy,
    required this.task,
    this.description,
    required DateTime startUtc,
    required DateTime endUtc,
    this.colorCode = '#3A86FF',
    this.remind = defaultRemindMinutes,
    DateTime? createdAt,
    this.attendance = const [],
  }) : startUtc = startUtc.toUtc(),
       endUtc = endUtc.toUtc(),
       createdAt = createdAt ?? DateTime.now();

  /// Đổi mã màu "#RRGGBB" thành Color để vẽ.
  Color get flutterColor => Color(int.parse(colorCode.replaceAll('#', '0xFF')));

  /// Trạng thái trả lời của một người, chưa có dòng nào thì coi như đang chờ.
  AttendanceStatus statusOf(String userId) {
    for (final a in attendance) {
      if (a.userId == userId) return a.status;
    }
    return AttendanceStatus.pending;
  }

  /// Danh sách id những người có trạng thái [status].
  List<String> userIdsWith(AttendanceStatus status) =>
      attendance.where((a) => a.status == status).map((a) => a.userId).toList();

  /// Hoạt động có giao với khoảng thời gian (UTC) này không.
  bool overlaps(DateTime startUtc, DateTime endUtc) =>
      this.startUtc.isBefore(endUtc) && this.endUtc.isAfter(startUtc);

  /// Tạo bản sao với vài trường thay đổi (dùng khi sửa hoạt động).
  TribeBlockModel copyWith({
    String? task,
    String? description,
    DateTime? startUtc,
    DateTime? endUtc,
    String? colorCode,
    List<TribeBlockAttendance>? attendance,
  }) => TribeBlockModel(
    id: id,
    tribeId: tribeId,
    createdBy: createdBy,
    task: task ?? this.task,
    description: description ?? this.description,
    startUtc: startUtc ?? this.startUtc,
    endUtc: endUtc ?? this.endUtc,
    colorCode: colorCode ?? this.colorCode,
    remind: remind,
    createdAt: createdAt,
    attendance: attendance ?? this.attendance,
  );

  /// Body gửi lên khi tạo hoặc sửa, giờ gửi dạng start_utc / end_utc (RFC3339).
  Map<String, dynamic> toRequest() => {
    'task': task,
    'description': description,
    'start_utc': startUtc.toIso8601String(),
    'end_utc': endUtc.toIso8601String(),
    'color_code': colorCode,
  };

  /// Đọc JSON backend. Ưu tiên start_utc / end_utc, không có thì ghép từ date + giờ (UTC).
  factory TribeBlockModel.fromJson(Map<String, dynamic> json) {
    DateTime start, end;
    if (json['start_utc'] != null && json['end_utc'] != null) {
      start = DateTime.parse(json['start_utc']);
      end = DateTime.parse(json['end_utc']);
    } else {
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

      start = at(json['start_time'] ?? '00:00:00');
      end = at(json['end_time'] ?? '01:00:00');
      // Qua nửa đêm UTC
      if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    }
    return TribeBlockModel(
      id: json['id'] ?? '',
      tribeId: json['tribe_id'] ?? '',
      createdBy: json['created_by'] ?? '',
      task: json['task'] ?? '',
      description: json['description'],
      startUtc: start,
      endUtc: end,
      colorCode: json['color_code'] ?? '#3A86FF',
      remind: json['remind'] ?? defaultRemindMinutes,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      attendance: [
        for (final a in (json['attendance'] as List? ?? const []))
          TribeBlockAttendance.fromJson(a),
      ],
    );
  }
}
