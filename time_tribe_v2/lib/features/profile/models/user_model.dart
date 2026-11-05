class UserModel {
  final String id;
  final String email;
  final String nickName;
  final String? avatarUrl;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.nickName,
    this.avatarUrl,
    this.timezone = 'Asia/Ho_Chi_Minh',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nickName: json['nick_name'] ?? '',
      avatarUrl: json['avatar_url'],
      timezone: json['timezone'] ?? 'Asia/Ho_Chi_Minh',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nick_name': nickName,
      'avatar_url': avatarUrl,
      'timezone': timezone,
    };
  }
}
