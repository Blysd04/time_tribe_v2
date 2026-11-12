import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:time_tribe_v2/core/utils/app_time.dart';
import 'package:time_tribe_v2/features/timeblock/models/timeblock_model.dart';
import 'package:time_tribe_v2/features/timeblock/viewmodels/timeblock_viewmodel.dart';
import 'package:time_tribe_v2/features/tribe/models/tribe_block_model.dart';
import 'package:time_tribe_v2/features/tribe/models/tribe_model.dart';
import 'package:time_tribe_v2/features/tribe/services/availability_calculator.dart';
import 'package:time_tribe_v2/features/tribe/viewmodels/tribe_viewmodel.dart';
import 'package:time_tribe_v2/features/tribe/views/tribe_detail_screen.dart';
import 'package:time_tribe_v2/features/tribe/views/tribe_list_screen.dart';

import 'package:time_tribe_v2/core/utils/overlap_layout.dart';
import 'package:time_tribe_v2/features/notifications/models/app_notification.dart';
import 'package:time_tribe_v2/features/notifications/viewmodels/notification_viewmodel.dart';
import 'package:time_tribe_v2/features/tribe/views/tribe_dialogs.dart';

import 'fake_server.dart';
import 'test_helpers.dart';

DateTime utc(int h, [int m = 0]) => DateTime.utc(2026, 11, 4, h, m);

void main() {
  setUpAll(AppTime.ensureInitialized);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTime.useTimezone('Asia/Ho_Chi_Minh');
    signInAsMe();
  });
  tearDown(AppTime.useDeviceTimezone);

  group('AvailabilityCalculator', () {
    final window = TimeRange(utc(0), utc(24));

    test('gộp các đoạn có cùng người bận và tìm giờ rảnh chung', () {
      final busy = {
        'a': [TimeRange(utc(1), utc(3))],
        'b': [TimeRange(utc(2), utc(4))],
      };
      final segs = AvailabilityCalculator.segments(
        window,
        busy,
      ).where((s) => s.busyUserIds.isNotEmpty).toList();
      expect(segs.map((s) => s.busyUserIds.length), [1, 2, 1]);
      expect(segs[1].range.start, utc(2));
      expect(segs[1].range.end, utc(3));

      final free = AvailabilityCalculator.commonFreeSlots(window, busy);
      expect(free.first.end, utc(1));
      expect(free.last.start, utc(4));
    });

    test('tô màu ngày theo tỉ lệ bận', () {
      expect(AvailabilityCalculator.dayLoad(0.8), DayLoad.busy);
      expect(AvailabilityCalculator.dayLoad(0.5), DayLoad.half);
      expect(AvailabilityCalculator.dayLoad(0.2), DayLoad.free);
      expect(AvailabilityCalculator.dayLoad(0.4), DayLoad.neutral);
    });

    test('tỉ lệ bận không đếm trùng khi các lịch chồng nhau', () {
      final w = TimeRange(utc(0), utc(10));
      final ratio = AvailabilityCalculator.busyRatio(
        w,
        ['a'],
        {
          'a': [TimeRange(utc(0), utc(5)), TimeRange(utc(2), utc(5))],
        },
      );
      expect(ratio, 0.5);
    });

    test('đếm số thành viên bận trong ngày (>= 40% thời gian)', () {
      final w = TimeRange(utc(0), utc(10));
      final share = AvailabilityCalculator.busyMemberShare(
        w,
        ['a', 'b', 'c'],
        {
          'a': [TimeRange(utc(0), utc(5))], // 50% -> bận
          'b': [TimeRange(utc(0), utc(2))], // 20% -> rảnh
        },
      );
      expect(share, closeTo(1 / 3, 0.001));
    });
  });

  group('Quyền trong nhóm', () {
    test('trưởng nhóm quản lý mọi người, phó nhóm chỉ quản lý thành viên', () {
      expect(
        TribePermissions.canManageMember(
          TribeRole.leader,
          TribeRole.viceLeader,
        ),
        isTrue,
      );
      expect(
        TribePermissions.canManageMember(TribeRole.leader, TribeRole.leader),
        isFalse,
      );
      expect(
        TribePermissions.canManageMember(
          TribeRole.viceLeader,
          TribeRole.member,
        ),
        isTrue,
      );
      expect(
        TribePermissions.canManageMember(
          TribeRole.viceLeader,
          TribeRole.viceLeader,
        ),
        isFalse,
      );
      expect(
        TribePermissions.canManageMember(TribeRole.member, TribeRole.member),
        isFalse,
      );
      expect(TribePermissions.canRename(TribeRole.viceLeader), isFalse);
      expect(TribePermissions.canManageBlocks(TribeRole.viceLeader), isTrue);
      expect(TribePermissions.canManageBlocks(TribeRole.member), isFalse);
    });
  });

  // Dữ liệu server giả: Nga là trưởng nhóm NIC (6 người), thành viên CLB cầu lông,
  // phó nhóm Marketing (8 người).
  final now = DateTime.now().toUtc();
  final tomorrow = DateTime.utc(now.year, now.month, now.day + 1);
  final nic = tribeJson('t-nic', 'Đồ án NIC', 'NIC2026', [
    memberJson('t-nic', 'u-me', 'Tuyết Nga', 'leader'),
    memberJson('t-nic', 'u-minh', 'Minh Trần', 'vice_leader'),
    memberJson('t-nic', 'u-linh', 'Linh Phạm', 'member'),
    memberJson(
      't-nic',
      'u-hana',
      'Hana Sato',
      'member',
      timezone: 'Asia/Tokyo',
    ),
    memberJson('t-nic', 'u-david', 'David Nguyen', 'member'),
    memberJson('t-nic', 'u-an', 'An Lê', 'member'),
  ]);
  final badminton = tribeJson('t-badminton', 'CLB Cầu lông Q7', 'CAULONGQ7', [
    memberJson('t-badminton', 'u-mai', 'Mai Võ', 'leader'),
    memberJson('t-badminton', 'u-me', 'Tuyết Nga', 'member'),
  ]);
  final marketing = tribeJson('t-mkt', 'Team Marketing Global', 'MKTGLOBAL', [
    memberJson('t-mkt', 'u-linh', 'Linh Phạm', 'leader'),
    memberJson('t-mkt', 'u-me', 'Tuyết Nga', 'vice_leader'),
    for (final id in ['u-a', 'u-b', 'u-c', 'u-d', 'u-e', 'u-f'])
      memberJson('t-mkt', id, 'Người $id', 'member'),
  ]);

  /// Server giả có sẵn 3 nhóm và vài hoạt động nhóm ngày mai.
  FakeServer fakeServer() {
    final server = FakeServer();
    server.on('GET', '/tribes', (_) => [nic, badminton, marketing]);
    server.on('GET', '/tribes/*/blocks', (req) {
      final tribe = req.url.pathSegments[req.url.pathSegments.length - 2];
      return switch (tribe) {
        't-nic' => [
          blockJson(
            'b-nic',
            't-nic',
            'Họp chốt tiến độ',
            tomorrow.add(const Duration(hours: 13)),
            tomorrow.add(const Duration(hours: 14)),
            {'u-me': 'accepted', 'u-minh': 'pending'},
          ),
        ],
        't-badminton' => [
          blockJson(
            'b-bad',
            't-badminton',
            'Đánh cầu tối',
            tomorrow.add(const Duration(hours: 11)),
            tomorrow.add(const Duration(hours: 12)),
            {'u-mai': 'accepted', 'u-me': 'pending'},
            createdBy: 'u-mai',
          ),
        ],
        't-mkt' => [
          blockJson(
            'b-mkt',
            't-mkt',
            'Họp tuần',
            tomorrow.add(const Duration(hours: 8)),
            tomorrow.add(const Duration(hours: 9)),
            {'u-linh': 'accepted', 'u-me': 'accepted'},
            createdBy: 'u-linh',
          ),
        ],
        _ => [],
      };
    });
    return server;
  }

  /// Tạo TribeViewModel đã tải xong dữ liệu từ server giả.
  Future<(TribeViewModel, FakeServer)> loadedVm() async {
    final server = fakeServer();
    final vm = TribeViewModel(api: server.client());
    await vm.load();
    return (vm, server);
  }

  group('TribeViewModel gọi API', () {
    test(
      'tải nhóm và hoạt động: đếm hoạt động đang chờ mình trả lời',
      () async {
        final (vm, _) = await loadedVm();
        expect(vm.tribes.length, 3);
        expect(vm.myRoleIn('t-nic'), TribeRole.leader);
        expect(vm.pendingCountForMe('t-badminton'), 1);
        expect(vm.pendingCountForMe('t-nic'), 0);
        expect(vm.nextBlockOf('t-nic')!.task, 'Họp chốt tiến độ');
      },
    );

    test('tạo nhóm: tên rỗng báo lỗi ngay, không gọi server', () async {
      final (vm, server) = await loadedVm();
      expect((await vm.createTribe('   ')).result, TribeResult.emptyName);
      expect(server.calls.where((c) => c == 'POST /tribes'), isEmpty);

      server.on(
        'POST',
        '/tribes',
        (req) => tribeJson('t-new', 'Nhóm mới', 'ABCD2345', [
          memberJson('t-new', 'u-me', 'Tuyết Nga', 'leader'),
        ]),
      );
      final res = await vm.createTribe('  Nhóm mới  ');
      expect(res.result, TribeResult.success);
      expect(server.lastBody['/tribes'], {'name': 'Nhóm mới'});
      expect(vm.myRoleIn('t-new'), TribeRole.leader);
    });

    test('tối đa 5 nhóm thì không gọi server tạo thêm', () async {
      final server = fakeServer();
      server.on(
        'GET',
        '/tribes',
        (_) => [
          for (int i = 0; i < 5; i++)
            tribeJson('t$i', 'Nhóm $i', 'CODE$i', [
              memberJson('t$i', 'u-me', 'Tuyết Nga', 'leader'),
            ]),
        ],
      );
      final vm = TribeViewModel(api: server.client());
      await vm.load();
      expect(vm.canCreateOrJoin, isFalse);
      expect((await vm.createTribe('Nhóm 6')).result, TribeResult.tribeLimit);
    });

    test('tham gia bằng mã: đổi đúng mã lỗi của server', () async {
      final (vm, server) = await loadedVm();
      expect((await vm.joinByCode('')).result, TribeResult.invalidCode);

      server.on(
        'POST',
        '/tribes/join',
        (_) => throw const FakeError(409, 'tribe_full'),
      );
      expect((await vm.joinByCode('FULLHOUSE')).result, TribeResult.tribeFull);

      server.on(
        'POST',
        '/tribes/join',
        (_) =>
            throw const FakeError(409, 'already_member', {'tribe_id': 't-nic'}),
      );
      final already = await vm.joinByCode('nic2026');
      expect(already.result, TribeResult.alreadyMember);
      expect(already.tribe!.name, 'Đồ án NIC');

      server.on(
        'POST',
        '/tribes/join',
        (_) => throw const FakeError(404, 'not_found'),
      );
      expect((await vm.joinByCode('KHONGCO')).result, TribeResult.notFound);
    });

    test('trưởng nhóm rời nhóm khi chưa chọn người kế nhiệm', () async {
      final (vm, server) = await loadedVm();
      server.on(
        'POST',
        '/tribes/*/leave',
        (_) => throw const FakeError(409, 'need_new_leader'),
      );
      expect(await vm.leaveTribe('t-nic'), TribeResult.needNewLeader);
      expect(vm.tribeById('t-nic'), isNotNull);

      server.on('POST', '/tribes/*/leave', (_) => {'action': 'left'});
      expect(
        await vm.leaveTribe('t-nic', newLeaderId: 'u-minh'),
        TribeResult.success,
      );
      expect(server.lastBody['/tribes/t-nic/leave'], {
        'new_leader_id': 'u-minh',
      });
      expect(vm.tribeById('t-nic'), isNull);
    });

    test('trả lời hoạt động: từ chối thì ẩn khỏi lịch cá nhân', () async {
      final (vm, server) = await loadedVm();
      final day = AppTime.fromUtc(vm.blockById('b-bad')!.startUtc);
      expect(
        vm.tribeBlocksForMe(day).map((b) => b.block.id),
        contains('b-bad'),
      );

      server.on('PUT', '/tribe-blocks/*/attendance', (req) {
        final b = blockJson(
          'b-bad',
          't-badminton',
          'Đánh cầu tối',
          tomorrow.add(const Duration(hours: 11)),
          tomorrow.add(const Duration(hours: 12)),
          {'u-mai': 'accepted', 'u-me': 'declined'},
          createdBy: 'u-mai',
        );
        return b;
      });
      expect(
        await vm.respond('b-bad', AttendanceStatus.declined),
        TribeResult.success,
      );
      expect(server.lastBody['/tribe-blocks/b-bad/attendance'], {
        'status': 'declined',
      });
      expect(
        vm.tribeBlocksForMe(day).map((b) => b.block.id),
        isNot(contains('b-bad')),
      );
    });

    test('giờ bận: người khác lấy từ server, mình lấy lịch trên máy', () async {
      final (vm, server) = await loadedVm();
      // Hana ở Tokyo bận 9h-10h giờ Tokyo ngày mai = 0h-1h UTC
      server.on(
        'GET',
        '/tribes/*/busy',
        (_) => {
          'members': [
            {
              'user_id': 'u-hana',
              'busy': [
                {
                  'start': tomorrow.toIso8601String(),
                  'end': tomorrow
                      .add(const Duration(hours: 1))
                      .toIso8601String(),
                },
              ],
            },
          ],
        },
      );
      final localDay = AppTime.fromUtc(tomorrow.add(const Duration(hours: 12)));
      await vm.ensureBusyLoaded('t-nic', localDay);
      // Lịch cá nhân của mình 9h-10h giờ Việt Nam = 2h-3h UTC
      final personal = TimeblockModel(
        id: 'p1',
        userId: 'u-me',
        task: 'Học',
        date: DateTime(localDay.year, localDay.month, localDay.day),
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        colorCode: '#3A86FF',
      );
      final busy = vm.busyByMember(
        vm.tribeById('t-nic')!,
        TribeViewModel.dayWindow(localDay),
        myPersonalBlocks: [personal],
      );
      expect(busy['u-hana']!.single.start, tomorrow);
      final mine = busy['u-me']!;
      // Hoạt động Marketing mình đã nhận (8h-9h UTC) cũng tính là bận
      expect(mine.length, 2);
      expect(mine.first.start.hour, 2);
      expect(busy['u-linh'], isEmpty);
    });
  });

  group('Giao diện', () {
    Widget app(Widget child, TribeViewModel vm, FakeServer server) =>
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: vm),
            ChangeNotifierProvider(
              create: (_) => TimeblockViewModel(api: server.client()),
            ),
          ],
          child: localizedApp(child),
        );

    testWidgets('danh sách nhóm hiện avatar +n và số nhóm', (tester) async {
      final (vm, server) = await tester.runAsync(loadedVm) ?? (null, null);
      await tester.pumpWidget(app(const TribeListScreen(), vm!, server!));
      await tester.pump();
      expect(find.text('Đồ án NIC'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget); // Marketing 8 người: 3 avatar +5
      expect(find.text('3/5'), findsOneWidget);
    });

    testWidgets('trang chi tiết: thành viên thường không thấy nút tạo', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final (vm, server) = await tester.runAsync(loadedVm) ?? (null, null);
      server!.on('GET', '/tribes/*/busy', (_) => {'members': []});

      await tester.pumpWidget(
        app(const TribeDetailScreen(tribeId: 't-nic'), vm!, server),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(FloatingActionButton), findsOneWidget); // trưởng nhóm
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        app(const TribeDetailScreen(tribeId: 't-badminton'), vm, server),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(FloatingActionButton), findsNothing); // thành viên

      await tester.tap(find.byTooltip('Thành viên'));
      await tester.pumpAndSettle();
      expect(find.text('Rời nhóm'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nhập mã nhóm đã tham gia: báo rõ + nút Mở nhóm', (
      tester,
    ) async {
      final (vm, server) = await tester.runAsync(loadedVm) ?? (null, null);
      server!
        ..on(
          'POST',
          '/tribes/join',
          (_) => throw const FakeError(409, 'already_member', {
            'tribe_id': 't-nic',
          }),
        )
        ..on('GET', '/tribes/*/busy', (_) => {'members': []});
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showJoinTribeDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
          vm!,
          server,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'nic2026');
      await tester.runAsync(() async {
        await tester.tap(find.text('Vào nhóm'));
        await Future.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.textContaining('Đồ án NIC'), findsWidgets);
      expect(find.text('Mở nhóm'), findsOneWidget);

      await tester.tap(find.text('Mở nhóm'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.byType(TribeDetailScreen), findsOneWidget);
    });

    testWidgets('đổi ngôn ngữ: danh sách nhóm hiện tiếng Anh và tiếng Pháp', (
      tester,
    ) async {
      final (vm, server) = await tester.runAsync(loadedVm) ?? (null, null);
      for (final (locale, text) in [
        (const Locale('en'), 'Your tribes'.toUpperCase()),
        (const Locale('fr'), 'Vos tribus'.toUpperCase()),
      ]) {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: vm!),
              ChangeNotifierProvider(
                create: (_) => TimeblockViewModel(api: server!.client()),
              ),
            ],
            child: localizedApp(
              const Scaffold(body: TribeListScreen()),
              locale: locale,
            ),
          ),
        );
        await tester.pump();
        expect(find.text(text), findsOneWidget);
      }
    });
  });

  group('Linh tinh', () {
    test('OverlapLayout chia cột cho các khối trùng giờ', () {
      final slots = OverlapLayout.compute([
        (60, 120),
        (90, 150),
        (130, 200),
        (300, 360),
      ]);
      // 3 khối đầu chồng nhau thành 1 cụm -> 2 cột; khối cuối đứng riêng
      expect(slots[0].column, 0);
      expect(slots[1].column, 1);
      expect(slots[2].column, 0);
      expect(slots.take(3).every((s) => s.columns == 2), isTrue);
      expect(slots[3].columns, 1);
    });

    test('thông báo: đọc JSON server, giữ 30 ngày, lọc theo nhóm', () async {
      final server = FakeServer();
      final recent = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      final old = DateTime.now().toUtc().subtract(const Duration(days: 31));
      server.on(
        'GET',
        '/notifications',
        (_) => [
          {
            'id': 'a',
            'user_id': 'u-me',
            'title': 'tribeMemberJoined',
            'content':
                '{"actor":"An Lê","tribe":"Đồ án NIC","tribe_id":"t-nic"}',
            'type': 'tribe_join',
            'is_read': false,
            'created_at': recent.toIso8601String(),
            'kind': 'tribeMemberJoined',
            'args': {
              'actor': 'An Lê',
              'tribe': 'Đồ án NIC',
              'tribe_id': 't-nic',
            },
            'tribe_id': 't-nic',
          },
          {
            'id': 'old',
            'user_id': 'u-me',
            'title': 'tribeMemberJoined',
            'content': '{}',
            'type': 'tribe_join',
            'is_read': false,
            'created_at': old.toIso8601String(),
            'tribe_id': 't-nic',
          },
          {
            'id': 'sys',
            'user_id': null,
            'title': 'Bảo trì hệ thống',
            'content': 'Bảo trì từ 23:00',
            'type': 'system_broadcast',
            'is_read': false,
            'created_at': recent.toIso8601String(),
          },
        ],
      );
      server.on('PATCH', '/notifications/*/read', (_) => null);
      final n = NotificationViewModel(api: server.client());
      await n.load();
      expect(n.filteredNotifications.map((e) => e.id), ['a', 'sys']);
      expect(
        n.filteredNotifications.last.kind,
        NotificationKind.systemBroadcast,
      );
      n.setFilter('t-nic');
      expect(n.filteredNotifications.map((e) => e.id), ['a']);
      n.setFilter(NotificationFilter.personal);
      expect(n.filteredNotifications.map((e) => e.id), ['sys']);
      expect(n.unreadCount, 2);
      await n.markAsRead('a');
      expect(n.unreadCount, 1);
      expect(server.calls, contains('PATCH /notifications/a/read'));
      // Thông báo chung chỉ đổi trên máy, không gọi server
      await n.markAsRead('sys');
      expect(server.calls.where((c) => c.contains('sys')), isEmpty);
    });
  });
}
