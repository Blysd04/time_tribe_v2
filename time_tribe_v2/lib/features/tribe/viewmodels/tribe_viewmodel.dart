import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/session/session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_time.dart';
import '../../notifications/models/app_notification.dart';
import '../../notifications/models/notification_model.dart';
import '../../timeblock/models/timeblock_model.dart';
import '../data/tribe_mock_data.dart';
import '../models/tribe_block_model.dart';
import '../models/tribe_model.dart';
import '../services/availability_calculator.dart';

/// Giới hạn — khớp các cột mặc định của `pricing_plans`.
/// TODO(backend): đọc theo gói đăng ký của user (max_tribes, max_members_per_tribe).
class TribeLimits {
  static const int maxTribesPerUser = 5;
  static const int maxMembersPerTribe = 10;
  static const int maxViceLeaders = 3;
  static const int maxNameLength = 255;
}

/// Kết quả các thao tác trong nhóm. Câu chữ hiển thị nằm ở giao diện
/// (`tribe_texts.dart`) để dịch được sang nhiều ngôn ngữ.
enum TribeResult {
  success,
  emptyName,
  nameTooLong,
  tribeLimit,
  invalidLink,
  notFound,
  alreadyMember,
  tribeFull,
  viceLimit,
  needNewLeader,
  notAllowed,
  notFoundItem,
}

/// Các quyền trong nhóm, gom về một chỗ cho dễ đọc và dễ test.
class TribePermissions {
  TribePermissions._();

  static bool canRename(TribeRole? r) => r == TribeRole.leader;
  static bool canDissolve(TribeRole? r) => r == TribeRole.leader;
  static bool canChangeColor(TribeRole? r) =>
      r == TribeRole.leader || r == TribeRole.viceLeader;
  static bool canManageBlocks(TribeRole? r) => r?.canManageBlocks ?? false;

  /// Trưởng nhóm quản lý mọi người (trừ chính mình).
  /// Phó nhóm chỉ được mời thành viên thường rời nhóm.
  static bool canManageMember(TribeRole? actor, TribeRole target) {
    if (actor == TribeRole.leader) return target != TribeRole.leader;
    if (actor == TribeRole.viceLeader) return target == TribeRole.member;
    return false;
  }

  static bool canKick(TribeRole? actor, TribeRole target) =>
      canManageMember(actor, target);
  static bool canAppoint(TribeRole? actor) => actor == TribeRole.leader;
}

/// Hoạt động nhóm đã quy đổi sang giờ của người xem.
class LocalTribeBlock {
  final TribeBlockModel block;
  final TribeModel tribe;
  final AttendanceStatus myStatus;
  final DateTime localStart;
  final DateTime localEnd;

  LocalTribeBlock(this.block, this.tribe, this.myStatus)
    : localStart = AppTime.fromUtc(block.startUtc),
      localEnd = AppTime.fromUtc(block.endUtc);
}

class TribeViewModel extends ChangeNotifier {
  final List<TribeModel> _tribes = TribeMockData.tribes();
  final List<TribeBlockModel> _blocks = TribeMockData.blocks();
  final Map<String, TribeModel> _joinable = TribeMockData.joinableTribes();

  /// Thông báo gửi cho NGƯỜI KHÁC (chưa có backend nên chỉ lưu lại).
  /// TODO(backend): server tự tạo bản ghi `notifications` (dịch theo ngôn ngữ
  /// của người nhận) + push FCM. `title` = loại thông báo, `content` = tham số JSON.
  final List<NotificationModel> outbox = [];

  /// Nơi nhận thông báo dành cho chính người dùng hiện tại.
  void Function(AppNotification notification)? notificationSink;

  String get me => Session.currentUserId;

  TribeViewModel({this.notificationSink}) {
    // Lời mời đang chờ mình xác nhận -> hiện trong tab Thông báo
    for (final b in _blocks) {
      if (b.statusOf(me) == AttendanceStatus.pending && b.createdBy != me) {
        final tribe = tribeById(b.tribeId);
        if (tribe == null) continue;
        _notifyUsers(
          [me],
          tribe: tribe,
          kind: NotificationKind.tribeNewBlock,
          args: {'actor': _name(b.createdBy), 'task': b.task},
          type: 'group_schedule',
          referenceId: b.id,
          referenceType: 'tribe_block',
          createdAt: b.createdAt.subtract(const Duration(minutes: 11)),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // ĐỌC DỮ LIỆU
  // ---------------------------------------------------------------------------

  List<TribeModel> get tribes => List.unmodifiable(_tribes);

  bool get canCreateOrJoin => _tribes.length < TribeLimits.maxTribesPerUser;

  TribeModel? tribeById(String id) {
    for (final t in _tribes) {
      if (t.id == id) return t;
    }
    return null;
  }

  TribeRole? myRoleIn(String tribeId) => tribeById(tribeId)?.roleOf(me);

  TribeBlockModel? blockById(String id) {
    for (final b in _blocks) {
      if (b.id == id) return b;
    }
    return null;
  }

  List<TribeBlockModel> blocksOf(String tribeId) =>
      _blocks.where((b) => b.tribeId == tribeId).toList()
        ..sort((a, b) => a.startUtc.compareTo(b.startUtc));

  /// Khung giờ 1 ngày (theo giờ của người xem) dưới dạng UTC.
  static TimeRange dayWindow(DateTime localDate) => TimeRange(
    AppTime.toUtc(DateTime(localDate.year, localDate.month, localDate.day)),
    AppTime.toUtc(DateTime(localDate.year, localDate.month, localDate.day + 1)),
  );

  List<TribeBlockModel> blocksInWindow(String tribeId, TimeRange window) =>
      blocksOf(
        tribeId,
      ).where((b) => b.overlaps(window.start, window.end)).toList();

  /// Số hoạt động đang chờ mình phản hồi trong nhóm.
  int pendingCountForMe(String tribeId) => blocksOf(tribeId)
      .where(
        (b) =>
            b.endUtc.isAfter(DateTime.now().toUtc()) &&
            b.statusOf(me) == AttendanceStatus.pending,
      )
      .length;

  /// Hoạt động sắp tới gần nhất của nhóm.
  TribeBlockModel? nextBlockOf(String tribeId) {
    final now = DateTime.now().toUtc();
    for (final b in blocksOf(tribeId)) {
      if (b.endUtc.isAfter(now)) return b;
    }
    return null;
  }

  /// Hoạt động nhóm hiện trong lịch cá nhân: đã tham gia + đang chờ xác nhận
  /// (để bấm xác nhận ngay trên lịch). Hoạt động đã từ chối thì ẩn.
  List<LocalTribeBlock> tribeBlocksForMe(DateTime localDate) {
    final window = dayWindow(localDate);
    final result = <LocalTribeBlock>[];
    for (final b in _blocks) {
      final status = b.statusOf(me);
      if (status == AttendanceStatus.declined) continue;
      if (!b.overlaps(window.start, window.end)) continue;
      final tribe = tribeById(b.tribeId);
      if (tribe != null) result.add(LocalTribeBlock(b, tribe, status));
    }
    return result;
  }

  /// Khoảng bận của từng thành viên trong [window] — KHÔNG tính hoạt động
  /// của chính nhóm đang xem (vì chúng được vẽ riêng), và với các nhóm khác
  /// chỉ tính hoạt động mà thành viên đã XÁC NHẬN tham gia.
  Map<String, List<TimeRange>> busyByMember(
    TribeModel tribe,
    TimeRange window, {
    required List<TimeblockModel> myPersonalBlocks,
  }) {
    final result = <String, List<TimeRange>>{};
    for (final member in tribe.members) {
      final ranges = <TimeRange>[];

      // 1. Lịch cá nhân
      if (member.userId == me) {
        for (final t in myPersonalBlocks) {
          final c = _personalRange(t).clip(window);
          if (c != null) ranges.add(c);
        }
      } else {
        ranges.addAll(TribeMockData.personalBusyOf(member.userId, window));
      }

      // 2. Hoạt động của các nhóm KHÁC mà người đó đã nhận tham gia
      for (final b in _blocks) {
        if (b.tribeId == tribe.id) continue;
        if (b.statusOf(member.userId) != AttendanceStatus.accepted) continue;
        final c = TimeRange(b.startUtc, b.endUtc).clip(window);
        if (c != null) ranges.add(c);
      }

      result[member.userId] = ranges;
    }
    return result;
  }

  TimeRange _personalRange(TimeblockModel t) {
    final start = AppTime.toUtc(
      DateTime(
        t.date.year,
        t.date.month,
        t.date.day,
        t.startTime.hour,
        t.startTime.minute,
      ),
    );
    var end = AppTime.toUtc(
      DateTime(
        t.date.year,
        t.date.month,
        t.date.day,
        t.endTime.hour,
        t.endTime.minute,
      ),
    );
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    return TimeRange(start, end);
  }

  // ---------------------------------------------------------------------------
  // QUẢN LÝ NHÓM
  // ---------------------------------------------------------------------------

  /// COM-03: tạo nhóm, người tạo là trưởng nhóm.
  ({TribeResult result, TribeModel? tribe}) createTribe(String rawName) {
    final name = rawName.trim();
    if (name.isEmpty) return (result: TribeResult.emptyName, tribe: null);
    if (name.length > TribeLimits.maxNameLength) {
      return (result: TribeResult.nameTooLong, tribe: null);
    }
    if (!canCreateOrJoin) return (result: TribeResult.tribeLimit, tribe: null);

    final id = const Uuid().v4();
    final tribe = TribeModel(
      id: id,
      name: name,
      createdBy: me,
      inviteCode: _newInviteCode(),
      backgroundColor:
          AppColors.palette[_tribes.length % AppColors.palette.length],
      members: [
        TribeMember(
          id: '$id-$me',
          tribeId: id,
          user: _user(me),
          role: TribeRole.leader,
        ),
      ],
    );
    _tribes.add(tribe);
    notifyListeners();
    // TODO(backend): POST /tribes
    return (result: TribeResult.success, tribe: tribe);
  }

  /// Lấy mã mời từ link: https://timetribe.app/tribe/ABC123 hoặc chỉ "ABC123".
  static String? extractInviteCode(String link) {
    final segments =
        (Uri.tryParse(link.trim())?.pathSegments ?? const <String>[])
            .where((s) => s.isNotEmpty)
            .toList();
    if (segments.isEmpty) return null;
    return segments.last.toUpperCase();
  }

  /// COM-11: tham gia nhóm bằng link.
  ({TribeResult result, TribeModel? tribe}) joinByLink(String link) {
    final code = extractInviteCode(link);
    if (code == null) return (result: TribeResult.invalidLink, tribe: null);

    for (final t in _tribes) {
      if (t.inviteCode.toUpperCase() == code) {
        return (result: TribeResult.alreadyMember, tribe: t);
      }
    }
    if (!canCreateOrJoin) return (result: TribeResult.tribeLimit, tribe: null);

    // TODO(backend): POST /tribes/join { invite_code }
    final found = _joinable[code];
    if (found == null) return (result: TribeResult.notFound, tribe: null);
    if (found.members.length >= TribeLimits.maxMembersPerTribe) {
      return (result: TribeResult.tribeFull, tribe: found);
    }

    final joined = found.copyWith(
      members: [
        ...found.members,
        TribeMember(id: '${found.id}-$me', tribeId: found.id, user: _user(me)),
      ],
    );
    _joinable.remove(code);
    _tribes.add(joined);
    _notifyUsers(
      _others(joined),
      tribe: joined,
      kind: NotificationKind.tribeMemberJoined,
      args: {'actor': _name(me)},
      type: 'tribe_join',
      referenceId: joined.id,
      referenceType: 'tribe',
    );
    notifyListeners();
    return (result: TribeResult.success, tribe: joined);
  }

  TribeResult renameTribe(String tribeId, String rawName) {
    final tribe = tribeById(tribeId);
    if (tribe == null) return TribeResult.notFoundItem;
    if (!TribePermissions.canRename(tribe.roleOf(me))) {
      return TribeResult.notAllowed;
    }
    final name = rawName.trim();
    if (name.isEmpty) return TribeResult.emptyName;
    if (name.length > TribeLimits.maxNameLength) return TribeResult.nameTooLong;

    _replaceTribe(tribe.copyWith(name: name));
    _notifyUsers(
      _others(tribe),
      tribe: tribe,
      kind: NotificationKind.tribeRenamed,
      args: {'actor': _name(me), 'old': tribe.name, 'new': name},
      type: 'tribe_role',
      referenceId: tribe.id,
      referenceType: 'tribe',
    );
    notifyListeners();
    return TribeResult.success;
  }

  /// COM-09: đổi màu nhóm (không lưu ảnh nền).
  TribeResult updateColor(String tribeId, String color) {
    final tribe = tribeById(tribeId);
    if (tribe == null) return TribeResult.notFoundItem;
    if (!TribePermissions.canChangeColor(tribe.roleOf(me))) {
      return TribeResult.notAllowed;
    }
    _replaceTribe(tribe.copyWith(backgroundColor: color));
    // TODO(backend): PATCH /tribes/{id} { background_color }
    notifyListeners();
    return TribeResult.success;
  }

  /// COM-06: giải tán nhóm.
  TribeResult dissolveTribe(String tribeId) {
    final tribe = tribeById(tribeId);
    if (tribe == null) return TribeResult.notFoundItem;
    if (!TribePermissions.canDissolve(tribe.roleOf(me))) {
      return TribeResult.notAllowed;
    }

    _tribes.removeWhere((t) => t.id == tribeId);
    _blocks.removeWhere((b) => b.tribeId == tribeId);
    _notifyUsers(
      _others(tribe),
      tribe: tribe,
      kind: NotificationKind.tribeDissolved,
      args: {'actor': _name(me)},
      type: 'tribe_role',
      referenceId: tribe.id,
      referenceType: 'tribe',
    );
    // TODO(backend): PATCH /tribes/{id} { deleted_at: now }
    notifyListeners();
    return TribeResult.success;
  }

  /// COM-12 / COM-13: rời nhóm.
  /// Trưởng nhóm còn thành viên khác phải bổ nhiệm người mới trước.
  /// Trưởng nhóm ở một mình -> rời = giải tán nhóm.
  TribeResult leaveTribe(String tribeId) {
    final tribe = tribeById(tribeId);
    if (tribe == null) return TribeResult.notFoundItem;
    if (tribe.roleOf(me) == TribeRole.leader) {
      if (tribe.members.length > 1) return TribeResult.needNewLeader;
      return dissolveTribe(tribeId);
    }
    _removeMember(tribe, me);
    _notifyUsers(
      _others(tribe),
      tribe: tribe,
      kind: NotificationKind.tribeMemberLeft,
      args: {'actor': _name(me)},
      type: 'tribe_join',
      referenceId: tribe.id,
      referenceType: 'tribe',
    );
    _tribes.removeWhere((t) => t.id == tribeId);
    notifyListeners();
    return TribeResult.success;
  }

  /// COM-14: mời một thành viên rời nhóm.
  TribeResult kickMember(String tribeId, String userId) {
    final tribe = tribeById(tribeId);
    final target = tribe?.memberOf(userId);
    if (tribe == null || target == null) return TribeResult.notFoundItem;
    if (!TribePermissions.canKick(tribe.roleOf(me), target.role)) {
      return TribeResult.notAllowed;
    }

    _removeMember(tribe, userId);
    _notifyUsers(
      [userId],
      tribe: tribe,
      kind: NotificationKind.tribeKickedYou,
      args: {'actor': _name(me)},
      type: 'tribe_role',
      referenceId: tribe.id,
      referenceType: 'tribe',
    );
    _notifyUsers(
      _others(tribe).where((id) => id != userId),
      tribe: tribe,
      kind: NotificationKind.tribeMemberLeft,
      args: {'actor': target.user.nickName},
      type: 'tribe_join',
      referenceId: tribe.id,
      referenceType: 'tribe',
    );
    notifyListeners();
    return TribeResult.success;
  }

  /// COM-15: bổ nhiệm phó nhóm (tối đa 3).
  TribeResult appointVice(String tribeId, String userId) {
    final tribe = tribeById(tribeId);
    final target = tribe?.memberOf(userId);
    if (tribe == null || target == null) return TribeResult.notFoundItem;
    if (!TribePermissions.canAppoint(tribe.roleOf(me)) ||
        target.role != TribeRole.member) {
      return TribeResult.notAllowed;
    }
    if (tribe.viceLeaders.length >= TribeLimits.maxViceLeaders) {
      return TribeResult.viceLimit;
    }

    _setRole(tribe, userId, TribeRole.viceLeader);
    _notifyRole(tribe, userId, NotificationKind.tribeRoleVice);
    notifyListeners();
    return TribeResult.success;
  }

  /// COM-17: bãi nhiệm phó nhóm -> thành viên.
  TribeResult dismissVice(String tribeId, String userId) {
    final tribe = tribeById(tribeId);
    final target = tribe?.memberOf(userId);
    if (tribe == null || target == null) return TribeResult.notFoundItem;
    if (!TribePermissions.canAppoint(tribe.roleOf(me)) ||
        target.role != TribeRole.viceLeader) {
      return TribeResult.notAllowed;
    }
    _setRole(tribe, userId, TribeRole.member);
    _notifyRole(tribe, userId, NotificationKind.tribeRoleViceRemoved);
    notifyListeners();
    return TribeResult.success;
  }

  /// COM-16: chuyển quyền trưởng nhóm. Trưởng nhóm cũ trở thành phó nhóm
  /// nếu nhóm còn chỗ (< 3 phó), ngược lại trở thành thành viên.
  TribeResult transferLeader(String tribeId, String userId) {
    final tribe = tribeById(tribeId);
    final target = tribe?.memberOf(userId);
    if (tribe == null || target == null || userId == me) {
      return TribeResult.notFoundItem;
    }
    if (tribe.roleOf(me) != TribeRole.leader) return TribeResult.notAllowed;

    final vicesAfter = tribe.viceLeaders
        .where((v) => v.userId != userId)
        .length;
    final myNewRole = vicesAfter < TribeLimits.maxViceLeaders
        ? TribeRole.viceLeader
        : TribeRole.member;

    _setRole(tribe, userId, TribeRole.leader);
    _setRole(tribeById(tribeId)!, me, myNewRole);
    _notifyRole(tribe, userId, NotificationKind.tribeRoleLeader);
    notifyListeners();
    return TribeResult.success;
  }

  /// Khi xoá tài khoản: tự chuyển quyền trưởng nhóm (ưu tiên phó nhóm, rồi
  /// thành viên vào sớm nhất) và rời mọi nhóm; nhóm chỉ có mình thì giải tán.
  void leaveAllForAccountDeletion() {
    for (final tribe in _tribes.toList()) {
      if (tribe.roleOf(me) == TribeRole.leader && tribe.members.length > 1) {
        final others = tribe.sortedMembers
            .where((m) => m.userId != me)
            .toList();
        transferLeader(tribe.id, others.first.userId);
      }
      leaveTribe(tribe.id);
    }
  }

  // ---------------------------------------------------------------------------
  // HOẠT ĐỘNG NHÓM
  // ---------------------------------------------------------------------------

  /// Các hoạt động khác của nhóm bị trùng giờ.
  List<TribeBlockModel> conflictsOf(
    String tribeId,
    DateTime startUtc,
    DateTime endUtc, {
    String? ignoreId,
  }) => blocksOf(
    tribeId,
  ).where((b) => b.id != ignoreId && b.overlaps(startUtc, endUtc)).toList();

  /// COM-07: tạo hoạt động nhóm, báo cho mọi người để xác nhận.
  TribeResult createBlock({
    required String tribeId,
    required String task,
    String? description,
    required DateTime startUtc,
    required DateTime endUtc,
    required String colorCode,
  }) {
    final tribe = tribeById(tribeId);
    if (tribe == null) return TribeResult.notFoundItem;
    if (!TribePermissions.canManageBlocks(tribe.roleOf(me))) {
      return TribeResult.notAllowed;
    }

    final id = const Uuid().v4();
    final block = TribeBlockModel(
      id: id,
      tribeId: tribeId,
      createdBy: me,
      task: task.trim(),
      description: description?.trim(),
      startUtc: startUtc,
      endUtc: endUtc,
      colorCode: colorCode,
      attendance: [
        for (final m in tribe.members)
          TribeBlockAttendance(
            id: '$id-${m.userId}',
            tribeBlockId: id,
            userId: m.userId,
            // Người tạo mặc định tham gia
            status: m.userId == me
                ? AttendanceStatus.accepted
                : AttendanceStatus.pending,
          ),
      ],
    );
    _blocks.add(block);
    _notifyUsers(
      _others(tribe),
      tribe: tribe,
      kind: NotificationKind.tribeNewBlock,
      args: {'actor': _name(me), 'task': block.task},
      type: 'group_schedule',
      referenceId: id,
      referenceType: 'tribe_block',
    );
    // TODO(backend): POST /tribes/{id}/blocks
    notifyListeners();
    return TribeResult.success;
  }

  /// COM-05: sửa hoạt động. Nếu đổi giờ, mọi người cần xác nhận lại.
  TribeResult updateBlock(TribeBlockModel updated) {
    final index = _blocks.indexWhere((b) => b.id == updated.id);
    final tribe = tribeById(updated.tribeId);
    if (index == -1 || tribe == null) return TribeResult.notFoundItem;
    if (!TribePermissions.canManageBlocks(tribe.roleOf(me))) {
      return TribeResult.notAllowed;
    }

    final old = _blocks[index];
    final timeChanged =
        old.startUtc != updated.startUtc || old.endUtc != updated.endUtc;
    var result = updated;
    if (timeChanged) {
      result = updated.copyWith(
        attendance: [
          for (final a in old.attendance)
            a.copyWith(
              status: a.userId == me
                  ? AttendanceStatus.accepted
                  : AttendanceStatus.pending,
            ),
        ],
      );
    }
    _blocks[index] = result;
    _notifyUsers(
      _others(tribe),
      tribe: tribe,
      kind: timeChanged
          ? NotificationKind.tribeBlockRescheduled
          : NotificationKind.tribeBlockUpdated,
      args: {'actor': _name(me), 'task': result.task},
      type: 'group_schedule',
      referenceId: result.id,
      referenceType: 'tribe_block',
    );
    notifyListeners();
    return TribeResult.success;
  }

  /// COM-10: xoá hoạt động nhóm.
  TribeResult deleteBlock(String blockId) {
    final block = blockById(blockId);
    final tribe = block == null ? null : tribeById(block.tribeId);
    if (block == null || tribe == null) return TribeResult.notFoundItem;
    if (!TribePermissions.canManageBlocks(tribe.roleOf(me))) {
      return TribeResult.notAllowed;
    }

    _blocks.removeWhere((b) => b.id == blockId);
    _notifyUsers(
      _others(tribe),
      tribe: tribe,
      kind: NotificationKind.tribeBlockCancelled,
      args: {'actor': _name(me), 'task': block.task},
      type: 'group_schedule',
      referenceType: 'tribe_block',
    );
    notifyListeners();
    return TribeResult.success;
  }

  /// COM-19: xác nhận / từ chối tham gia. Báo về cho trưởng & phó nhóm.
  TribeResult respond(String blockId, AttendanceStatus status) {
    final index = _blocks.indexWhere((b) => b.id == blockId);
    if (index == -1) return TribeResult.notFoundItem;
    final block = _blocks[index];
    final tribe = tribeById(block.tribeId);
    if (tribe == null || tribe.memberOf(me) == null) {
      return TribeResult.notAllowed;
    }
    if (block.statusOf(me) == status) return TribeResult.success;

    final attendance = block.attendance.toList();
    final i = attendance.indexWhere((a) => a.userId == me);
    if (i == -1) {
      attendance.add(
        TribeBlockAttendance(
          id: '$blockId-$me',
          tribeBlockId: blockId,
          userId: me,
          status: status,
        ),
      );
    } else {
      attendance[i] = attendance[i].copyWith(status: status);
    }
    _blocks[index] = block.copyWith(attendance: attendance);

    final managers = tribe.members
        .where((m) => m.role != TribeRole.member && m.userId != me)
        .map((m) => m.userId);
    _notifyUsers(
      managers,
      tribe: tribe,
      kind: status == AttendanceStatus.accepted
          ? NotificationKind.tribeResponseAccepted
          : NotificationKind.tribeResponseDeclined,
      args: {'actor': _name(me), 'task': block.task},
      type: 'group_schedule',
      referenceId: blockId,
      referenceType: 'tribe_block_response',
    );
    // TODO(backend): PUT /tribe-blocks/{id}/attendance { status }
    notifyListeners();
    return TribeResult.success;
  }

  // ---------------------------------------------------------------------------
  // NỘI BỘ
  // ---------------------------------------------------------------------------

  AppUser _user(String id) => id == me
      ? TribeMockData.users['u-me']!
      : (TribeMockData.users[id] ?? AppUser(id: id, nickName: '?'));

  String _name(String id) {
    for (final t in _tribes) {
      final m = t.memberOf(id);
      if (m != null) return m.user.nickName;
    }
    return _user(id).nickName;
  }

  Iterable<String> _others(TribeModel tribe) =>
      tribe.members.map((m) => m.userId).where((id) => id != me);

  void _replaceTribe(TribeModel tribe) {
    final i = _tribes.indexWhere((t) => t.id == tribe.id);
    if (i != -1) _tribes[i] = tribe;
  }

  void _setRole(TribeModel tribe, String userId, TribeRole role) {
    _replaceTribe(
      tribe.copyWith(
        members: [
          for (final m in tribe.members)
            m.userId == userId ? m.copyWith(role: role) : m,
        ],
      ),
    );
  }

  void _removeMember(TribeModel tribe, String userId) {
    _replaceTribe(
      tribe.copyWith(
        members: tribe.members.where((m) => m.userId != userId).toList(),
      ),
    );
    // Bỏ phản hồi của người đã rời khỏi các hoạt động của nhóm
    for (int i = 0; i < _blocks.length; i++) {
      final b = _blocks[i];
      if (b.tribeId != tribe.id) continue;
      _blocks[i] = b.copyWith(
        attendance: b.attendance.where((a) => a.userId != userId).toList(),
      );
    }
  }

  void _notifyRole(TribeModel tribe, String userId, NotificationKind kind) =>
      _notifyUsers(
        [userId],
        tribe: tribe,
        kind: kind,
        args: {'actor': _name(me)},
        type: 'tribe_role',
        referenceId: tribe.id,
        referenceType: 'tribe',
      );

  void _notifyUsers(
    Iterable<String> userIds, {
    required TribeModel tribe,
    required NotificationKind kind,
    required Map<String, String> args,
    required String type,
    String? referenceId,
    String? referenceType,
    DateTime? createdAt,
  }) {
    final fullArgs = {'tribe': tribe.name, ...args};
    for (final userId in userIds) {
      outbox.add(
        NotificationModel(
          id: const Uuid().v4(),
          userId: userId,
          createdBy: me,
          title: kind.name,
          content: jsonEncode(fullArgs),
          type: type,
          referenceId: referenceId,
          referenceType: referenceType,
        ),
      );
      if (userId == me) {
        notificationSink?.call(
          AppNotification(
            id: const Uuid().v4(),
            kind: kind,
            args: fullArgs,
            type: type,
            tribeId: tribe.id,
            referenceId: referenceId,
            referenceType: referenceType,
            createdAt: createdAt,
          ),
        );
      }
    }
  }

  static String _newInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
