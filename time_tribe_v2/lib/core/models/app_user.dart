/// Thông tin người dùng rút gọn — bảng `users`.
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

  String get initials {
    final parts = nickName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] ?? '',
    nickName: json['nick_name'] ?? '',
    avatarUrl: json['avatar_url'],
    timezone: json['timezone'] ?? 'Asia/Ho_Chi_Minh',
  );
}
