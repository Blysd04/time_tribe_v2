import 'package:flutter/material.dart';

import '../models/app_notification.dart';

/// Bộ lọc thông báo: tất cả, cá nhân, hoặc theo id của một nhóm.
class NotificationFilter {
  static const all = 'all';
  static const personal = 'personal';
}

class NotificationViewModel extends ChangeNotifier {
  /// Chỉ hiển thị thông báo trong vòng 30 ngày gần nhất.
  static const Duration retention = Duration(days: 30);

  final List<AppNotification> _all = [];
  bool _isLoading = true;
  String _filter = NotificationFilter.all;

  bool get isLoading => _isLoading;
  String get selectedFilter => _filter;

  NotificationViewModel({bool loadMock = true}) {
    if (loadMock) {
      loadMockData();
    } else {
      _isLoading = false;
    }
  }

  List<AppNotification> get _recent {
    final cutoff = DateTime.now().subtract(retention);
    return _all.where((n) => n.createdAt.isAfter(cutoff)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<AppNotification> get filteredNotifications => switch (_filter) {
    NotificationFilter.all => _recent,
    NotificationFilter.personal =>
      _recent.where((n) => n.tribeId == null).toList(),
    _ => _recent.where((n) => n.tribeId == _filter).toList(),
  };

  int get unreadCount => _recent.where((n) => n.isUnread).length;

  int unreadCountFor(String filter) => switch (filter) {
    NotificationFilter.all => unreadCount,
    NotificationFilter.personal =>
      _recent.where((n) => n.tribeId == null && n.isUnread).length,
    _ => _recent.where((n) => n.tribeId == filter && n.isUnread).length,
  };

  void setFilter(String filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  void markAsRead(String id) {
    for (final n in _all) {
      if (n.id == id && n.isUnread) {
        n.isUnread = false;
        notifyListeners();
        return;
      }
    }
  }

  void markAllAsRead() {
    for (final n in _all) {
      n.isUnread = false;
    }
    notifyListeners();
  }

  void push(AppNotification notification) {
    _all.insert(0, notification);
    notifyListeners();
  }

  void clear() {
    _all.clear();
    notifyListeners();
  }

  // TODO(backend): GET /notifications?since=<30 ngày trước>
  void loadMockData() {
    Future.delayed(const Duration(milliseconds: 500), () {
      final now = DateTime.now();
      _all.addAll([
        AppNotification(
          id: 'mock-personal-1',
          kind: NotificationKind.personalBlockAdded,
          args: const {'task': 'Tập Gym', 'time': '17:30'},
          type: 'reminder',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        // Thông báo quá 30 ngày -> sẽ không hiển thị
        AppNotification(
          id: 'mock-personal-old',
          kind: NotificationKind.personalBlockAdded,
          args: const {'task': 'Họp lớp', 'time': '09:00'},
          type: 'reminder',
          createdAt: now.subtract(const Duration(days: 45)),
          isUnread: false,
        ),
      ]);
      _isLoading = false;
      notifyListeners();
    });
  }
}
