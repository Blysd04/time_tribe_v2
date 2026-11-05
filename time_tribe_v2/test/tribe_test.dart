import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:time_tribe_v2/core/utils/app_time.dart';
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

import 'test_helpers.dart';

DateTime utc(int h, [int m = 0]) => DateTime.utc(2026, 11, 4, h, m);

void main() {
  setUpAll(AppTime.ensureInitialized);
  setUp(() => AppTime.useTimezone('Asia/Ho_Chi_Minh'));
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

  group('TribeViewModel', () {
    test('tối đa 5 nhóm', () {
      final vm = TribeViewModel();
      expect(vm.tribes.length, 3);
      expect(vm.createTribe('A').result, TribeResult.success);
      expect(vm.createTribe('B').result, TribeResult.success);
      expect(vm.createTribe('C').result, TribeResult.tribeLimit);
      expect(
        vm.joinByLink('timetribe.app/tribe/GAMEDEV26').result,
        TribeResult.tribeLimit,
      );
    });

    test('tạo nhóm thì mình là trưởng nhóm', () {
      final vm = TribeViewModel();
      final res = vm.createTribe('  Nhóm mới  ');
      expect(res.tribe!.name, 'Nhóm mới');
      expect(vm.myRoleIn(res.tribe!.id), TribeRole.leader);
      expect(vm.createTribe('   ').result, TribeResult.emptyName);
    });

    test('tham gia bằng link: các trường hợp lỗi và thành công', () {
      final vm = TribeViewModel();
      expect(vm.joinByLink('').result, TribeResult.invalidLink);
      expect(
        vm.joinByLink('timetribe.app/tribe/KHONGCO').result,
        TribeResult.notFound,
      );
      expect(
        vm.joinByLink('https://timetribe.app/tribe/FULLHOUSE').result,
        TribeResult.tribeFull,
      );
      expect(
        vm.joinByLink('https://timetribe.app/tribe/nic2026').result,
        TribeResult.alreadyMember,
      );

      final ok = vm.joinByLink('https://timetribe.app/tribe/gamedev26');
      expect(ok.result, TribeResult.success);
      expect(vm.myRoleIn(ok.tribe!.id), TribeRole.member);
      // Báo cho các thành viên cũ
      expect(vm.outbox.where((n) => n.type == 'tribe_join').length, 3);
    });

    test('bổ nhiệm phó nhóm tối đa 3 người', () {
      final vm = TribeViewModel();
      expect(vm.appointVice('t-nic', 'u-linh'), TribeResult.success);
      expect(vm.appointVice('t-nic', 'u-hana'), TribeResult.success);
      expect(vm.appointVice('t-nic', 'u-david'), TribeResult.viceLimit);
      expect(vm.dismissVice('t-nic', 'u-linh'), TribeResult.success);
      expect(vm.tribeById('t-nic')!.roleOf('u-linh'), TribeRole.member);
      expect(
        vm.outbox
            .where((n) => n.userId == 'u-linh' && n.type == 'tribe_role')
            .length,
        2,
      );
    });

    test('chuyển quyền trưởng nhóm: trưởng cũ thành phó (khi còn chỗ)', () {
      final vm = TribeViewModel();
      expect(vm.transferLeader('t-nic', 'u-linh'), TribeResult.success);
      final t = vm.tribeById('t-nic')!;
      expect(t.roleOf('u-linh'), TribeRole.leader);
      expect(t.roleOf('u-me'), TribeRole.viceLeader);
    });

    test('trưởng nhóm phải bổ nhiệm người mới trước khi rời', () {
      final vm = TribeViewModel();
      expect(vm.leaveTribe('t-nic'), TribeResult.needNewLeader);
      vm.transferLeader('t-nic', 'u-minh');
      expect(vm.leaveTribe('t-nic'), TribeResult.success);
      expect(vm.tribeById('t-nic'), isNull);
    });

    test('phó nhóm không được mời phó nhóm khác rời nhóm', () {
      final vm = TribeViewModel();
      // Trong Team Marketing mình là phó nhóm
      expect(vm.kickMember('t-marketing', 'u-hana'), TribeResult.notAllowed);
      expect(vm.kickMember('t-marketing', 'u-khoa'), TribeResult.success);
      expect(vm.renameTribe('t-marketing', 'X'), TribeResult.notAllowed);
    });

    test('thành viên không được tạo hoạt động; phản hồi báo về trưởng/phó', () {
      final vm = TribeViewModel();
      final now = DateTime.now().toUtc();
      expect(
        vm.createBlock(
          tribeId: 't-badminton',
          task: 'x',
          startUtc: now,
          endUtc: now.add(const Duration(hours: 1)),
          colorCode: '#000000',
        ),
        TribeResult.notAllowed,
      );

      vm.respond('tb-bad-1', AttendanceStatus.accepted);
      final notified = vm.outbox
          .where((n) => n.referenceType == 'tribe_block_response')
          .map((n) => n.userId)
          .toSet();
      expect(notified, {'u-mai', 'u-minh'}); // trưởng + phó nhóm
      expect(
        vm.blockById('tb-bad-1')!.statusOf('u-me'),
        AttendanceStatus.accepted,
      );
    });

    test('tạo hoạt động: mình tự tham gia, người khác chờ xác nhận', () {
      final vm = TribeViewModel();
      final start = DateTime.now().toUtc().add(const Duration(days: 3));
      vm.createBlock(
        tribeId: 't-nic',
        task: 'Demo',
        startUtc: start,
        endUtc: start.add(const Duration(hours: 1)),
        colorCode: '#3A86FF',
      );
      final b = vm.blocksOf('t-nic').firstWhere((b) => b.task == 'Demo');
      expect(b.statusOf('u-me'), AttendanceStatus.accepted);
      expect(b.userIdsWith(AttendanceStatus.pending).length, 5);
      expect(vm.outbox.where((n) => n.referenceId == b.id).length, 5);
      expect(b.remind, 60);
      expect(b.repeating, 'none');
    });

    test(
      'lịch bận chỉ tính hoạt động nhóm khác mà người đó ĐÃ nhận tham gia',
      () {
        final vm = TribeViewModel();
        final mkt = vm.blockById('tb-mkt-1')!; // Mai đã từ chối, Minh đã nhận
        final window = TimeRange(mkt.startUtc, mkt.endUtc);
        final busy = vm.busyByMember(
          vm.tribeById('t-badminton')!,
          window,
          myPersonalBlocks: const [],
        );
        bool coversBlock(String id) => (busy[id] ?? []).any(
          (r) => r.start == mkt.startUtc && r.end == mkt.endUtc,
        );
        expect(coversBlock('u-minh'), isTrue);
        expect(coversBlock('u-mai'), isFalse);
      },
    );

    test('lịch của thành viên ở Tokyo được quy đổi đúng sang giờ Việt Nam', () {
      final vm = TribeViewModel();
      // Thứ Tư 04/11/2026: Hana bận 9:00–18:00 giờ Tokyo = 7:00–16:00 giờ VN
      final day = TimeRange(
        AppTime.toUtc(DateTime(2026, 11, 4)),
        AppTime.toUtc(DateTime(2026, 11, 5)),
      );
      final busy = vm.busyByMember(
        vm.tribeById('t-nic')!,
        day,
        myPersonalBlocks: const [],
      );
      final hana = busy['u-hana']!.first;
      expect(AppTime.fromUtc(hana.start).hour, 7);
      expect(AppTime.fromUtc(hana.end).hour, 16);
    });
  });

  group('Giao diện', () {
    Widget app(Widget child, TribeViewModel vm) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: vm),
        ChangeNotifierProvider(create: (_) => TimeblockViewModel()),
      ],
      child: localizedApp(child),
    );

    testWidgets('danh sách nhóm hiện avatar +n và menu theo chức vụ', (
      tester,
    ) async {
      final vm = TribeViewModel();
      await tester.pumpWidget(app(const TribeListScreen(), vm));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Đồ án NIC'), findsOneWidget);
      expect(
        find.text('+5'),
        findsOneWidget,
      ); // Marketing: 8 người -> 3 avatar +5
      expect(find.text('3/5'), findsOneWidget);
    });

    testWidgets('trang chi tiết dựng được, thành viên không thấy nút tạo', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final vm = TribeViewModel();
      await tester.pumpWidget(
        app(const TribeDetailScreen(tribeId: 't-nic'), vm),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.byType(FloatingActionButton),
        findsOneWidget,
      ); // mình là trưởng nhóm
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        app(const TribeDetailScreen(tribeId: 't-badminton'), vm),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.byType(FloatingActionButton),
        findsNothing,
      ); // mình là thành viên

      // Mở danh sách thành viên: thành viên thường không thấy menu quản lý
      await tester.tap(find.byTooltip('Thành viên'));
      await tester.pumpAndSettle();
      expect(find.text('Rời nhóm'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Đợt cập nhật giao diện & đa ngôn ngữ', () {
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

    testWidgets(
      'dán link nhóm đã tham gia: báo rõ + nút Mở nhóm, không màn hình đỏ',
      (tester) async {
        final vm = TribeViewModel();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: vm),
              ChangeNotifierProvider(create: (_) => TimeblockViewModel()),
            ],
            child: localizedApp(
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
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField),
          'https://timetribe.app/tribe/NIC2026',
        );
        await tester.tap(find.text('Vào nhóm'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Đồ án NIC'), findsWidgets);
        expect(find.text('Mở nhóm'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Mở nhóm'));
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        expect(find.byType(TribeDetailScreen), findsOneWidget);
      },
    );

    test(
      'lịch cá nhân hiện hoạt động nhóm đã nhận + đang chờ, ẩn hoạt động đã từ chối',
      () {
        final vm = TribeViewModel();
        final mkt = vm.blockById('tb-mkt-1')!; // mình đã nhận
        final day = AppTime.fromUtc(mkt.startUtc);
        final ids = vm.tribeBlocksForMe(day).map((b) => b.block.id).toSet();
        expect(ids, contains('tb-mkt-1'));
        vm.respond('tb-mkt-1', AttendanceStatus.declined);
        expect(
          vm.tribeBlocksForMe(day).map((b) => b.block.id),
          isNot(contains('tb-mkt-1')),
        );
      },
    );

    test('nhân bản: phát hiện ngày bị trùng khung giờ', () async {
      final vm = TimeblockViewModel();
      await Future.delayed(const Duration(milliseconds: 600)); // dữ liệu mẫu
      final today = AppTime.today();
      // Dữ liệu mẫu có "Họp team" 9:00–10:30 hôm nay
      expect(
        vm.conflictsOn(
          today,
          const TimeOfDay(hour: 10, minute: 0),
          const TimeOfDay(hour: 11, minute: 0),
        ),
        isTrue,
      );
      expect(
        vm.conflictsOn(
          today,
          const TimeOfDay(hour: 6, minute: 0),
          const TimeOfDay(hour: 7, minute: 0),
        ),
        isFalse,
      );
    });

    test('thông báo: chỉ giữ 30 ngày, lọc theo nhóm', () {
      final n = NotificationViewModel(loadMock: false);
      n.push(
        AppNotification(
          id: 'a',
          kind: NotificationKind.tribeMemberJoined,
          type: 'tribe_join',
          tribeId: 't-nic',
        ),
      );
      n.push(
        AppNotification(
          id: 'old',
          kind: NotificationKind.tribeMemberJoined,
          type: 'tribe_join',
          tribeId: 't-nic',
          createdAt: DateTime.now().subtract(const Duration(days: 31)),
        ),
      );
      expect(n.filteredNotifications.map((e) => e.id), ['a']);
      n.setFilter('t-badminton');
      expect(n.filteredNotifications, isEmpty);
      n.setFilter(NotificationFilter.personal);
      expect(n.filteredNotifications, isEmpty);
    });

    test('xoá tài khoản: tự chuyển quyền trưởng nhóm rồi rời mọi nhóm', () {
      final vm = TribeViewModel();
      vm.leaveAllForAccountDeletion();
      expect(vm.tribes, isEmpty);
      // Nhóm mình làm trưởng (Đồ án NIC) được chuyển cho phó nhóm Minh
      expect(
        vm.outbox.any(
          (o) => o.userId == 'u-minh' && o.title == 'tribeRoleLeader',
        ),
        isTrue,
      );
    });

    testWidgets(
      'đổi ngôn ngữ: danh sách nhóm hiển thị tiếng Anh và tiếng Pháp',
      (tester) async {
        for (final (locale, text) in [
          (const Locale('en'), 'Your tribes'.toUpperCase()),
          (const Locale('fr'), 'Vos tribus'.toUpperCase()),
        ]) {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => TribeViewModel()),
                ChangeNotifierProvider(create: (_) => TimeblockViewModel()),
              ],
              child: localizedApp(
                const Scaffold(body: TribeListScreen()),
                locale: locale,
              ),
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          expect(find.text(text), findsOneWidget);
        }
      },
    );
  });
}
