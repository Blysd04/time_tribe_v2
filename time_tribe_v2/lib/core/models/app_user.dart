/// Thông tin người dùng rút gọn, bảng `users`.
class AppUser {
  final String id;
  final String nickName;
  final String? avatarUrl;

  /// Múi giờ IANA của người dùng (`users.timezone`).
  final String timezone;

  const AppUser({
    required this.id,
    required this.nickName,
    this.avatarUrl,
    this.timezone = 'Asia/Ho_Chi_Minh',
  });

  /// Chữ cái đầu của tên để hiện khi chưa có ảnh đại diện, ví dụ Tuyết Nga -> TN.
  String get initials {
    final parts = nickName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Đọc thông tin rút gọn của một người từ JSON backend.
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] ?? '',
    nickName: json['nick_name'] ?? '',
    avatarUrl: json['avatar_url'],
    timezone: json['timezone'] ?? 'Asia/Ho_Chi_Minh',
  );
}
