import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/utils/app_time.dart';
import '../../timeblock/models/timeblock_model.dart';
import '../models/tribe_block_model.dart';
import '../models/tribe_model.dart';
import '../services/availability_calculator.dart';

/// Giới hạn của nhóm, khớp với hằng số bên backend.
class TribeLimits {
  static const int maxTribesPerUser = 5;
  static const int maxMembersPerTribe = 10;
  static const int maxViceLeaders = 3;
  static const int maxNameLength = 255;
}

/// Kết quả các thao tác trong nhóm. Câu chữ hiển thị nằm ở giao diện
/// (tribe_texts.dart) để dịch được sang nhiều ngôn ngữ.
enum TribeResult {
  success,
  emptyName,
  nameTooLong,
  tribeLimit,
  invalidCode,
  notFound,
  alreadyMember,
  tribeFull,
  viceLimit,
  needNewLeader,
  notAllowed,
  notFoundItem,
  pastTime,
  blockEnded,
  network,
  failed,
}

/// Các quyền trong nhóm, gom về một chỗ cho dễ đọc và dễ test.
/// Server cũng kiểm tra lại y hệt, ở đây chỉ để ẩn hoặc khoá nút trên giao diện.
class TribePermissions {
  TribePermissions._();

  /// Chỉ trưởng nhóm được đổi tên nhóm.
  static bool canRename(TribeRole? r) => r == TribeRole.leader;

  /// Chỉ trưởng nhóm được giải tán nhóm.
  static bool canDissolve(TribeRole? r) => r == TribeRole.leader;

  /// Trưởng và phó nhóm được tạo, sửa, xoá hoạt động nhóm.
  static bool canManageBlocks(TribeRole? r) => r?.canManageBlocks ?? false;

  /// Trưởng nhóm quản lý mọi người (trừ chính mình).
  /// Phó nhóm chỉ được mời thành viên thường rời nhóm.
  static bool canManageMember(TribeRole? actor, TribeRole target) {
    if (actor == TribeRole.leader) return target != TribeRole.leader;
    if (actor == TribeRole.viceLeader) return target == TribeRole.member;
    return false;
  }

  /// Có được mời người này rời nhóm không.
  static bool canKick(TribeRole? actor, TribeRole target) =>
      canManageMember(actor, target);

  /// Chỉ trưởng nhóm được bổ nhiệm, bãi nhiệm, chuyển quyền.
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

/// Giờ bận của các thành viên một nhóm, tải từ /tribes/:id/busy cho cả một khoảng ngày.
class _BusyCache {
  final DateTime from;
  final DateTime to;
  final Map<String, List<TimeRange>> byUser;

  _BusyCache(this.from, this.to, this.byUser);

  /// Khoảng đã tải có bao trọn ngày [day] không.
  bool covers(DateTime day) => !day.isBefore(from) && !day.isAfter(to);
}

class TribeViewModel extends ChangeNotifier {
  TribeViewModel({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  List<TribeModel> _tribes = [];
  List<TribeBlockModel> _blocks = [];
  final Map<String, _BusyCache> _busy = {};

  // Khoảng ngày (theo giờ người xem) đã tải hoạt động nhóm
  DateTime? _blocksFrom;
  DateTime? _blocksTo;

  bool _isLoading = false;

  /// Đang tải danh sách nhóm hay không.
  bool get isLoading => _isLoading;

  /// id của người đang đăng nhập.
  String get me => Session.currentUserId;

  // ---------------------------------------------------------------------------
  // Đọc dữ liệu
  // ---------------------------------------------------------------------------

  /// Các nhóm mình đang tham gia (không cho sửa trực tiếp từ ngoài).
  List<TribeModel> get tribes => List.unmodifiable(_tribes);

  /// Còn được tạo hoặc tham gia thêm nhóm không (tối đa 5 nhóm).
  bool get canCreateOrJoin => _tribes.length < TribeLimits.maxTribesPerUser;

  /// Tìm nhóm trong danh sách đã tải.
  TribeModel? tribeById(String id) {
    for (final t in _tribes) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Chức vụ của mình trong một nhóm.
  TribeRole? myRoleIn(String tribeId) => tribeById(tribeId)?.roleOf(me);

  /// Tìm hoạt động nhóm trong danh sách đã tải.
  TribeBlockModel? blockById(String id) {
    for (final b in _blocks) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Hoạt động của một nhóm, sắp theo giờ bắt đầu.
  List<TribeBlockModel> blocksOf(String tribeId) =>
      _blocks.where((b) => b.tribeId == tribeId).toList()
        ..sort((a, b) => a.startUtc.compareTo(b.startUtc));

  /// Khung giờ 1 ngày (theo giờ của người xem) dưới dạng UTC.
  static TimeRange dayWindow(DateTime localDate) => TimeRange(
    AppTime.toUtc(DateTime(localDate.year, localDate.month, localDate.day)),
    AppTime.toUtc(DateTime(localDate.year, localDate.month, localDate.day + 1)),
  );

  /// Hoạt động của nhóm có giao với khoảng thời gian [window].
  List<TribeBlockModel> blocksInWindow(String tribeId, TimeRange window) =>
      blocksOf(
        tribeId,
      ).where((b) => b.overlaps(window.start, window.end)).toList();

  /// Số hoạt động chưa kết thúc mà mình chưa trả lời trong nhóm.
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

  /// Khoảng bận của từng thành viên trong [window], không tính hoạt động của
  /// chính nhóm đang xem (vì chúng được vẽ riêng).
  /// - Mình: lấy lịch cá nhân đang có trên máy + hoạt động nhóm khác đã nhận tham gia.
  /// - Người khác: lấy từ server (/tribes/:id/busy), server chỉ trả khoảng bận chứ
  ///   không trả nội dung lịch riêng của họ.
  Map<String, List<TimeRange>> busyByMember(
    TribeModel tribe,
    TimeRange window, {
    required List<TimeblockModel> myPersonalBlocks,
  }) {
    final cache = _busy[tribe.id];
    final result = <String, List<TimeRange>>{};
    for (final member in tribe.members) {
      final ranges = <TimeRange>[];
      if (member.userId == me) {
        for (final t in myPersonalBlocks) {
          final c = _personalRange(t).clip(window);
          if (c != null) ranges.add(c);
        }
        for (final b in _blocks) {
          if (b.tribeId == tribe.id) continue;
          if (b.statusOf(me) != AttendanceStatus.accepted) continue;
          final c = TimeRange(b.startUtc, b.endUtc).clip(window);
          if (c != null) ranges.add(c);
        }
      } else {
        for (final r in cache?.byUser[member.userId] ?? const <TimeRange>[]) {
          final c = r.clip(window);
          if (c != null) ranges.add(c);
        }
      }
      result[member.userId] = ranges;
    }
    return result;
  }

  /// Đổi lịch cá nhân (giờ địa phương) sang khoảng thời gian UTC.
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

  /// Các hoạt động khác của nhóm bị trùng giờ.
  List<TribeBlockModel> conflictsOf(
    String tribeId,
    DateTime startUtc,
    DateTime endUtc, {
    String? ignoreId,
  }) => blocksOf(
    tribeId,
  ).where((b) => b.id != ignoreId && b.overlaps(startUtc, endUtc)).toList();

  // ---------------------------------------------------------------------------
  // Tải dữ liệu từ server
  // ---------------------------------------------------------------------------

  /// COM-01: tải danh sách nhóm và hoạt động nhóm quanh hôm nay (gọi sau khi đăng nhập).
  Future<void> load() async {
    if (me.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/tribes');
      _tribes = [for (final j in data as List) TribeModel.fromJson(j)];
      _blocks = [];
      _busy.clear();
      _blocksFrom = null;
      _blocksTo = null;
      await ensureBlocksLoaded(AppTime.today());
    } on ApiException catch (e) {
      debugPrint('tải danh sách nhóm lỗi: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đảm bảo đã có hoạt động của mọi nhóm trong tháng trước, tháng này và tháng sau của [date].
  Future<void> ensureBlocksLoaded(DateTime date) async {
    final from = DateTime(date.year, date.month - 1, 1);
    final to = DateTime(date.year, date.month + 2, 0);
    if (_blocksFrom != null &&
        !from.isBefore(_blocksFrom!) &&
        !to.isAfter(_blocksTo!)) {
      return;
    }
    // Server giới hạn mỗi lần hỏi tối đa 62 ngày nên chia nhỏ
    for (final t in _tribes.toList()) {
      await _fetchBlocksRange(t.id, from, to);
    }
    _blocksFrom = _blocksFrom == null || from.isBefore(_blocksFrom!)
        ? from
        : _blocksFrom;
    _blocksTo = _blocksTo == null || to.isAfter(_blocksTo!) ? to : _blocksTo;
    notifyListeners();
  }

  /// Tải hoạt động của một nhóm trong khoảng ngày bất kỳ, chia thành từng đoạn tối đa 60 ngày.
  Future<void> _fetchBlocksRange(
    String tribeId,
    DateTime from,
    DateTime to,
  ) async {
    var start = DateTime(from.year, from.month, from.day);
    final last = DateTime(to.year, to.month, to.day);
    while (!start.isAfter(last)) {
      var end = DateTime(start.year, start.month, start.day + 59);
      if (end.isAfter(last)) end = last;
      await _fetchBlocks(tribeId, start, end);
      start = DateTime(end.year, end.month, end.day + 1);
    }
  }

  /// Gọi GET /tribes/:id/blocks?from=&to= rồi thay vào danh sách đang có.
  Future<void> _fetchBlocks(String tribeId, DateTime from, DateTime to) async {
    try {
      final data = await _api.get(
        '/tribes/$tribeId/blocks',
        query: {
          'from': TimeblockModel.formatDate(from),
          'to': TimeblockModel.formatDate(to),
        },
      );
      final fresh = [for (final j in data as List) TribeBlockModel.fromJson(j)];
      final ids = fresh.map((b) => b.id).toSet();
      _blocks = [..._blocks.where((b) => !ids.contains(b.id)), ...fresh];
    } on ApiException catch (e) {
      debugPrint('tải hoạt động nhóm lỗi: $e');
    }
  }

  /// Tải giờ bận của thành viên nhóm quanh ngày [date] (cả tháng đó, cộng thêm vài ngày hai đầu).
  Future<void> ensureBusyLoaded(String tribeId, DateTime date) async {
    final cache = _busy[tribeId];
    final day = DateTime(date.year, date.month, date.day);
    if (cache != null && cache.covers(day)) return;
    final from = DateTime(
      date.year,
      date.month,
      1,
    ).subtract(const Duration(days: 7));
    final to = DateTime(date.year, date.month + 1, 7);
    try {
      final data = await _api.get(
        '/tribes/$tribeId/busy',
        query: {
          'from': TimeblockModel.formatDate(from),
          'to': TimeblockModel.formatDate(to),
        },
      );
      final byUser = <String, List<TimeRange>>{};
      for (final m in (data['members'] as List)) {
        byUser[m['user_id']] = [
          for (final r in (m['busy'] as List))
            TimeRange(DateTime.parse(r['start']), DateTime.parse(r['end'])),
        ];
      }
      _busy[tribeId] = _BusyCache(from, to, byUser);
      notifyListeners();
    } on ApiException catch (e) {
      debugPrint('tải giờ bận lỗi: $e');
    }
  }

  /// Tải lại một nhóm (sau khi có người rời nhóm, đổi chức vụ...).
  Future<void> refreshTribe(String tribeId) async {
    try {
      final data = await _api.get('/tribes/$tribeId');
      _upsertTribe(TribeModel.fromJson(data));
    } on ApiException catch (e) {
      if (e.code == 'not_found_item') _removeTribeLocal(tribeId);
    }
    notifyListeners();
  }

  /// Xoá dữ liệu khi đăng xuất.
  void clear() {
    _tribes = [];
    _blocks = [];
    _busy.clear();
    _requestedBlocks.clear();
    _blocksFrom = null;
    _blocksTo = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Quản lý nhóm
  // ---------------------------------------------------------------------------

  /// Đổi mã lỗi server thành TribeResult.
  static TribeResult resultFrom(ApiException e) => switch (e.code) {
    'empty_name' => TribeResult.emptyName,
    'name_too_long' => TribeResult.nameTooLong,
    'tribe_limit' => TribeResult.tribeLimit,
    'invalid_code' => TribeResult.invalidCode,
    'not_found' => TribeResult.notFound,
    'already_member' => TribeResult.alreadyMember,
    'tribe_full' => TribeResult.tribeFull,
    'vice_limit' => TribeResult.viceLimit,
    'need_new_leader' => TribeResult.needNewLeader,
    'not_allowed' => TribeResult.notAllowed,
    'not_found_item' => TribeResult.notFoundItem,
    'past_time' => TribeResult.pastTime,
    'block_ended' => TribeResult.blockEnded,
    'network_error' => TribeResult.network,
    _ => TribeResult.failed,
  };

  /// Kiểm tra nhanh tên nhóm ở máy trước khi gửi lên server.
  static TribeResult? _checkName(String rawName) {
    final name = rawName.trim();
    if (name.isEmpty) return TribeResult.emptyName;
    if (name.length > TribeLimits.maxNameLength) return TribeResult.nameTooLong;
    return null;
  }

  /// COM-03: tạo nhóm, mình là trưởng nhóm.
  Future<({TribeResult result, TribeModel? tribe})> createTribe(
    String rawName,
  ) async {
    final invalid = _checkName(rawName);
    if (invalid != null) return (result: invalid, tribe: null);
    if (!canCreateOrJoin) return (result: TribeResult.tribeLimit, tribe: null);
    try {
      final data = await _api.post('/tribes', {'name': rawName.trim()});
      final tribe = TribeModel.fromJson(data);
      _upsertTribe(tribe);
      notifyListeners();
      return (result: TribeResult.success, tribe: tribe);
    } on ApiException catch (e) {
      return (result: resultFrom(e), tribe: null);
    }
  }

  /// COM-11: tham gia nhóm bằng mã mời. Nếu đã ở trong nhóm thì trả kèm nhóm đó để mở nhanh.
  Future<({TribeResult result, TribeModel? tribe})> joinByCode(
    String code,
  ) async {
    if (code.trim().isEmpty) {
      return (result: TribeResult.invalidCode, tribe: null);
    }
    try {
      final data = await _api.post('/tribes/join', {
        'invite_code': code.trim(),
      });
      final tribe = TribeModel.fromJson(data);
      _upsertTribe(tribe);
      // Tải hoạt động của nhóm vừa vào cho đúng khoảng ngày đang có của các nhóm khác.
      // Khoảng này thường dài ~3 tháng, server chỉ nhận tối đa 62 ngày một lần nên phải chia nhỏ
      // (trước đây gọi một lần cả khoảng nên bị từ chối, người mới vào không thấy hoạt động nào).
      final now = AppTime.today();
      await _fetchBlocksRange(
        tribe.id,
        _blocksFrom ?? DateTime(now.year, now.month - 1, 1),
        _blocksTo ?? DateTime(now.year, now.month + 2, 0),
      );
      notifyListeners();
      return (result: TribeResult.success, tribe: tribe);
    } on ApiException catch (e) {
      TribeModel? existing;
      if (e.code == 'already_member' && e.details is Map) {
        existing = tribeById((e.details as Map)['tribe_id'] ?? '');
      }
      return (result: resultFrom(e), tribe: existing);
    }
  }

  /// COM-05: đổi tên nhóm (chỉ trưởng nhóm).
  Future<TribeResult> renameTribe(String tribeId, String rawName) async {
    final invalid = _checkName(rawName);
    if (invalid != null) return invalid;
    return _tribeAction(
      () => _api.patch('/tribes/$tribeId', {'name': rawName.trim()}),
    );
  }

  /// COM-06: giải tán nhóm.
  Future<TribeResult> dissolveTribe(String tribeId) async {
    try {
      await _api.delete('/tribes/$tribeId');
      _removeTribeLocal(tribeId);
      notifyListeners();
      return TribeResult.success;
    } on ApiException catch (e) {
      return resultFrom(e);
    }
  }

  /// COM-12, COM-13: rời nhóm. Trưởng nhóm còn người khác thì phải truyền [newLeaderId].
  /// Trưởng nhóm ở một mình thì rời nhóm cũng là giải tán.
  Future<TribeResult> leaveTribe(String tribeId, {String? newLeaderId}) async {
    try {
      await _api.post('/tribes/$tribeId/leave', {
        'new_leader_id': ?newLeaderId,
      });
      _removeTribeLocal(tribeId);
      notifyListeners();
      return TribeResult.success;
    } on ApiException catch (e) {
      return resultFrom(e);
    }
  }

  /// COM-14: mời một thành viên rời nhóm.
  Future<TribeResult> kickMember(String tribeId, String userId) async {
    try {
      await _api.delete('/tribes/$tribeId/members/$userId');
      await refreshTribe(tribeId);
      return TribeResult.success;
    } on ApiException catch (e) {
      return resultFrom(e);
    }
  }

  /// COM-15: bổ nhiệm phó nhóm (tối đa 3).
  Future<TribeResult> appointVice(String tribeId, String userId) =>
      _changeRole(tribeId, userId, TribeRole.viceLeader);

  /// COM-17: bãi nhiệm phó nhóm xuống thành viên.
  Future<TribeResult> dismissVice(String tribeId, String userId) =>
      _changeRole(tribeId, userId, TribeRole.member);

  /// COM-16: chuyển quyền trưởng nhóm. Trưởng nhóm cũ thành phó nhóm nếu còn chỗ,
  /// không thì thành thành viên (server tự xử lý).
  Future<TribeResult> transferLeader(String tribeId, String userId) =>
      _changeRole(tribeId, userId, TribeRole.leader);

  /// Gọi API đổi chức vụ một thành viên rồi cập nhật lại nhóm.
  Future<TribeResult> _changeRole(
    String tribeId,
    String userId,
    TribeRole role,
  ) {
    return _tribeAction(
      () => _api.patch('/tribes/$tribeId/members/$userId/role', {
        'role': role.value,
      }),
    );
  }

  /// Chạy một API trả về chi tiết nhóm rồi cập nhật lại nhóm đó trong danh sách.
  Future<TribeResult> _tribeAction(Future<dynamic> Function() call) async {
    try {
      final data = await call();
      _upsertTribe(TribeModel.fromJson(data));
      notifyListeners();
      return TribeResult.success;
    } on ApiException catch (e) {
      return resultFrom(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Hoạt động nhóm
  // ---------------------------------------------------------------------------

  /// COM-07: tạo hoạt động nhóm. Server ghi mình là đã tham gia, người khác đang chờ.
  Future<TribeResult> createBlock({
    required String tribeId,
    required String task,
    String? description,
    required DateTime startUtc,
    required DateTime endUtc,
    required String colorCode,
  }) async {
    final draft = TribeBlockModel(
      id: '',
      tribeId: tribeId,
      createdBy: me,
      task: task.trim(),
      description: description?.trim(),
      startUtc: startUtc,
      endUtc: endUtc,
      colorCode: colorCode,
    );
    try {
      final data = await _api.post(
        '/tribes/$tribeId/blocks',
        draft.toRequest(),
      );
      _upsertBlock(TribeBlockModel.fromJson(data['block']));
      notifyListeners();
      return TribeResult.success;
    } on ApiException catch (e) {
      return resultFrom(e);
    }
  }

  /// COM-09: sửa hoạt động. Nếu đổi giờ, mọi người cần xác nhận lại.
  Future<TribeResult> updateBlock(TribeBlockModel updated) async {
    try {
      final data = await _api.put(
        '/tribe-blocks/${updated.id}',
        updated.toRequest(),
      );
      _upsertBlock(TribeBlockModel.fromJson(data));
      notifyListeners();
      return TribeResult.success;
    } on ApiException catch (e) {
      return resultFrom(e);
    }
  }

  /// COM-10: huỷ hoạt động nhóm.
  Future<TribeResult> deleteBlock(String blockId) async {
    try {
      await _api.delete('/tribe-blocks/$blockId');
      _blocks.removeWhere((b) => b.id == blockId);
      notifyListeners();
      return TribeResult.success;
    } on ApiException catch (e) {
      return resultFrom(e);
    }
  }

  /// COM-19: tham gia hoặc không tham gia. Server báo về cho trưởng và phó nhóm.
  Future<TribeResult> respond(String blockId, AttendanceStatus status) async {
    final block = blockById(blockId);
    if (block != null && block.statusOf(me) == status) {
      return TribeResult.success;
    }
    try {
      final data = await _api.put('/tribe-blocks/$blockId/attendance', {
        'status': status.value,
      });
      _upsertBlock(TribeBlockModel.fromJson(data));
      notifyListeners();
      return TribeResult.success;
    } on ApiException catch (e) {
      return resultFrom(e);
    }
  }

  final Set<String> _requestedBlocks = {};

  /// Hoạt động chưa có trên máy thì hỏi server một lần. Trả về true nếu đang tải,
  /// false nếu đã hỏi rồi mà không có (hoạt động đã bị huỷ).
  bool ensureBlock(String blockId) {
    if (blockById(blockId) != null) return false;
    if (!_requestedBlocks.add(blockId)) return false;
    fetchBlock(blockId);
    return true;
  }

  /// Lấy một hoạt động nhóm từ server (mở từ thông báo mà máy chưa có hoạt động đó).
  Future<TribeBlockModel?> fetchBlock(String blockId) async {
    try {
      final data = await _api.get('/tribe-blocks/$blockId');
      final block = TribeBlockModel.fromJson(data);
      _upsertBlock(block);
      notifyListeners();
      return block;
    } on ApiException {
      // Báo để giao diện thôi hiện vòng tải và ghi "hoạt động đã bị huỷ"
      notifyListeners();
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Nội bộ
  // ---------------------------------------------------------------------------

  /// Thêm nhóm mới hoặc thay nhóm cũ cùng id.
  void _upsertTribe(TribeModel tribe) {
    final i = _tribes.indexWhere((t) => t.id == tribe.id);
    if (i == -1) {
      _tribes.add(tribe);
    } else {
      _tribes[i] = tribe;
    }
  }

  /// Bỏ nhóm khỏi danh sách cùng các hoạt động của nhóm đó.
  void _removeTribeLocal(String tribeId) {
    _tribes.removeWhere((t) => t.id == tribeId);
    _blocks.removeWhere((b) => b.tribeId == tribeId);
    _busy.remove(tribeId);
  }

  /// Thêm hoạt động mới hoặc thay hoạt động cũ cùng id.
  void _upsertBlock(TribeBlockModel block) {
    final i = _blocks.indexWhere((b) => b.id == block.id);
    if (i == -1) {
      _blocks.add(block);
    } else {
      _blocks[i] = block;
    }
  }
}
