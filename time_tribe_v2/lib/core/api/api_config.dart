import 'package:flutter/foundation.dart';

/// Địa chỉ backend.
///
/// Thứ tự ưu tiên:
/// 1. Giá trị truyền khi build: --dart-define=API_BASE_URL=https://.../api/v1
/// 2. Bản release (APK phát hành): server Render [productionUrl]
/// 3. Bản debug: máy ảo Android gọi về máy tính qua 10.0.2.2, nền tảng khác dùng localhost
///
/// Build APK phát hành:
/// flutter build apk --release --dart-define=API_BASE_URL=https://timetribe-api.onrender.com/api/v1
///
/// Chạy debug trên điện thoại thật thì truyền IP máy tính đang chạy backend, ví dụ:
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api/v1
class ApiConfig {
  ApiConfig._();

  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  /// Domain Render cấp cho backend. Đổi lại cho đúng sau khi deploy.
  static const String productionUrl =
      'https://timetribe.onrender.com/api/v1';

  /// Trả về địa chỉ API đang dùng.
  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    if (kReleaseMode) return productionUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // return 'http://10.0.2.2:8080/api/v1';
      return 'https://timetribe.onrender.com/api/v1';
      // return 'http://172.31.11.70:8080/api/v1';
    }
    // return 'http://localhost:8080/api/v1';
      return 'https://timetribe.onrender.com/api/v1';
  }
}
