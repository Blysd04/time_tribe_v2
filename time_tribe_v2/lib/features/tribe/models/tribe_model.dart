import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';

export '../../../core/models/app_user.dart';

/// Chức vụ trong nhóm — enum `tribe_attendees.role`.
enum TribeRole {
  leader('leader'),
  viceLeader('vice_leader'),
  member('member');

  final String value;
  const TribeRole(this.value);

  static TribeRole fromValue(String? value) => TribeRole.values.firstWhere(
    (r) => r.value == value,
    orElse: () => TribeRole.member,
  );

  /// Trưởng/phó nhóm được tạo, sửa, xoá hoạt động nhóm.
  bool get canManageBlocks => this != TribeRole.member;
}

/// Một dòng của `tribe_attendees`, kèm thông tin user để hiển thị.
class TribeMember {
  final String id;
  final String tribeId;
  final AppUser user;
  final TribeRole role;
  final DateTime joinedAt;

  TribeMember({
    required this.id,
    required this.tribeId,
    required this.user,
    this.role = TribeRole.member,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  String get userId => user.id;

  TribeMember copyWith({TribeRole? role}) => TribeMember(
    id: id,
    tribeId: tribeId,
    user: user,
    role: role ?? this.role,
    joinedAt: joinedAt,
  );

  factory TribeMember.fromJson(Map<String, dynamic> json) => TribeMember(
    id: json['id'] ?? '',
    tribeId: json['tribe_id'] ?? '',
    user: AppUser.fromJson(json['user'] ?? {'id': json['user_id']}),
    role: TribeRole.fromValue(json['role']),
    joinedAt: json['joined_at'] != null
        ? DateTime.parse(json['joined_at'])
        : null,
  );
}

/// Bảng `tribes` + danh sách thành viên.
class TribeModel {
  final String id;
  final String name;
  final String createdBy;
  final String inviteCode;
  final String inviteLink;
  final String? backgroundColor;
  final String? backgroundImageUrl;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final List<TribeMember> members;

  TribeModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.inviteCode,
    String? inviteLink,
    this.backgroundColor,
    this.backgroundImageUrl,
    DateTime? createdAt,
    this.deletedAt,
    this.members = const [],
  }) : inviteLink = inviteLink ?? 'https://timetribe.app/tribe/$inviteCode',
       createdAt = createdAt ?? DateTime.now();

  Color get color => backgroundColor == null
      ? const Color(0xFF3A86FF)
      : Color(int.parse(backgroundColor!.replaceAll('#', '0xFF')));

  TribeMember? get leader {
    for (final m in members) {
      if (m.role == TribeRole.leader) return m;
    }
    return null;
  }

  List<TribeMember> get viceLeaders =>
      members.where((m) => m.role == TribeRole.viceLeader).toList();

  TribeMember? memberOf(String userId) {
    for (final m in members) {
      if (m.userId == userId) return m;
    }
    return null;
  }

  TribeRole? roleOf(String userId) => memberOf(userId)?.role;

  /// Thành viên sắp theo thứ tự: trưởng nhóm -> phó nhóm -> thành viên.
  List<TribeMember> get sortedMembers {
    final list = members.toList();
    list.sort((a, b) {
      final byRole = a.role.index.compareTo(b.role.index);
      return byRole != 0 ? byRole : a.joinedAt.compareTo(b.joinedAt);
    });
    return list;
  }

  TribeModel copyWith({
    String? name,
    String? backgroundColor,
    String? backgroundImageUrl,
    bool clearBackgroundImage = false,
    List<TribeMember>? members,
    DateTime? deletedAt,
  }) => TribeModel(
    id: id,
    name: name ?? this.name,
    createdBy: createdBy,
    inviteCode: inviteCode,
    inviteLink: inviteLink,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundImageUrl: clearBackgroundImage
        ? null
        : (backgroundImageUrl ?? this.backgroundImageUrl),
    createdAt: createdAt,
    deletedAt: deletedAt ?? this.deletedAt,
    members: members ?? this.members,
  );

  factory TribeModel.fromJson(Map<String, dynamic> json) => TribeModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    createdBy: json['created_by'] ?? '',
    inviteCode: json['invite_code'] ?? '',
    inviteLink: json['invite_link'],
    backgroundColor: json['background_color'],
    backgroundImageUrl: json['background_image_url'],
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : null,
    deletedAt: json['deleted_at'] != null
        ? DateTime.parse(json['deleted_at'])
        : null,
    members: (json['members'] as List? ?? [])
        .map((m) => TribeMember.fromJson(m))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'created_by': createdBy,
    'invite_code': inviteCode,
    'invite_link': inviteLink,
    'background_color': backgroundColor,
    'background_image_url': backgroundImageUrl,
  };
}
