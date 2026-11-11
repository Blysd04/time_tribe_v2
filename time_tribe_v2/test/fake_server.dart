import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:time_tribe_v2/core/api/api_client.dart';
import 'package:time_tribe_v2/core/session/session.dart';
import 'package:time_tribe_v2/features/profile/models/user_model.dart';

/// Lỗi giả lập server trả về, giống dạng {"success": false, "error": {...}} của backend Go.
class FakeError implements Exception {
  final int status;
  final String code;
  final Object? details;
  const FakeError(this.status, this.code, [this.details]);
}

/// Server giả cho test: khai báo từng API bằng on(), mọi request đi qua ApiClient thật
/// nên test được cả phần đọc JSON, gắn token, đổi mã lỗi.
class FakeServer {
  final _routes = <(String, RegExp, Object? Function(http.Request))>[];

  /// Danh sách request đã gọi, dạng "POST /tribes".
  final calls = <String>[];

  /// Body JSON của request gần nhất theo từng đường dẫn.
  final lastBody = <String, dynamic>{};

  /// Khai báo một API. Dấu * trong path khớp một đoạn bất kỳ (ví dụ /tribes/*/blocks).
  void on(
    String method,
    String path,
    Object? Function(http.Request req) handler,
  ) {
    final pattern = RegExp(
      '^${RegExp.escape(path).replaceAll(r'\*', '[^/]+')}\$',
    );
    _routes.insert(0, (method, pattern, handler));
  }

  /// Tạo ApiClient dùng server giả này.
  ApiClient client() =>
      ApiClient(httpClient: MockClient(_handle), baseUrl: 'http://fake/api/v1')
        ..setTokens('access', 'refresh', persist: false);

  Future<http.Response> _handle(http.Request req) async {
    final path = req.url.path.replaceFirst('/api/v1', '');
    calls.add('${req.method} $path');
    if (req.body.isNotEmpty) lastBody[path] = jsonDecode(req.body);
    for (final (method, pattern, handler) in _routes) {
      if (method != req.method || !pattern.hasMatch(path)) continue;
      try {
        final data = handler(req);
        return _json(200, {'success': true, 'message': '', 'data': data});
      } on FakeError catch (e) {
        return _json(e.status, {
          'success': false,
          'error': {'code': e.code, 'message': e.code, 'details': e.details},
        });
      }
    }
    return _json(404, {
      'success': false,
      'error': {'code': 'not_found', 'message': 'route $path'},
    });
  }

  http.Response _json(int status, Object body) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

/// Đăng nhập giả: gán người dùng hiện tại là "u-me" (Tuyết Nga, giờ Việt Nam).
void signInAsMe() {
  Session.start(
    UserModel(
      id: 'u-me',
      email: 'tuyetnga@timetribe.app',
      nickName: 'Tuyết Nga',
      createdAt: DateTime(2026, 1, 1),
    ),
  );
}

/// JSON một thành viên nhóm.
Map<String, dynamic> memberJson(
  String tribeId,
  String userId,
  String name,
  String role, {
  String timezone = 'Asia/Ho_Chi_Minh',
}) => {
  'id': '$tribeId-$userId',
  'tribe_id': tribeId,
  'user_id': userId,
  'role': role,
  'joined_at': '2026-10-01T00:00:00Z',
  'user': {
    'id': userId,
    'nick_name': name,
    'avatar_url': null,
    'timezone': timezone,
  },
};

/// JSON một nhóm kèm danh sách thành viên.
Map<String, dynamic> tribeJson(
  String id,
  String name,
  String code,
  List<Map<String, dynamic>> members,
) => {
  'id': id,
  'name': name,
  'created_by': members.first['user_id'],
  'invite_code': code,
  'created_at': '2026-10-01T00:00:00Z',
  'deleted_at': null,
  'members': members,
};

/// JSON một hoạt động nhóm, giờ theo UTC, attendance là map userId -> trạng thái.
Map<String, dynamic> blockJson(
  String id,
  String tribeId,
  String task,
  DateTime startUtc,
  DateTime endUtc,
  Map<String, String> attendance, {
  String createdBy = 'u-me',
}) => {
  'id': id,
  'tribe_id': tribeId,
  'created_by': createdBy,
  'task': task,
  'description': null,
  'start_utc': startUtc.toUtc().toIso8601String(),
  'end_utc': endUtc.toUtc().toIso8601String(),
  'color_code': '#3A86FF',
  'remind': 60,
  'created_at': '2026-10-01T00:00:00Z',
  'attendance': [
    for (final e in attendance.entries)
      {
        'id': '$id-${e.key}',
        'tribe_block_id': id,
        'user_id': e.key,
        'status': e.value,
        'updated_at': '2026-10-01T00:00:00Z',
      },
  ],
};
