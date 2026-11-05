class NotificationModel {
  final String id;
  final String? userId;
  final String? createdBy;
  final String title;
  final String content;
  final String type;
  final String? referenceId;
  final String? referenceType;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    this.userId,
    this.createdBy,
    required this.title,
    required this.content,
    required this.type,
    this.referenceId,
    this.referenceType,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'],
      createdBy: json['created_by'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'system_broadcast',
      referenceId: json['reference_id'],
      referenceType: json['reference_type'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
