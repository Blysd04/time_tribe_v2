import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:time_tribe_v2/core/api/api_client.dart';
import 'package:time_tribe_v2/core/session/session.dart';
import 'package:time_tribe_v2/core/utils/app_time.dart';
import 'package:time_tribe_v2/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:time_tribe_v2/features/template/models/template_model.dart';
import 'package:time_tribe_v2/features/template/viewmodels/template_viewmodel.dart';
import 'package:time_tribe_v2/features/template/views/widgets/apply_template_dialog.dart';
import 'package:time_tribe_v2/features/timeblock/models/timeblock_model.dart';
import 'package:time_tribe_v2/features/timeblock/viewmodels/timeblock_viewmodel.dart';

import 'fake_server.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(AppTime.ensureInitialized);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    signInAsMe();
  });
  tearDown(AppTime.useDeviceTimezone);

  group('AppTime', () {
    test('chế độ tự động dùng đúng đồng hồ của thiết bị', () {
      AppTime.useDeviceTimezone();
      final device = DateTime.now();
      final app = AppTime.now();
      expect(app.difference(device).inSeconds.abs() <= 1, isTrue);
      expect(AppTime.currentOffset, device.timeZoneOffset);
    });

    test('chế độ thủ công đổi giờ theo múi giờ IANA đã chọn', () {
      expect(AppTime.useTimezone('Asia/Tokyo'), isTrue);
      final utc = DateTime.now().toUtc();
      final tokyo = AppTime.now();
      // Tokyo = UTC+9, không có giờ mùa hè
      final expected = utc.add(const Duration(hours: 9));
      expect(tokyo.hour, expected.hour);
      expect(tokyo.day, expected.day);
      expect(tokyo.isUtc, isFalse);
      expect(AppTime.currentOffset, const Duration(hours: 9));
    });

    test('múi giờ không hợp lệ bị từ chối', () {
      expect(AppTime.useTimezone('Not/AZone'), isFalse);
      expect(AppTime.isAuto, isTrue);
    });

    test('định dạng GMT', () {
      expect(AppTime.formatOffset(const Duration(hours: 7)), 'GMT+07:00');
      expect(AppTime.formatOffset(const Duration(hours: -8)), 'GMT-08:00');
      expect(
        AppTime.formatOffset(const Duration(hours: 5, minutes: 30)),
        'GMT+05:30',
      );
    });
  });

  testWidgets('Áp dụng mẫu bị trùng giờ: hỏi thay thế, xong chỉ đóng hộp thoại', (
    tester,
  ) async {
    final template = TemplateModel(
      id: 't1',
      userId: 'u-me',
      templateName: 'Mẫu test',
      blocks: [
        for (int day = 1; day <= 7; day++)
          for (int h = 0; h < 2; h++)
            TemplateBlockModel(
              id: 'b$day$h',
              templateId: 't1',
              dayIndex: day,
              title: 'Việc $day-$h',
              startTime: TimeOfDay(hour: 1 + h, minute: 0),
              endTime: TimeOfDay(hour: 1 + h, minute: 30),
              colorCode: '#3A86FF',
            ),
      ],
    );

    final server = FakeServer();
    final today = AppTime.today();
    server.on('POST', '/templates/*/apply', (req) {
      final body = server.lastBody['/templates/t1/apply'];
      if (body['replace_conflicts'] != true) {
        throw FakeError(409, 'conflict', {
          'conflict_count': 2,
          'conflict_dates': [TimeblockModel.formatDate(today)],
        });
      }
      return {'added': 28, 'overwritten': 2};
    });
    server.on(
      'GET',
      '/timeblocks',
      (_) => [
        {
          'id': 'x1',
          'user_id': 'u-me',
          'task': 'Việc 1-0',
          'date': TimeblockModel.formatDate(today),
          'start_time': '01:00:00',
          'end_time': '01:30:00',
          'color_code': '#3A86FF',
          'remind': 15,
        },
      ],
    );
    final api = server.client();
    final timeblocks = TimeblockViewModel(api: api);
    final templates = TemplateViewModel(api: api);
    dynamic result;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: timeblocks),
          ChangeNotifierProvider.value(value: templates),
        ],
        child: localizedApp(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showDialog(
                      context: context,
                      builder: (_) => ApplyTemplateDialog(template: template),
                    );
                  },
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
    await tester.tap(find.byIcon(Icons.add)); // lặp lại 2 tuần
    await tester.pumpAndSettle();
    await tester.tap(find.text('Áp dụng ngay'));
    // Hộp thoại đang quay vòng tải nên không dùng pumpAndSettle, chờ tới khi hiện câu hỏi
    await pumpUntil(
      tester,
      () => find.text('Thay thế & thêm').evaluate().isNotEmpty,
    );
    // Bị trùng giờ -> hỏi "Thay thế & thêm"
    await tester.tap(find.text('Thay thế & thêm'));
    await pumpUntil(
      tester,
      () => find.byType(ApplyTemplateDialog).evaluate().isEmpty,
    );

    // Màn hình gốc vẫn còn, hộp thoại đã đóng
    expect(find.text('open'), findsOneWidget);
    expect(find.byType(ApplyTemplateDialog), findsNothing);
    expect(result, {'added': 28, 'overwritten': 2});
    expect(server.lastBody['/templates/t1/apply']['weeks'], 2);
    // Áp dụng xong thì tải lại lịch cá nhân
    expect(timeblocks.tasks.single.task, 'Việc 1-0');
  });

  group('Lịch mẫu', () {
    test('nhập bằng mã: đổi đúng mã lỗi server', () async {
      final server = FakeServer();
      final vm = TemplateViewModel(api: server.client());
      expect(await vm.importByCode('  '), TemplateImportResult.invalidCode);

      server.on(
        'POST',
        '/templates/import',
        (_) => throw const FakeError(404, 'not_found'),
      );
      expect(await vm.importByCode('KHONGCO'), TemplateImportResult.notFound);
      expect(vm.templates, isEmpty);

      server.on(
        'POST',
        '/templates/import',
        (_) => {
          'id': 'new',
          'user_id': 'u-me',
          'original_template_id': 'src',
          'template_name': 'Tuần ôn thi cuối kỳ',
          'share_code': null,
          'blocks': [
            {
              'id': 'b1',
              'template_id': 'new',
              'day_index': 1,
              'title': 'Ôn Toán',
              'start_time': '19:00:00',
              'end_time': '21:00:00',
              'color_code': '#3A86FF',
              'remind': 15,
            },
          ],
        },
      );
      expect(await vm.importByCode('studyweek'), TemplateImportResult.success);
      expect(server.lastBody['/templates/import'], {'share_code': 'studyweek'});
      expect(vm.templates.single.blocks.single.title, 'Ôn Toán');

      server.on(
        'POST',
        '/templates/import',
        (_) => throw const FakeError(409, 'duplicate'),
      );
      expect(
        await vm.importByCode('STUDYWEEK'),
        TemplateImportResult.duplicate,
      );
    });

    test('lưu mẫu mới gửi tên và danh sách khối', () async {
      final server = FakeServer();
      server.on(
        'POST',
        '/templates',
        (_) => {
          'id': 'srv-1',
          'user_id': 'u-me',
          'template_name': 'HK1',
          'share_code': null,
          'blocks': [],
        },
      );
      final vm = TemplateViewModel(api: server.client());
      final err = await vm.saveTemplate(
        TemplateModel(
          id: '',
          userId: 'u-me',
          templateName: 'HK1',
          blocks: [
            TemplateBlockModel(
              id: 'local',
              templateId: '',
              dayIndex: 2,
              title: 'Lập trình Go',
              startTime: const TimeOfDay(hour: 7, minute: 30),
              endTime: const TimeOfDay(hour: 9, minute: 30),
              colorCode: '#3A86FF',
            ),
          ],
        ),
        isNew: true,
      );
      expect(err, isNull);
      final body = server.lastBody['/templates'];
      expect(body['template_name'], 'HK1');
      expect(body['blocks'][0]['start_time'], '07:30:00');
      expect(vm.templates.single.id, 'srv-1');
    });
  });

  group('Đăng nhập và phiên', () {
    test('đăng nhập thành công lưu phiên, sai mật khẩu báo đúng ô', () async {
      Session.clear();
      final server = FakeServer();
      server.on('POST', '/auth/login', (_) {
        final body = server.lastBody['/auth/login'];
        if (body['password'] != '123456') {
          throw const FakeError(401, 'wrong_credentials');
        }
        return {
          'access_token': 'a1',
          'refresh_token': 'r1',
          'token_type': 'Bearer',
          'expires_in': 3600,
          'user': {
            'id': 'u-me',
            'email': 'tuyetnga@timetribe.app',
            'nick_name': 'Tuyết Nga',
            'timezone': 'Asia/Ho_Chi_Minh',
            'fcm_token': null,
            'role': 'customer',
          },
        };
      });
      final vm = AuthViewModel(api: server.client());
      expect(await vm.login('tuyetnga@timetribe.app', 'sai'), isFalse);
      expect(vm.passwordError, AuthError.wrongCredentials);
      expect(Session.currentUserId, isEmpty);

      expect(await vm.login('tuyetnga@timetribe.app', '123456'), isTrue);
      expect(Session.currentUserId, 'u-me');
      // Trên máy test không có Firebase nên fcm_token gửi lên là chuỗi rỗng
      expect(server.lastBody['/auth/login']['fcm_token'], '');
    });

    test('token hết hạn thì tự làm mới rồi gửi lại request', () async {
      final server = FakeServer();
      var refreshed = false;
      server.on('POST', '/auth/refresh', (_) {
        refreshed = true;
        return {'access_token': 'new', 'refresh_token': 'r2'};
      });
      server.on('GET', '/users/me', (req) {
        if (req.headers['Authorization'] != 'Bearer new') {
          throw const FakeError(401, 'invalid_token');
        }
        return {'id': 'u-me', 'nick_name': 'Tuyết Nga'};
      });
      final api = server.client();
      final me = await api.get('/users/me');
      expect(refreshed, isTrue);
      expect(me['nick_name'], 'Tuyết Nga');
    });

    test('đăng nhập ở máy khác: báo phiên kết thúc và xoá token', () async {
      final server = FakeServer();
      server.on(
        'GET',
        '/users/me',
        (_) => throw const FakeError(401, 'session_ended'),
      );
      final api = server.client();
      String? ended;
      api.onSessionEnded = (code) => ended = code;
      await expectLater(api.get('/users/me'), throwsA(isA<ApiException>()));
      expect(ended, 'session_ended');
      expect(api.hasSession, isFalse);
    });
  });

  group('Lịch cá nhân', () {
    test(
      'lưu hoạt động gửi kèm ngày nhân bản, thêm cả bản sao vào lịch',
      () async {
        final server = FakeServer();
        final day = DateTime(2030, 1, 7);
        Map<String, dynamic> row(String id, DateTime d) => {
          'id': id,
          'user_id': 'u-me',
          'task': 'Học tiếng Nhật',
          'date': TimeblockModel.formatDate(d),
          'start_time': '06:00:00',
          'end_time': '07:00:00',
          'color_code': '#9B5DE5',
          'remind': 10,
        };
        server.on(
          'POST',
          '/timeblocks',
          (_) => {
            'timeblock': row('main', day),
            'copies': [row('copy', day.add(const Duration(days: 1)))],
            'skipped_dates': [],
          },
        );
        final vm = TimeblockViewModel(api: server.client());
        final res = await vm.saveTimeblock(
          TimeblockModel(
            id: '',
            userId: 'u-me',
            task: 'Học tiếng Nhật',
            date: day,
            startTime: const TimeOfDay(hour: 6, minute: 0),
            endTime: const TimeOfDay(hour: 7, minute: 0),
            colorCode: '#9B5DE5',
            remind: 10,
          ),
          isEditing: false,
          duplicateDates: [day.add(const Duration(days: 1))],
        );
        expect(res.ok, isTrue);
        expect(res.copies, 1);
        expect(server.lastBody['/timeblocks']['repeating_dates'], [
          '2030-01-08',
        ]);
        expect(vm.tasks.length, 2);
        // Ngày hôm sau đã có lịch trùng giờ
        expect(
          vm.conflictsOn(
            day.add(const Duration(days: 1)),
            const TimeOfDay(hour: 6, minute: 30),
            const TimeOfDay(hour: 8, minute: 0),
          ),
          isTrue,
        );

        server.on(
          'POST',
          '/timeblocks',
          (_) => throw const FakeError(409, 'overlap'),
        );
        final dup = await vm.saveTimeblock(vm.tasks.first, isEditing: false);
        expect(dup.error, 'overlap');
      },
    );
  });
}
