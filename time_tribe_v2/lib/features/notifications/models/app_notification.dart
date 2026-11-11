import 'dart:convert';

/// Loại nội dung thông báo, trùng với cột title mà backend lưu.
/// Nội dung chữ được dựng ở giao diện theo ngôn ngữ người dùng đang chọn
/// (xem notification_text.dart), nên server chỉ cần gửi loại + tham số.
enum NotificationKind {
  tribeNewBlock,
  tribeBlockUpdated,
  tribeBlockRescheduled,
  tribeBlockCancelled,
  tribeResponseAccepted,
  tribeResponseDeclined,
  tribeMemberJoined,
  tribeMemberLeft,
  tribeKickedYou,
  tribeRenamed,
  tribeDissolved,
  tribeRoleVice,
  tribeRoleViceRemoved,
  tribeRoleLeader,
  personalBlockAdded,
  personalReminder,
  tribeReminder,

  /// Thông báo chung admin gửi cho mọi người, hiện thẳng title và content.
  systemBroadcast,
}

/// Thông báo hiển thị trong tab Thông báo.
class AppNotification {
  final String id;
  final NotificationKind kind;
  final Map<String, String> args;

  /// enum notifications.type: tribe_join, group_schedule, reminder, tribe_role...
  final String type;
  final String? tribeId;
  final String? referenceId;
  final String? referenceType;

  /// Tiêu đề và nội dung gốc, chỉ dùng cho thông báo chung của admin.
  final String rawTitle;
  final String rawContent;
  final DateTime createdAt;
  bool isUnread;

  AppNotification({
    required this.id,
    required this.kind,
    this.args = const {},
    required this.type,
    this.tribeId,
    this.referenceId,
    this.referenceType,
    this.rawTitle = '',
    this.rawContent = '',
    DateTime? createdAt,
    this.isUnread = true,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Lời mời tham gia hoạt động, hiện nút Tham gia / Không tham gia.
  bool get isAttendanceRequest =>
      kind == NotificationKind.tribeNewBlock ||
      kind == NotificationKind.tribeBlockRescheduled;

  /// Đọc JSON của GET /notifications. Server đã tách sẵn kind, args, tribe_id.
  /// Loại lạ (app bản cũ chưa biết) thì hiện như thông báo chung cho khỏi lỗi.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString() ?? '';
    final kindName = json['kind']?.toString() ?? json['title']?.toString();
    var kind = NotificationKind.values
        .where((k) => k.name == kindName)
        .firstOrNull;
    if (type == 'system_broadcast') kind = NotificationKind.systemBroadcast;

    var args = <String, String>{};
    final rawArgs = json['args'];
    if (rawArgs is Map) {
      args = rawArgs.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else if (json['content'] is String && kind != null) {
      try {
        final decoded = jsonDecode(json['content']) as Map;
        args = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      } catch (_) {}
    }

    return AppNotification(
      id: json['id'] ?? '',
      kind: kind ?? NotificationKind.systemBroadcast,
      args: args,
      type: type,
      tribeId: json['tribe_id'] ?? args['tribe_id'],
      referenceId: json['reference_id'],
      referenceType: json['reference_type'],
      rawTitle: json['title']?.toString() ?? '',
      rawContent: json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : null,
      isUnread: json['is_read'] != true,
    );
  }
}
