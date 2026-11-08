import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Thông báo đẩy qua Firebase Cloud Messaging.
///
/// Chỉ bật trên Android và iOS (file google-services.json mới có cấu hình cho Android).
/// Trên web hoặc desktop thì mọi hàm đều không làm gì, app vẫn chạy bình thường.
class PushService {
  PushService._();

  static bool _ready = false;

  /// Có dùng được Firebase trên máy này không.
  static bool get isReady => _ready;

  /// Mỗi khi có thông báo mới lúc app đang mở thì gọi hàm này (để tải lại danh sách).
  static void Function()? onMessage;

  /// Gọi khi Firebase cấp mã FCM mới, app cần gửi mã mới lên server.
  static void Function(String token)? onTokenRefresh;

  /// Khởi tạo Firebase một lần lúc mở app. Lỗi thì bỏ qua, chỉ tắt thông báo đẩy.
  static Future<void> init() async {
    final mobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (!mobile) return;
    try {
      await Firebase.initializeApp();
      _ready = true;
      FirebaseMessaging.onMessage.listen((_) => onMessage?.call());
      FirebaseMessaging.onMessageOpenedApp.listen((_) => onMessage?.call());
      // Bản firebase_messaging 17 khuyên dùng onRegistered (trả Firebase Installation ID),
      // nhưng Firebase Admin SDK bên backend Go đang gửi theo registration token,
      // nên vẫn dùng onTokenRefresh / getToken cho hai bên khớp nhau.
      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (t) => onTokenRefresh?.call(t),
      );
    } catch (e) {
      debugPrint('không khởi tạo được Firebase: $e');
    }
  }

  /// Xin quyền hiện thông báo (Android 13 trở lên và iOS bắt buộc phải hỏi).
  static Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {}
  }

  /// Lấy mã FCM của máy để gửi kèm khi đăng nhập. Không có thì trả null.
  static Future<String?> getToken() async {
    if (!_ready) return null;
    try {
      // ignore: deprecated_member_use
      return await FirebaseMessaging.instance.getToken().timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {
      return null;
    }
  }
}
