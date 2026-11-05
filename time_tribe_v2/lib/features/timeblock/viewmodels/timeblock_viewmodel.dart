import 'package:flutter/material.dart';
import '../models/timeblock_model.dart';
import '../../../core/utils/app_time.dart';

/// Bộ lọc trên trang chủ Lịch cá nhân.
enum ScheduleFilter { all, personal, group }

class TimeblockViewModel extends ChangeNotifier {
  ScheduleFilter _filter = ScheduleFilter.all;
  ScheduleFilter get filter => _filter;

  void setFilter(ScheduleFilter f) {
    if (_filter == f) return;
    _filter = f;
    notifyListeners();
  }

  /// Ngày [date] đã có lịch cá nhân trùng với khung [start]–[end] chưa.
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
          t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day &&
          s < t.endTime.hour * 60 + t.endTime.minute &&
          e > t.startTime.hour * 60 + t.startTime.minute,
    );
  }

  List<TimeblockModel> _tasks = [];
  List<TimeblockModel> get tasks => _tasks;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Trạng thái lịch
  DateTime _selectedDate = AppTime.today();
  DateTime get selectedDate => _selectedDate;

  bool _isCalendarExpanded = false;
  bool get isCalendarExpanded => _isCalendarExpanded;

  // Giả lập ngày tạo tài khoản
  final DateTime _accountCreatedAt = AppTime.today().subtract(
    const Duration(days: 10),
  );
  DateTime get accountCreatedAt => _accountCreatedAt;

  // Mặc định cho người dùng 5 màu, sau này có thể lưu xuống SharedPreferences hoặc DB
  final List<String> _userColors = [
    '#3A86FF',
    '#FF007F',
    '#00F5D4',
    '#FFB703',
    '#9B5DE5',
  ];
  List<String> get userColors => _userColors;

  void updateUserColor(int index, String newHexCode) {
    if (index >= 0 && index < _userColors.length) {
      _userColors[index] = newHexCode;
      notifyListeners();
    }
  }

  // Kiểm tra xung đột thời gian
  bool isOverlapping(TimeblockModel newBlock) {
    int newStart = newBlock.startTime.hour * 60 + newBlock.startTime.minute;
    int newEnd = newBlock.endTime.hour * 60 + newBlock.endTime.minute;

    for (var block in _tasks) {
      // Bỏ qua chính nó khi đang ở chế độ Edit
      if (block.id == newBlock.id) continue;

      // Chỉ xét các block trong cùng một ngày
      if (block.date.year == newBlock.date.year &&
          block.date.month == newBlock.date.month &&
          block.date.day == newBlock.date.day) {
        int existStart = block.startTime.hour * 60 + block.startTime.minute;
        int existEnd = block.endTime.hour * 60 + block.endTime.minute;

        // Công thức kiểm tra đè nhau: (Start1 < End2) VÀ (End1 > Start2)
        if (newStart < existEnd && newEnd > existStart) {
          return true; // Phát hiện xung đột
        }
      }
    }
    return false; // An toàn
  }

  // Constructor: Tự động chạy khi ViewModel được tạo
  TimeblockViewModel() {
    _lastKnownToday = AppTime.today();
    AppTime.changes.addListener(_onTimezoneChanged);
    loadMockDataForDate(_selectedDate);
  }

  late DateTime _lastKnownToday;

  // Khi đổi múi giờ, "hôm nay" có thể đổi sang ngày khác.
  // Nếu người dùng đang xem "hôm nay" thì chuyển theo "hôm nay" mới.
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

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    AppTime.changes.removeListener(_onTimezoneChanged);
    super.dispose();
  }

  // Hàm tương tác lịch
  void changeSelectedDate(DateTime date) {
    if (_selectedDate.day == date.day &&
        _selectedDate.month == date.month &&
        _selectedDate.year == date.year) {
      return;
    }
    _selectedDate = date;
    notifyListeners();
    loadMockDataForDate(date); // Load lại dữ liệu khi đổi ngày
  }

  void toggleCalendar() {
    _isCalendarExpanded = !_isCalendarExpanded;
    notifyListeners();
  }

  // Đã nạp dữ liệu mẫu chưa (chỉ nạp 1 lần, tránh ghi đè các block
  // người dùng vừa thêm / vừa áp dụng từ Lịch mẫu khi đổi ngày)
  bool _mockSeeded = false;

  // Giả lập load dữ liệu từ DB cho ngày được chọn
  // TODO(backend): GET /timeblocks?date=yyyy-MM-dd rồi gộp vào _tasks
  void loadMockDataForDate(DateTime date) {
    _isLoading = true;
    notifyListeners();

    // Giả lập load API 0.5s
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_mockSeeded) {
        _isLoading = false;
        notifyListeners();
        return;
      }
      _mockSeeded = true;
      final today = AppTime.today();

      _tasks = [
        TimeblockModel(
          id: 'uuid-1',
          userId: 'user-id-123', // Tham số bắt buộc
          task: 'Họp team Backend Go & Flutter',
          description: 'Bàn về cấu trúc chuẩn hoá Time Grid',
          date: today,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 10, minute: 30),
          colorCode: '#3A86FF',
          repeating: 'none',
          remind: 15,
        ),
        TimeblockModel(
          id: 'uuid-2',
          userId: 'user-id-123',
          task: 'Code giao diện Time Grid động',
          date: today,
          startTime: const TimeOfDay(hour: 11, minute: 15),
          endTime: const TimeOfDay(
            hour: 14,
            minute: 0,
          ), // Block kéo dài xuyên trưa
          colorCode: '#FF007F',
          repeating: 'daily',
          remind: 10,
        ),
        TimeblockModel(
          id: 'uuid-3',
          userId: 'user-id-123',
          task: 'Tập Gym / Chạy bộ',
          date: today,
          startTime: const TimeOfDay(hour: 17, minute: 30),
          endTime: const TimeOfDay(hour: 19, minute: 0),
          colorCode: '#00F5D4',
          repeating: 'none',
          remind: 30,
        ),
      ];

      _isLoading = false;
      notifyListeners();
    });
  }

  void addTimeblock(TimeblockModel newBlock) {
    _tasks.add(newBlock);
    notifyListeners();
  }

  void updateTimeblock(TimeblockModel updatedBlock) {
    final index = _tasks.indexWhere((t) => t.id == updatedBlock.id);
    if (index != -1) {
      _tasks[index] = updatedBlock;
      notifyListeners();
    }
  }

  void deleteTimeblock(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  bool isColorDuplicate(String newHexCode, int currentIndex) {
    // Kiểm tra xem mã màu mới có tồn tại ở bất kỳ vị trí nào khác ngoài vị trí hiện tại không
    for (int i = 0; i < _userColors.length; i++) {
      if (i != currentIndex &&
          _userColors[i].toUpperCase() == newHexCode.toUpperCase()) {
        return true;
      }
    }
    return false;
  }

  void addTimeblocks(List<TimeblockModel> newBlocks) {
    _tasks.addAll(newBlocks);
    notifyListeners();
  }

  // 3. Xoá hàng loạt
  void deleteTimeblocks(List<String> ids) {
    _tasks.removeWhere((t) => ids.contains(t.id));
    notifyListeners();
  }

  // Trả về danh sách các công việc cũ bị trùng với khung giờ của block mới
  List<TimeblockModel> getConflictingBlocks(TimeblockModel newBlock) {
    List<TimeblockModel> conflicts = [];
    int newStart = newBlock.startTime.hour * 60 + newBlock.startTime.minute;
    int newEnd = newBlock.endTime.hour * 60 + newBlock.endTime.minute;

    for (var block in _tasks) {
      if (block.id == newBlock.id) continue;

      if (block.date.year == newBlock.date.year &&
          block.date.month == newBlock.date.month &&
          block.date.day == newBlock.date.day) {
        int existStart = block.startTime.hour * 60 + block.startTime.minute;
        int existEnd = block.endTime.hour * 60 + block.endTime.minute;

        if (newStart < existEnd && newEnd > existStart) {
          conflicts.add(block);
        }
      }
    }
    return conflicts;
  }
}
