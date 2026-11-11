import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session.dart';
import '../models/app_notification.dart';

/// Bộ lọc thông báo: tất cả, cá nhân, hoặc theo id của một nhóm.
class NotificationFilter {
  static const all = 'all';
  static const personal = 'personal';
}

class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel({ApiClient? api}) : _api = api ?? ApiClient.instance;

  /// Chỉ hiển thị thông báo trong vòng 30 ngày gần nhất.
  static const Duration retention = Duration(days: 30);

  final ApiClient _api;
  final List<AppNotification> _all = [];
  bool _isLoading = false;
  String _filter = NotificationFilter.all;

  /// Đang tải thông báo hay không.
  bool get isLoading => _isLoading;

  /// Chip lọc đang chọn: all, personal hoặc id nhóm.
  String get selectedFilter => _filter;

  /// Thông báo trong 30 ngày gần nhất, mới nhất lên đầu.
  List<AppNotification> get _recent {
    final cutoff = DateTime.now().subtract(retention);
    return _all.where((n) => n.createdAt.isAfter(cutoff)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Danh sách theo bộ lọc đang chọn.
  List<AppNotification> get filteredNotifications => switch (_filter) {
    NotificationFilter.all => _recent,
    NotificationFilter.personal =>
      _recent.where((n) => n.tribeId == null).toList(),
    _ => _recent.where((n) => n.tribeId == _filter).toList(),
  };

  /// Tổng số thông báo chưa đọc (số trên huy hiệu đỏ).
  int get unreadCount => _recent.where((n) => n.isUnread).length;

  /// Số chưa đọc của từng chip lọc.
  int unreadCountFor(String filter) => switch (filter) {
    NotificationFilter.all => unreadCount,
    NotificationFilter.personal =>
      _recent.where((n) => n.tribeId == null && n.isUnread).length,
    _ => _recent.where((n) => n.tribeId == filter && n.isUnread).length,
  };

  /// Đổi chip lọc.
  void setFilter(String filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  /// NOTI-01: tải thông báo 30 ngày gần nhất từ server.
  /// silent = true thì không hiện vòng tải (dùng khi có thông báo đẩy mới tới).
  Future<void> load({bool silent = false}) async {
    if (Session.currentUserId.isEmpty) return;
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final data = await _api.get('/notifications');
      _all
        ..clear()
        ..addAll([for (final j in data as List) AppNotification.fromJson(j)]);
    } on ApiException catch (e) {
      debugPrint('tải thông báo lỗi: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// NOTI-02: đánh dấu đã đọc một thông báo. Đổi trên máy trước cho nhanh rồi mới gọi server.
  /// Thông báo chung của admin cũng gửi lên: server ghi nhận riêng cho từng người (read_by).
  Future<void> markAsRead(String id) async {
    for (final n in _all) {
      if (n.id == id && n.isUnread) {
        n.isUnread = false;
        notifyListeners();
        try {
          await _api.patch('/notifications/$id/read');
        } on ApiException catch (e) {
          debugPrint('đánh dấu đã đọc lỗi: $e');
        }
        return;
      }
    }
  }

  /// NOTI-02: đánh dấu đọc tất cả.
  Future<void> markAllAsRead() async {
    for (final n in _all) {
      n.isUnread = false;
    }
    notifyListeners();
    try {
      await _api.patch('/notifications/read-all');
    } on ApiException catch (e) {
      debugPrint('đánh dấu đọc tất cả lỗi: $e');
    }
  }

  /// Xoá hết thông báo trên máy khi đăng xuất.
  void clear() {
    _all.clear();
    _filter = NotificationFilter.all;
    notifyListeners();
  }
}
