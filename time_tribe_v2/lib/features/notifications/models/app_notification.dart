/// Loại nội dung thông báo. Nội dung chữ được dựng ở giao diện theo ngôn ngữ
/// người dùng đang chọn (xem `notification_text.dart`), nên view model chỉ
/// cần truyền loại + tham số.
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
}

/// Thông báo hiển thị trong tab Thông báo.
class AppNotification {
  final String id;
  final NotificationKind kind;
  final Map<String, String> args;

  /// enum `notifications.type`: tribe_join, group_schedule, reminder, tribe_role...
  final String type;
  final String? tribeId;
  final String? referenceId;
  final String? referenceType;
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
    DateTime? createdAt,
    this.isUnread = true,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Lời mời tham gia hoạt động -> hiện nút Tham gia / Không tham gia.
  bool get isAttendanceRequest =>
      kind == NotificationKind.tribeNewBlock ||
      kind == NotificationKind.tribeBlockRescheduled;
}
