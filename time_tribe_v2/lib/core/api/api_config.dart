import 'package:flutter/foundation.dart';

/// Địa chỉ backend.
///
/// Mặc định:
/// - máy ảo Android gọi về máy tính qua 10.0.2.2
/// - web, desktop, máy ảo iOS dùng localhost
///
/// Chạy trên điện thoại thật thì truyền IP máy tính đang chạy backend, ví dụ:
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api/v1
class ApiConfig {
  ApiConfig._();

  static const String _fromEnv = String.fromEnvironment('API_BASE_URL');

  /// Trả về địa chỉ API đang dùng, ưu tiên giá trị truyền bằng --dart-define.
  static String get baseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // return 'http://10.0.2.2:8080/api/v1';
      return 'http://172.31.11.68:8080/api/v1';      
    }
    return 'http://localhost:8080/api/v1';
  }
}
