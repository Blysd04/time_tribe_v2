import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/utils/app_time.dart';
import '../models/timeblock_model.dart';

/// Bộ lọc trên trang chủ Lịch cá nhân.
enum ScheduleFilter { all, personal, group }

/// Kết quả lưu một hoạt động cá nhân.
class TimeblockSaveResult {
  /// Mã lỗi server trả về (overlap, past_date...), null là lưu thành công.
  final String? error;

  /// Số bản nhân bản đã tạo được.
  final int copies;

  const TimeblockSaveResult({this.error, this.copies = 0});

  /// Lưu thành công hay không.
  bool get ok => error == null;
}

class TimeblockViewModel extends ChangeNotifier {
  TimeblockViewModel({ApiClient? api}) : _api = api ?? ApiClient.instance {
    _lastKnownToday = AppTime.today();
    AppTime.changes.addListener(_onTimezoneChanged);
    AppTime.scheduleShifted.addListener(_reloadAfterShift);
    _loadColors();
  }

  final ApiClient _api;
  static const _kColors = 'timeblock.colors';

  ScheduleFilter _filter = ScheduleFilter.all;

  /// Bộ lọc đang chọn trên trang chủ.
  ScheduleFilter get filter => _filter;

  /// Đổi bộ lọc Tất cả / Cá nhân / Nhóm trên trang chủ.
  void setFilter(ScheduleFilter f) {
    if (_filter == f) return;
    _filter = f;
    notifyListeners();
  }

  List<TimeblockModel> _tasks = [];

  /// Các hoạt động cá nhân đã tải về máy.
  List<TimeblockModel> get tasks => _tasks;

  bool _isLoading = false;

  /// Đang tải lịch từ server hay không.
  bool get isLoading => _isLoading;

  // Khoảng ngày đã tải về từ server, đổi ngày ra ngoài khoảng này thì tải thêm
  DateTime? _loadedFrom;
  DateTime? _loadedTo;

  // Trạng thái lịch
  DateTime _selectedDate = AppTime.today();

  /// Ngày đang xem trên lịch.
  DateTime get selectedDate => _selectedDate;

  bool _isCalendarExpanded = false;

  /// Lịch tháng đang mở rộng hay thu gọn.
  bool get isCalendarExpanded => _isCalendarExpanded;

  /// Ngày tạo tài khoản, lịch chỉ cho lùi về tới ngày này.
  DateTime get accountCreatedAt {
    final created = Session.currentUser?.createdAt;
    if (created == null) return AppTime.today();
    final local = AppTime.fromUtc(created.toUtc());
    return DateTime(local.year, local.month, local.day);
  }

  // Mặc định cho người dùng 5 màu, lưu trên máy (PT-05)
  final List<String> _userColors = [
    '#3A86FF',
    '#FF007F',
    '#00F5D4',
    '#FFB703',
    '#9B5DE5',
  ];

  /// Bảng 5 màu riêng của người dùng.
  List<String> get userColors => _userColors;

  /// Đọc bảng 5 màu đã lưu trên máy.
  Future<void> _loadColors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_kColors);
      if (saved != null && saved.length == _userColors.length) {
        _userColors.setAll(0, saved);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// PT-05: đổi một màu trong bảng 5 màu và lưu lại trên máy.
  void updateUserColor(int index, String newHexCode) {
    if (index >= 0 && index < _userColors.length) {
      _userColors[index] = newHexCode;
      notifyListeners();
      SharedPreferences.getInstance()
          .then((p) => p.setStringList(_kColors, _userColors))
          .catchError((_) => false);
    }
  }

  /// Màu mới có trùng với một ô màu khác (không tính ô đang sửa) không.
  bool isColorDuplicate(String newHexCode, int currentIndex) {
    for (int i = 0; i < _userColors.length; i++) {
      if (i != currentIndex &&
          _userColors[i].toUpperCase() == newHexCode.toUpperCase()) {
        return true;
      }
    }
    return false;
  }

  /// Ngày [date] đã có lịch cá nhân trùng với khung [start]-[end] chưa.
  bool conflictsOn(
    DateTime date,
    TimeOfDay start,
    TimeOfDay end, {
    String? ignoreId,
  }) {
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    return _tasks.any(
      (t) =>
          t.id != ignoreId &&
          _isSameDay(t.date, date) &&
          s < t.endTime.hour * 60 + t.endTime.minute &&
          e > t.startTime.hour * 60 + t.startTime.minute,
    );
  }

  /// Hoạt động mới có đè giờ hoạt động khác trong cùng ngày không (bỏ qua chính nó khi sửa).
  bool isOverlapping(TimeblockModel newBlock) => conflictsOn(
    newBlock.date,
    newBlock.startTime,
    newBlock.endTime,
    ignoreId: newBlock.id,
  );

  late DateTime _lastKnownToday;

  /// Khi đổi múi giờ, "hôm nay" có thể đổi sang ngày khác.
  /// Nếu người dùng đang xem "hôm nay" thì chuyển theo "hôm nay" mới.
  void _onTimezoneChanged() {
    final newToday = AppTime.today();
    final wasViewingToday = _isSameDay(_selectedDate, _lastKnownToday);
    _lastKnownToday = newToday;
    if (wasViewingToday && !_isSameDay(_selectedDate, newToday)) {
      changeSelectedDate(newToday);
    } else {
      notifyListeners();
    }
  }

  /// Đổi múi giờ xong: server đã tính lại ngày giờ của lịch cá nhân theo múi giờ mới
  /// (VD "Học 17:00" giờ Vancouver thành 16:00 giờ Los Angeles), tải lại khoảng đang có.
  Future<void> _reloadAfterShift() async {
    final from = _loadedFrom;
    final to = _loadedTo;
    _tasks = [];
    _loadedFrom = null;
    _loadedTo = null;
    if (from == null || to == null) {
      await ensureLoaded(_selectedDate);
    } else {
      await _fetch(from, to);
    }
  }

  /// Hai mốc thời gian có cùng một ngày không.
  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Dọn controller, listener khi lịch cá nhân bị đóng để không rò bộ nhớ.
  @override
  void dispose() {
    AppTime.changes.removeListener(_onTimezoneChanged);
    AppTime.scheduleShifted.removeListener(_reloadAfterShift);
    super.dispose();
  }

  /// Chọn ngày khác trên lịch, ngày đó chưa có dữ liệu thì tải thêm.
  void changeSelectedDate(DateTime date) {
    if (_isSameDay(_selectedDate, date)) return;
    _selectedDate = date;
    notifyListeners();
    ensureLoaded(date);
  }

  /// Mở hoặc thu gọn lịch tháng.
  void toggleCalendar() {
    _isCalendarExpanded = !_isCalendarExpanded;
    notifyListeners();
  }

  /// Tải lịch từ tháng trước tới tháng sau của ngày đang chọn (gọi sau khi đăng nhập).
  Future<void> load() async {
    _selectedDate = AppTime.today();
    _loadedFrom = null;
    _loadedTo = null;
    _tasks = [];
    await ensureLoaded(_selectedDate);
  }

  /// Đảm bảo đã có dữ liệu quanh [date] (tháng trước, tháng đó, tháng sau).
  /// Dùng cho lịch tháng và bảng chọn ngày nhân bản cần biết ngày nào đã bận.
  Future<void> ensureLoaded(DateTime date) async {
    final from = DateTime(date.year, date.month - 1, 1);
    final to = DateTime(date.year, date.month + 2, 0);
    if (_loadedFrom != null &&
        !from.isBefore(_loadedFrom!) &&
        !to.isAfter(_loadedTo!)) {
      return;
    }
    await _fetch(from, to);
  }

  /// Tải lại toàn bộ khoảng đã tải (sau khi áp dụng lịch mẫu chẳng hạn).
  Future<void> reload() async {
    if (_loadedFrom == null) return load();
    final from = _loadedFrom!, to = _loadedTo!;
    _loadedFrom = null;
    await _fetch(from, to);
  }

  /// Gọi GET /timeblocks?from=&to= rồi gộp vào danh sách đang có.
  Future<void> _fetch(DateTime from, DateTime to) async {
    if (Session.currentUserId.isEmpty) return;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _api.get(
        '/timeblocks',
        query: {
          'from': TimeblockModel.formatDate(from),
          'to': TimeblockModel.formatDate(to),
        },
      );
      final fresh = [for (final j in data as List) TimeblockModel.fromJson(j)];
      // Bỏ dữ liệu cũ trong khoảng vừa tải rồi thay bằng dữ liệu mới
      _tasks = [
        ..._tasks.where((t) => t.date.isBefore(from) || t.date.isAfter(to)),
        ...fresh,
      ];
      _loadedFrom = _loadedFrom == null || from.isBefore(_loadedFrom!)
          ? from
          : _loadedFrom;
      _loadedTo = _loadedTo == null || to.isAfter(_loadedTo!) ? to : _loadedTo;
    } on ApiException catch (e) {
      debugPrint('tải lịch cá nhân lỗi: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xoá dữ liệu khi đăng xuất.
  void clear() {
    _tasks = [];
    _loadedFrom = null;
    _loadedTo = null;
    _selectedDate = AppTime.today();
    _filter = ScheduleFilter.all;
    notifyListeners();
  }

  /// PT-01, PT-02: tạo mới hoặc sửa hoạt động, kèm danh sách ngày muốn nhân bản.
  /// Server tự bỏ qua ngày quá khứ hoặc đã có lịch trùng giờ.
  Future<TimeblockSaveResult> saveTimeblock(
    TimeblockModel block, {
    required bool isEditing,
    List<DateTime> duplicateDates = const [],
  }) async {
    try {
      final body = block.toRequest(duplicateDates: duplicateDates);
      final data = isEditing
          ? await _api.put('/timeblocks/${block.id}', body)
          : await _api.post('/timeblocks', body);
      final saved = TimeblockModel.fromJson(data['timeblock']);
      final copies = [
        for (final j in (data['copies'] as List? ?? const []))
          TimeblockModel.fromJson(j),
      ];
      _tasks = [..._tasks.where((t) => t.id != saved.id), saved, ...copies];
      notifyListeners();
      return TimeblockSaveResult(copies: copies.length);
    } on ApiException catch (e) {
      return TimeblockSaveResult(error: e.code);
    }
  }

  /// PT-04: xoá hoạt động cá nhân.
  Future<bool> deleteTimeblock(String id) async {
    try {
      await _api.delete('/timeblocks/$id');
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } on ApiException {
      return false;
    }
  }
}
