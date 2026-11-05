import 'package:flutter/material.dart';

class HomeViewModel extends ChangeNotifier {
  // Các mục trong menu (Drawer)
  static const int personal = 0;
  static const int tribes = 1;
  static const int templates = 2;

  // Bottom Navigation (mặc định tab 1 - Trang chủ)
  int _currentTabIndex = 1;
  int get currentTabIndex => _currentTabIndex;

  int _currentDrawerIndex = personal;
  int get currentDrawerIndex => _currentDrawerIndex;

  void changeTab(int index) {
    if (_currentTabIndex == index) return;
    _currentTabIndex = index;
    notifyListeners();
  }

  void changeDrawerSubFeature(int drawerIndex) {
    _currentDrawerIndex = drawerIndex;
    _currentTabIndex = 1; // Luôn quay về tab Trang chủ
    notifyListeners();
  }
}
