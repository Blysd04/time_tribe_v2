import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

  /// Android không tự hiện thông báo đẩy khi app đang mở, nên gọi hàm này để app
  /// tự hiện banner trong app (tiêu đề, nội dung). iOS đã có banner hệ thống.
  static void Function(String title, String body)? onForeground;

  /// Người dùng bấm vào một thông báo (app đang chạy hoặc vừa được mở từ thông báo).
  static void Function()? onOpenNotifications;

  /// Kênh sang MainActivity.kt: hiện thông báo hệ thống khi app đang mở.
  static const _native = MethodChannel('timetribe/notify');

  static bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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
      if (_android) {
        _native.setMethodCallHandler((call) async {
          if (call.method == 'openNotifications') onOpenNotifications?.call();
        });
      }
      FirebaseMessaging.onMessage.listen((m) {
        onMessage?.call();
        final n = m.notification;
        if (n != null && _android) {
          // Firebase không tự hiện thông báo khi app đang mở: tự hiện ra thanh thông báo
          // (giống lúc app chạy nền), kèm banner trong app.
          _native
              .invokeMethod('show', {'title': n.title ?? '', 'body': n.body ?? ''})
              .catchError((_) => null);
          onForeground?.call(n.title ?? '', n.body ?? '');
        }
      });
      // Bấm vào thông báo FCM lúc app chạy nền -> mở tab Thông báo
      FirebaseMessaging.onMessageOpenedApp.listen((_) {
        onMessage?.call();
        onOpenNotifications?.call();
      });
      // iOS: vẫn hiện banner hệ thống khi app đang mở
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
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

  /// App vừa được mở bằng cách bấm vào thông báo (lúc app đã tắt hẳn) hay không.
  static Future<bool> launchedFromNotification() async {
    if (!_ready) return false;
    try {
      if (await FirebaseMessaging.instance.getInitialMessage() != null) {
        return true;
      }
      if (_android) {
        return await _native.invokeMethod<bool>('launchedFromNotification') ??
            false;
      }
    } catch (_) {}
    return false;
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
        const Duration(seconds: 15),
      );
    } catch (_) {
      return null;
    }
  }
}
