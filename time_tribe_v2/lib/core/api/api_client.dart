import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

/// Lỗi trả về từ backend, dạng {"success": false, "error": {"code", "message", "details"}}.
/// code khớp với mã lỗi bên Go (wrong_credentials, overlap, tribe_limit...).
class ApiException implements Exception {
  final int status;
  final String code;
  final String message;
  final dynamic details;

  const ApiException(this.status, this.code, this.message, [this.details]);

  /// Lỗi do không gọi được server (mất mạng, server chưa bật).
  bool get isNetwork => code == 'network_error';

  /// In lỗi ra cho dễ đọc khi debug.
  @override
  String toString() => 'ApiException($status, $code, $message)';
}

/// Những mã lỗi nghĩa là phiên đăng nhập đã hết, phải quay về màn hình đăng nhập.
const _sessionEndedCodes = {
  'session_ended',
  'token_revoked',
  'invalid_refresh_token',
  'account_deleted',
  'account_banned',
  'missing_token',
};

/// Lớp gọi API dùng chung cho cả app.
///
/// - tự gắn header `Authorization: Bearer <access_token>`
/// - access token hết hạn thì tự gọi /auth/refresh rồi gửi lại request một lần
/// - phiên bị kết thúc (đăng nhập ở máy khác, đổi mật khẩu...) thì xoá token và báo
///   ra ngoài qua [onSessionEnded] để app đưa người dùng về màn hình đăng nhập
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
    : _http = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Bản dùng chung cho cả app. Test có thể gán một bản khác (dùng MockClient).
  static ApiClient instance = ApiClient();

  static const _kAccess = 'auth.access_token';
  static const _kRefresh = 'auth.refresh_token';

  final http.Client _http;
  final String _baseUrl;

  String? _accessToken;
  String? _refreshToken;
  Future<bool>? _refreshing;

  /// Gọi khi phiên đăng nhập kết thúc, tham số là mã lỗi server trả về.
  void Function(String code)? onSessionEnded;

  /// Đang có access token (đã đăng nhập) hay chưa.
  bool get hasSession => _accessToken != null;

  /// Đọc token đã lưu trên máy (chỉ có khi lần trước người dùng chọn ghi nhớ đăng nhập).
  Future<void> loadTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_kAccess);
      _refreshToken = prefs.getString(_kRefresh);
    } catch (_) {
      // Không đọc được bộ nhớ thì coi như chưa đăng nhập
    }
  }

  /// Giữ token sau khi đăng nhập. persist = false thì chỉ giữ trong bộ nhớ,
  /// tắt app là phải đăng nhập lại (trường hợp không chọn ghi nhớ đăng nhập).
  Future<void> setTokens(
    String access,
    String refresh, {
    bool persist = true,
  }) async {
    _accessToken = access;
    _refreshToken = refresh;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (persist) {
        await prefs.setString(_kAccess, access);
        await prefs.setString(_kRefresh, refresh);
      } else {
        await prefs.remove(_kAccess);
        await prefs.remove(_kRefresh);
      }
    } catch (_) {}
  }

  /// Xoá token trong bộ nhớ và trên máy (đăng xuất, phiên hết hạn).
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAccess);
      await prefs.remove(_kRefresh);
    } catch (_) {}
  }

  /// Gọi GET, query là các tham số trên URL.
  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  /// Gọi POST với body JSON.
  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  /// Gọi PUT với body JSON.
  Future<dynamic> put(String path, [Object? body]) =>
      _send('PUT', path, body: body);

  /// Gọi PATCH với body JSON.
  Future<dynamic> patch(String path, [Object? body]) =>
      _send('PATCH', path, body: body);

  /// Gọi DELETE, một số API (xoá tài khoản) cần gửi kèm body.
  Future<dynamic> delete(String path, [Object? body]) =>
      _send('DELETE', path, body: body);

  /// Tải file lên dạng multipart/form-data (dùng cho ảnh đại diện).
  Future<dynamic> upload(
    String path,
    String field,
    List<int> bytes,
    String filename,
  ) async {
    Future<http.Response> run() async {
      final req = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll(_headers(json: false))
        ..files.add(
          http.MultipartFile.fromBytes(field, bytes, filename: filename),
        );
      return http.Response.fromStream(await _http.send(req));
    }

    return _handle(await _guard(run), () async => _guard(run));
  }

  /// Ghép địa chỉ server với đường dẫn API và tham số trên URL.
  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl$path');
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: query);
  }

  /// Header gửi kèm mỗi request: kiểu JSON và token đăng nhập.
  Map<String, String> _headers({bool json = true}) => {
    if (json) 'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  /// Bọc lỗi mạng thành ApiException để chỗ gọi chỉ cần bắt một loại lỗi.
  Future<http.Response> _guard(Future<http.Response> Function() run) async {
    try {
      return await run().timeout(const Duration(seconds: 20));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        0,
        'network_error',
        'Không kết nối được máy chủ',
      );
    }
  }

  /// Gửi một request JSON và xử lý kết quả (kể cả tự làm mới token).
  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    Future<http.Response> run() {
      final req = http.Request(method, _uri(path, query))
        ..headers.addAll(_headers());
      if (body != null) req.body = jsonEncode(body);
      return _http.send(req).then(http.Response.fromStream);
    }

    return _handle(await _guard(run), () => _guard(run));
  }

  /// Đọc kết quả. Gặp invalid_token thì thử làm mới token rồi gửi lại đúng một lần.
  Future<dynamic> _handle(
    http.Response res,
    Future<http.Response> Function() retry,
  ) async {
    var decoded = _decode(res);
    if (res.statusCode == 401 &&
        decoded.code == 'invalid_token' &&
        _refreshToken != null &&
        await _refresh()) {
      res = await retry();
      decoded = _decode(res);
    }
    if (decoded.error == null) return decoded.data;

    final err = decoded.error!;
    if (_sessionEndedCodes.contains(err.code) && _accessToken != null) {
      await clearTokens();
      onSessionEnded?.call(err.code);
    }
    throw err;
  }

  /// Đọc body JSON của server: thành công thì lấy data, thất bại thì tạo ApiException.
  ({dynamic data, ApiException? error, String? code}) _decode(
    http.Response res,
  ) {
    Map<String, dynamic> map;
    try {
      map = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      final e = ApiException(
        res.statusCode,
        'bad_response',
        'Máy chủ trả về dữ liệu không đọc được',
      );
      return (data: null, error: e, code: e.code);
    }
    if (map['success'] == true) {
      return (data: map['data'], error: null, code: null);
    }
    final e = map['error'] as Map<String, dynamic>? ?? const {};
    final err = ApiException(
      res.statusCode,
      e['code']?.toString() ?? 'unknown',
      e['message']?.toString() ?? '',
      e['details'],
    );
    return (data: null, error: err, code: err.code);
  }

  /// Đổi refresh token lấy access token mới. Nhiều request cùng hết hạn một lúc
  /// thì chỉ gọi /auth/refresh một lần, các request kia chờ chung kết quả.
  Future<bool> _refresh() {
    return _refreshing ??= () async {
      try {
        final res = await _http.post(
          _uri('/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': _refreshToken}),
        );
        final decoded = _decode(res);
        if (decoded.error != null) return false;
        final data = decoded.data as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        final persist = prefs.getString(_kRefresh) != null;
        await setTokens(
          data['access_token'],
          data['refresh_token'],
          persist: persist,
        );
        return true;
      } catch (_) {
        return false;
      } finally {
        _refreshing = null;
      }
    }();
  }
}
