import 'package:flutter/material.dart';

import '../../../core/models/app_user.dart';
import '../../../core/theme/app_theme.dart';

export '../../../core/models/app_user.dart';

/// Chức vụ trong nhóm, enum tribe_attendees.role.
enum TribeRole {
  leader('leader'),
  viceLeader('vice_leader'),
  member('member');

  final String value;
  const TribeRole(this.value);

  /// Đổi chuỗi trong JSON thành enum, giá trị lạ thì coi như thành viên.
  static TribeRole fromValue(String? value) => TribeRole.values.firstWhere(
    (r) => r.value == value,
    orElse: () => TribeRole.member,
  );

  /// Trưởng/phó nhóm được tạo, sửa, xoá hoạt động nhóm.
  bool get canManageBlocks => this != TribeRole.member;
}

/// Một dòng của tribe_attendees, kèm thông tin user để hiển thị.
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

  /// id của người dùng ứng với dòng thành viên này.
  String get userId => user.id;

  /// Tạo bản sao với chức vụ mới.
  TribeMember copyWith({TribeRole? role}) => TribeMember(
    id: id,
    tribeId: tribeId,
    user: user,
    role: role ?? this.role,
    joinedAt: joinedAt,
  );

  /// Đọc một dòng tribe_attendees kèm thông tin user từ JSON.
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

/// Bảng tribes kèm danh sách thành viên.
class TribeModel {
  final String id;
  final String name;
  final String createdBy;

  /// Mã mời (invite_code), người khác gõ mã này để vào nhóm.
  final String inviteCode;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final List<TribeMember> members;

  TribeModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.inviteCode,
    DateTime? createdAt,
    this.deletedAt,
    this.members = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  /// Màu đại diện của nhóm, sinh cố định theo id nên mỗi nhóm luôn một màu.
  Color get color => AppColors.seeded(id);

  /// Trưởng nhóm hiện tại.
  TribeMember? get leader {
    for (final m in members) {
      if (m.role == TribeRole.leader) return m;
    }
    return null;
  }

  /// Các phó nhóm.
  List<TribeMember> get viceLeaders =>
      members.where((m) => m.role == TribeRole.viceLeader).toList();

  /// Tìm dòng thành viên của một người, không có thì trả null.
  TribeMember? memberOf(String userId) {
    for (final m in members) {
      if (m.userId == userId) return m;
    }
    return null;
  }

  /// Chức vụ của một người trong nhóm.
  TribeRole? roleOf(String userId) => memberOf(userId)?.role;

  /// Thành viên sắp theo thứ tự: trưởng nhóm, phó nhóm, thành viên; cùng chức vụ thì ai vào trước đứng trước.
  List<TribeMember> get sortedMembers {
    final list = members.toList();
    list.sort((a, b) {
      final byRole = a.role.index.compareTo(b.role.index);
      return byRole != 0 ? byRole : a.joinedAt.compareTo(b.joinedAt);
    });
    return list;
  }

  /// Tạo bản sao với vài trường thay đổi.
  TribeModel copyWith({
    String? name,
    List<TribeMember>? members,
    DateTime? deletedAt,
  }) => TribeModel(
    id: id,
    name: name ?? this.name,
    createdBy: createdBy,
    inviteCode: inviteCode,
    createdAt: createdAt,
    deletedAt: deletedAt ?? this.deletedAt,
    members: members ?? this.members,
  );

  /// Đọc JSON backend (GET /tribes, GET /tribes/:id).
  factory TribeModel.fromJson(Map<String, dynamic> json) => TribeModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    createdBy: json['created_by'] ?? '',
    inviteCode: json['invite_code'] ?? '',
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
}
