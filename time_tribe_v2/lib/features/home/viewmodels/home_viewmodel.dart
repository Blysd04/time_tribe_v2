import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  // Các mục trong menu (Drawer)
  static const int personal = 0;
  static const int tribes = 1;
  static const int templates = 2;

  // Bottom Navigation (mặc định tab 1 - Trang chủ)
  int _currentTabIndex = 1;

  /// Tab đang mở ở thanh điều hướng dưới.
  int get currentTabIndex => _currentTabIndex;

  int _currentDrawerIndex = personal;

  /// Mục đang chọn trong menu bên trái.
  int get currentDrawerIndex => _currentDrawerIndex;

  /// Bấm một tab ở thanh điều hướng dưới.
  void changeTab(int index) {
    if (_currentTabIndex == index) return;
    _currentTabIndex = index;
    notifyListeners();
  }

  /// Chọn một mục trong menu bên trái (Lịch cá nhân, Nhóm, Lịch mẫu).
  void changeDrawerSubFeature(int drawerIndex) {
    _currentDrawerIndex = drawerIndex;
    _currentTabIndex = 1; // Luôn quay về tab Trang chủ
    notifyListeners();
  }

  /// Về trạng thái ban đầu khi đăng xuất.
  void reset() {
    _currentTabIndex = 1;
    _currentDrawerIndex = personal;
    notifyListeners();
  }
}
