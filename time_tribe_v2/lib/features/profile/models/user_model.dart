/// Hồ sơ của chính người dùng: bảng users + vài cột của user_securities mà /users/me trả về.
class UserModel {
  final String id;
  final String email;
  final String nickName;
  final String? avatarUrl;
  final String timezone;
  final String? fcmToken;
  final String role;
  final String authProvider;
  final bool hasPassword;

  /// Tài khoản mới tạo, chưa xem màn hình chào mừng / hướng dẫn.
  final bool needsOnboarding;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.nickName,
    this.avatarUrl,
    this.timezone = 'Asia/Ho_Chi_Minh',
    this.fcmToken,
    this.role = 'customer',
    this.authProvider = 'local',
    this.hasPassword = true,
    this.needsOnboarding = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Đọc JSON backend trả về, tên khoá giống cột trong database (snake_case).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nickName: json['nick_name'] ?? '',
      avatarUrl: json['avatar_url'],
      timezone: json['timezone'] ?? 'Asia/Ho_Chi_Minh',
      fcmToken: json['fcm_token'],
      role: json['role'] ?? 'customer',
      authProvider: json['auth_provider'] ?? 'local',
      hasPassword: json['has_password'] ?? true,
      needsOnboarding: json['needs_onboarding'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// Đổi sang JSON (dùng khi cần lưu tạm hoặc gửi lại một phần thông tin).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nick_name': nickName,
      'avatar_url': avatarUrl,
      'timezone': timezone,
      'fcm_token': fcmToken,
    };
  }
}
