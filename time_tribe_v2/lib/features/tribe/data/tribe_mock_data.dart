import '../../../core/utils/app_time.dart';
import '../models/tribe_block_model.dart';
import '../models/tribe_model.dart';
import '../services/availability_calculator.dart';

/// Dữ liệu giả lập cho tính năng Tribe.
/// Khi có backend, toàn bộ file này sẽ được thay bằng các lệnh gọi API.
class TribeMockData {
  TribeMockData._();

  static const users = <String, AppUser>{
    'u-me': AppUser(id: 'u-me', nickName: 'Tuyết Nga'),
    'u-minh': AppUser(id: 'u-minh', nickName: 'Minh Trần'),
    'u-linh': AppUser(id: 'u-linh', nickName: 'Linh Phạm'),
    'u-hana': AppUser(
      id: 'u-hana',
      nickName: 'Hana Sato',
      timezone: 'Asia/Tokyo',
    ),
    'u-david': AppUser(
      id: 'u-david',
      nickName: 'David Nguyen',
      timezone: 'America/Vancouver',
    ),
    'u-an': AppUser(id: 'u-an', nickName: 'An Lê'),
    'u-khoa': AppUser(
      id: 'u-khoa',
      nickName: 'Khoa Đỗ',
      timezone: 'Europe/London',
    ),
    'u-mai': AppUser(id: 'u-mai', nickName: 'Mai Võ'),
    'u-tuan': AppUser(id: 'u-tuan', nickName: 'Tuấn Hồ'),
    'u-vy': AppUser(
      id: 'u-vy',
      nickName: 'Vy Ngô',
      timezone: 'Australia/Sydney',
    ),
  };

  /// Lịch cá nhân lặp theo thứ (1 = Thứ Hai ... 7 = Chủ Nhật), tính theo
  /// múi giờ của chính người đó. Mỗi phần tử: [giờ bắt đầu, phút, giờ kết thúc, phút].
  static const Map<String, Map<int, List<List<int>>>> _weeklyBusy = {
    'u-minh': {
      1: [
        [8, 0, 12, 0],
        [13, 30, 17, 30],
      ],
      2: [
        [8, 0, 12, 0],
        [13, 30, 17, 30],
      ],
      3: [
        [8, 0, 12, 0],
        [13, 30, 17, 30],
      ],
      4: [
        [8, 0, 12, 0],
        [13, 30, 17, 30],
      ],
      5: [
        [8, 0, 12, 0],
        [13, 30, 16, 0],
      ],
      6: [
        [9, 0, 11, 0],
      ],
    },
    'u-linh': {
      1: [
        [7, 30, 11, 30],
        [14, 0, 18, 0],
      ],
      2: [
        [7, 30, 11, 30],
        [19, 0, 21, 0],
      ],
      3: [
        [7, 30, 11, 30],
        [14, 0, 18, 0],
      ],
      4: [
        [7, 30, 11, 30],
        [19, 0, 21, 0],
      ],
      5: [
        [7, 30, 11, 30],
        [14, 0, 17, 0],
      ],
    },
    'u-hana': {
      1: [
        [9, 0, 18, 0],
      ],
      2: [
        [9, 0, 18, 0],
      ],
      3: [
        [9, 0, 18, 0],
      ],
      4: [
        [9, 0, 18, 0],
      ],
      5: [
        [9, 0, 17, 0],
      ],
      6: [
        [10, 0, 12, 0],
      ],
    },
    'u-david': {
      1: [
        [9, 0, 17, 0],
      ],
      2: [
        [9, 0, 17, 0],
      ],
      3: [
        [9, 0, 17, 0],
      ],
      4: [
        [9, 0, 17, 0],
      ],
      5: [
        [9, 0, 15, 0],
      ],
    },
    'u-an': {
      1: [
        [8, 0, 11, 0],
        [19, 0, 20, 30],
      ],
      2: [
        [13, 0, 17, 0],
      ],
      3: [
        [8, 0, 11, 0],
        [19, 0, 20, 30],
      ],
      4: [
        [13, 0, 17, 0],
      ],
      5: [
        [8, 0, 11, 0],
      ],
      7: [
        [9, 0, 11, 0],
      ],
    },
    'u-khoa': {
      1: [
        [9, 0, 17, 30],
      ],
      2: [
        [9, 0, 17, 30],
      ],
      3: [
        [9, 0, 17, 30],
      ],
      4: [
        [9, 0, 17, 30],
      ],
      5: [
        [9, 0, 16, 0],
      ],
    },
    'u-mai': {
      1: [
        [9, 0, 12, 0],
        [18, 0, 21, 0],
      ],
      2: [
        [9, 0, 12, 0],
      ],
      3: [
        [9, 0, 12, 0],
        [18, 0, 21, 0],
      ],
      4: [
        [9, 0, 12, 0],
      ],
      5: [
        [9, 0, 12, 0],
        [18, 0, 21, 0],
      ],
      6: [
        [18, 0, 21, 0],
      ],
    },
  };

  /// Lịch cá nhân (đã quy về UTC) của 1 người khác trong khoảng [window].
  /// TODO(backend): GET /tribes/{id}/availability?from=&to= (server chỉ trả
  /// về khoảng bận, KHÔNG trả nội dung lịch riêng để bảo vệ quyền riêng tư).
  static List<TimeRange> personalBusyOf(String userId, TimeRange window) {
    final pattern = _weeklyBusy[userId];
    final user = users[userId];
    if (pattern == null || user == null) return const [];

    final result = <TimeRange>[];
    // Duyệt các ngày theo giờ địa phương của người đó, bao trùm cả cửa sổ
    final firstLocal = AppTime.fromUtc(window.start, timezoneId: user.timezone);
    for (int d = -1; d <= window.duration.inDays + 1; d++) {
      final day = DateTime(
        firstLocal.year,
        firstLocal.month,
        firstLocal.day + d,
      );
      for (final slot in pattern[day.weekday] ?? const <List<int>>[]) {
        final start = AppTime.toUtc(
          DateTime(day.year, day.month, day.day, slot[0], slot[1]),
          timezoneId: user.timezone,
        );
        final end = AppTime.toUtc(
          DateTime(day.year, day.month, day.day, slot[2], slot[3]),
          timezoneId: user.timezone,
        );
        final clipped = TimeRange(start, end).clip(window);
        if (clipped != null) result.add(clipped);
      }
    }
    return result;
  }

  static TribeMember _m(String tribeId, String userId, TribeRole role) =>
      TribeMember(
        id: '$tribeId-$userId',
        tribeId: tribeId,
        user: users[userId]!,
        role: role,
      );

  static List<TribeModel> tribes() => [
    TribeModel(
      id: 't-nic',
      name: 'Đồ án NIC',
      createdBy: 'u-me',
      inviteCode: 'NIC2026',
      backgroundColor: '#3A86FF',
      members: [
        _m('t-nic', 'u-me', TribeRole.leader),
        _m('t-nic', 'u-minh', TribeRole.viceLeader),
        _m('t-nic', 'u-linh', TribeRole.member),
        _m('t-nic', 'u-hana', TribeRole.member),
        _m('t-nic', 'u-david', TribeRole.member),
        _m('t-nic', 'u-an', TribeRole.member),
      ],
    ),
    TribeModel(
      id: 't-badminton',
      name: 'CLB Cầu lông Q7',
      createdBy: 'u-mai',
      inviteCode: 'CAULONGQ7',
      backgroundColor: '#00B894',
      members: [
        _m('t-badminton', 'u-mai', TribeRole.leader),
        _m('t-badminton', 'u-minh', TribeRole.viceLeader),
        _m('t-badminton', 'u-me', TribeRole.member),
        _m('t-badminton', 'u-an', TribeRole.member),
      ],
    ),
    TribeModel(
      id: 't-marketing',
      name: 'Team Marketing Global',
      createdBy: 'u-linh',
      inviteCode: 'MKTGLOBAL',
      backgroundColor: '#9B5DE5',
      members: [
        _m('t-marketing', 'u-linh', TribeRole.leader),
        _m('t-marketing', 'u-me', TribeRole.viceLeader),
        _m('t-marketing', 'u-hana', TribeRole.viceLeader),
        _m('t-marketing', 'u-david', TribeRole.member),
        _m('t-marketing', 'u-khoa', TribeRole.member),
        _m('t-marketing', 'u-an', TribeRole.member),
        _m('t-marketing', 'u-mai', TribeRole.member),
        _m('t-marketing', 'u-minh', TribeRole.member),
      ],
    ),
  ];

  /// Các nhóm "trên server" mà người dùng có thể tham gia bằng link.
  static Map<String, TribeModel> joinableTribes() => {
    'GAMEDEV26': TribeModel(
      id: 't-gamedev',
      name: 'Hội Game Dev',
      createdBy: 'u-tuan',
      inviteCode: 'GAMEDEV26',
      backgroundColor: '#FF7F50',
      members: [
        _m('t-gamedev', 'u-tuan', TribeRole.leader),
        _m('t-gamedev', 'u-vy', TribeRole.viceLeader),
        _m('t-gamedev', 'u-khoa', TribeRole.member),
      ],
    ),
    'FULLHOUSE': TribeModel(
      id: 't-full',
      name: 'Nhóm đã đủ người',
      createdBy: 'u-tuan',
      inviteCode: 'FULLHOUSE',
      members: [
        for (final (i, id) in [
          'u-tuan',
          'u-vy',
          'u-khoa',
          'u-mai',
          'u-an',
          'u-minh',
          'u-linh',
          'u-hana',
          'u-david',
          'u-x',
        ].indexed)
          TribeMember(
            id: 't-full-$id',
            tribeId: 't-full',
            user: users[id] ?? AppUser(id: id, nickName: 'Thành viên ${i + 1}'),
            role: i == 0 ? TribeRole.leader : TribeRole.member,
          ),
      ],
    ),
  };

  /// Hoạt động nhóm mẫu, xếp theo giờ Việt Nam cho dễ hình dung.
  static List<TribeBlockModel> blocks() {
    final vnNow = AppTime.nowIn('Asia/Ho_Chi_Minh');
    DateTime vn(int dayOffset, int h, int m) => AppTime.toUtc(
      DateTime(vnNow.year, vnNow.month, vnNow.day + dayOffset, h, m),
      timezoneId: 'Asia/Ho_Chi_Minh',
    );

    TribeBlockModel block({
      required String id,
      required String tribeId,
      required String createdBy,
      required String task,
      String? description,
      required TribeBlockType type,
      required DateTime start,
      required DateTime end,
      required String color,
      required Map<String, AttendanceStatus> attendance,
    }) => TribeBlockModel(
      id: id,
      tribeId: tribeId,
      createdBy: createdBy,
      task: task,
      description: description,
      blockType: type,
      startUtc: start,
      endUtc: end,
      colorCode: color,
      attendance: [
        for (final e in attendance.entries)
          TribeBlockAttendance(
            id: '$id-${e.key}',
            tribeBlockId: id,
            userId: e.key,
            status: e.value,
          ),
      ],
    );

    const a = AttendanceStatus.accepted;
    const d = AttendanceStatus.declined;
    const p = AttendanceStatus.pending;

    return [
      block(
        id: 'tb-nic-1',
        tribeId: 't-nic',
        createdBy: 'u-me',
        task: 'Họp chốt tiến độ',
        description:
            'Mọi người cập nhật phần việc của mình trước buổi họp nhé.',
        type: TribeBlockType.meeting,
        start: vn(0, 20, 0),
        end: vn(0, 21, 0),
        color: '#3A86FF',
        attendance: {
          'u-me': a,
          'u-minh': a,
          'u-linh': a,
          'u-hana': p,
          'u-david': d,
          'u-an': p,
        },
      ),
      block(
        id: 'tb-nic-2',
        tribeId: 't-nic',
        createdBy: 'u-minh',
        task: 'Code review sprint 3',
        type: TribeBlockType.work,
        start: vn(2, 21, 0),
        end: vn(2, 22, 30),
        color: '#FFB703',
        attendance: {
          'u-me': a,
          'u-minh': a,
          'u-linh': p,
          'u-hana': a,
          'u-david': p,
          'u-an': p,
        },
      ),
      block(
        id: 'tb-bad-1',
        tribeId: 't-badminton',
        createdBy: 'u-mai',
        task: 'Đánh cầu tối',
        description: 'Sân Phú Mỹ, nhớ mang vợt nha.',
        type: TribeBlockType.entertainment,
        start: vn(1, 18, 30),
        end: vn(1, 20, 30),
        color: '#00B894',
        attendance: {'u-mai': a, 'u-minh': a, 'u-me': p, 'u-an': d},
      ),
      block(
        id: 'tb-mkt-1',
        tribeId: 't-marketing',
        createdBy: 'u-linh',
        task: 'Họp tuần Marketing',
        type: TribeBlockType.meeting,
        start: vn(0, 15, 0),
        end: vn(0, 16, 0),
        color: '#9B5DE5',
        attendance: {
          'u-linh': a,
          'u-me': a,
          'u-hana': a,
          'u-david': p,
          'u-khoa': a,
          'u-an': p,
          'u-mai': d,
          'u-minh': a,
        },
      ),
    ];
  }
}
