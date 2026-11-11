/// Khoảng thời gian tuyệt đối (UTC), dùng để so lịch giữa các múi giờ.
class TimeRange {
  final DateTime start;
  final DateTime end;

  TimeRange(DateTime start, DateTime end)
    : start = start.toUtc(),
      end = end.toUtc();

  /// Độ dài của khoảng thời gian.
  Duration get duration => end.difference(start);

  /// Khoảng thời gian rỗng (kết thúc không sau bắt đầu).
  bool get isEmpty => !end.isAfter(start);

  /// Hai khoảng thời gian có giao nhau không.
  bool overlaps(TimeRange other) =>
      start.isBefore(other.end) && end.isAfter(other.start);

  /// Phần giao với [window]; null nếu không giao.
  TimeRange? clip(TimeRange window) {
    final s = start.isAfter(window.start) ? start : window.start;
    final e = end.isBefore(window.end) ? end : window.end;
    return e.isAfter(s) ? TimeRange(s, e) : null;
  }

  /// In ra cho dễ đọc khi debug.
  @override
  String toString() => 'TimeRange($start → $end)';
}

/// Một đoạn liên tục trong ngày mà tập người bận không đổi.
class AvailabilitySegment {
  final TimeRange range;
  final Set<String> busyUserIds;

  AvailabilitySegment(this.range, this.busyUserIds);

  /// Đoạn này có ai bận không, không ai bận là cả nhóm rảnh.
  bool get isEveryoneFree => busyUserIds.isEmpty;
}

/// Mức độ bận của cả nhóm trong 1 ngày (để tô màu thanh chọn ngày).
enum DayLoad {
  /// > 2/3 thành viên rảnh
  free,

  /// khoảng một nửa thành viên bận
  half,

  /// > 2/3 thành viên bận
  busy,

  /// chưa đủ rõ ràng / không có dữ liệu
  neutral,
}

class AvailabilityCalculator {
  AvailabilityCalculator._();

  /// Chia [window] thành các đoạn, mỗi đoạn biết ai đang bận.
  /// Các đoạn liền kề có cùng tập người bận sẽ được gộp lại.
  static List<AvailabilitySegment> segments(
    TimeRange window,
    Map<String, List<TimeRange>> busyByUser,
  ) {
    // Gom tất cả mốc thời gian (đã cắt theo cửa sổ)
    final clipped = <String, List<TimeRange>>{};
    final points = <DateTime>{window.start, window.end};
    busyByUser.forEach((userId, ranges) {
      for (final r in ranges) {
        final c = r.clip(window);
        if (c == null) continue;
        clipped.putIfAbsent(userId, () => []).add(c);
        points
          ..add(c.start)
          ..add(c.end);
      }
    });

    final sorted = points.toList()..sort();
    final result = <AvailabilitySegment>[];
    for (int i = 0; i < sorted.length - 1; i++) {
      final piece = TimeRange(sorted[i], sorted[i + 1]);
      if (piece.isEmpty) continue;
      final busy = <String>{};
      clipped.forEach((userId, ranges) {
        if (ranges.any((r) => r.overlaps(piece))) busy.add(userId);
      });

      if (result.isNotEmpty &&
          _sameSet(result.last.busyUserIds, busy) &&
          result.last.range.end == piece.start) {
        final last = result.removeLast();
        result.add(
          AvailabilitySegment(TimeRange(last.range.start, piece.end), busy),
        );
      } else {
        result.add(AvailabilitySegment(piece, busy));
      }
    }
    return result;
  }

  /// Các khoảng mà tất cả thành viên đều rảnh, dài tối thiểu [minDuration].
  static List<TimeRange> commonFreeSlots(
    TimeRange window,
    Map<String, List<TimeRange>> busyByUser, {
    Duration minDuration = const Duration(minutes: 30),
  }) {
    return segments(window, busyByUser)
        .where((s) => s.isEveryoneFree && s.range.duration >= minDuration)
        .map((s) => s.range)
        .toList();
  }

  /// Tỉ lệ thành viên "bận" trong ngày (0..1).
  /// Một người được tính là bận nếu lịch của họ chiếm từ [threshold]
  /// thời gian của [window] trở lên (mặc định 40% khung 7h-22h ≈ 6 tiếng).
  static double busyMemberShare(
    TimeRange window,
    List<String> memberIds,
    Map<String, List<TimeRange>> busyByUser, {
    double threshold = 0.4,
  }) {
    if (memberIds.isEmpty || window.isEmpty) return 0;
    final busyCount = memberIds.where((id) {
      final ratio =
          _busyMinutes(window, busyByUser[id] ?? const []) /
          window.duration.inMinutes;
      return ratio >= threshold;
    }).length;
    return busyCount / memberIds.length;
  }

  /// Tỉ lệ thời gian bận trung bình của nhóm trong [window] (0..1).
  static double busyRatio(
    TimeRange window,
    List<String> memberIds,
    Map<String, List<TimeRange>> busyByUser,
  ) {
    if (memberIds.isEmpty || window.isEmpty) return 0;
    double total = 0;
    for (final id in memberIds) {
      total +=
          _busyMinutes(window, busyByUser[id] ?? const []) /
          window.duration.inMinutes;
    }
    return total / memberIds.length;
  }

  /// Phân loại ngày theo tỉ lệ thành viên bận:
  /// > 2/3 bận -> đỏ, từ 1/2 -> vàng, < 1/3 bận (tức > 2/3 rảnh) -> xanh.
  static DayLoad dayLoad(double ratio) {
    if (ratio > 2 / 3) return DayLoad.busy;
    if (ratio >= 0.5) return DayLoad.half;
    if (ratio < 1 / 3) return DayLoad.free;
    return DayLoad.neutral;
  }

  /// Tổng số phút bận trong cửa sổ, các khoảng chồng nhau chỉ tính một lần.
  static int _busyMinutes(TimeRange window, List<TimeRange> ranges) {
    // Gộp các khoảng chồng nhau để không đếm trùng
    final parts =
        ranges.map((r) => r.clip(window)).whereType<TimeRange>().toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    int minutes = 0;
    DateTime? curStart;
    DateTime? curEnd;
    for (final p in parts) {
      if (curEnd == null || p.start.isAfter(curEnd)) {
        if (curStart != null) minutes += curEnd!.difference(curStart).inMinutes;
        curStart = p.start;
        curEnd = p.end;
      } else if (p.end.isAfter(curEnd)) {
        curEnd = p.end;
      }
    }
    if (curStart != null) minutes += curEnd!.difference(curStart).inMinutes;
    return minutes;
  }

  /// Hai tập người bận có giống nhau không.
  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
