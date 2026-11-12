import '../../features/profile/models/user_model.dart';

/// Thông tin người đang đăng nhập, gán lúc đăng nhập xong và xoá khi đăng xuất.
class Session {
  Session._();

  /// id của người đang đăng nhập (users.id), chuỗi rỗng là chưa đăng nhập.
  static String currentUserId = '';

  /// Hồ sơ đầy đủ lấy từ backend (/users/me hoặc kết quả đăng nhập).
  static UserModel? currentUser;

  /// Lưu người dùng hiện tại sau khi đăng nhập hoặc tải lại hồ sơ.
  static void start(UserModel user) {
    currentUser = user;
    currentUserId = user.id;
  }

  /// Xoá thông tin người dùng khỏi bộ nhớ khi đăng xuất.
  static void clear() {
    currentUser = null;
    currentUserId = '';
  }
}
