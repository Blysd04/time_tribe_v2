import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'push_service.dart';

/// Kết quả đăng nhập Google phía app.
enum GoogleSignInStatus { success, cancelled, unsupported, failed }

/// Đăng nhập Google qua Firebase Auth rồi lấy Firebase ID token để gửi lên backend.
class GoogleAuthService {
  GoogleAuthService._();

  /// Web client id (client_type 3 trong google-services.json). Google cần id này
  /// để cấp idToken mà Firebase chấp nhận.
  static const _serverClientId =
      '580239912545-1mm1db31j934q3mmf430p65rqufktueu.apps.googleusercontent.com';

  static bool _initialized = false;

  /// Mở hộp chọn tài khoản Google. Thành công thì trả kèm Firebase ID token.
  static Future<({GoogleSignInStatus status, String? idToken})> signIn() async {
    if (!PushService.isReady) {
      return (status: GoogleSignInStatus.unsupported, idToken: null);
    }
    try {
      final google = GoogleSignIn.instance;
      if (!_initialized) {
        await google.initialize(serverClientId: _serverClientId);
        _initialized = true;
      }
      final account = await google.authenticate();
      final googleIdToken = account.authentication.idToken;
      if (googleIdToken == null) {
        return (status: GoogleSignInStatus.failed, idToken: null);
      }
      final cred = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: googleIdToken),
      );
      final idToken = await cred.user?.getIdToken();
      if (idToken == null) {
        return (status: GoogleSignInStatus.failed, idToken: null);
      }
      return (status: GoogleSignInStatus.success, idToken: idToken);
    } on GoogleSignInException catch (e) {
      final cancelled = e.code == GoogleSignInExceptionCode.canceled;
      return (
        status: cancelled
            ? GoogleSignInStatus.cancelled
            : GoogleSignInStatus.failed,
        idToken: null,
      );
    } catch (_) {
      return (status: GoogleSignInStatus.failed, idToken: null);
    }
  }

  /// Thoát tài khoản Google trên máy để lần sau được chọn lại tài khoản khác.
  static Future<void> signOut() async {
    if (!PushService.isReady) return;
    try {
      await FirebaseAuth.instance.signOut();
      if (_initialized) await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
