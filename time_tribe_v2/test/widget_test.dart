import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:time_tribe_v2/core/utils/app_time.dart';
import 'package:time_tribe_v2/features/template/models/template_model.dart';
import 'package:time_tribe_v2/features/template/viewmodels/template_viewmodel.dart';
import 'package:time_tribe_v2/features/template/views/widgets/apply_template_dialog.dart';
import 'package:time_tribe_v2/features/timeblock/viewmodels/timeblock_viewmodel.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(AppTime.ensureInitialized);
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

  testWidgets('Áp dụng mẫu chỉ đóng hộp thoại, không đóng màn hình phía dưới', (
    tester,
  ) async {
    final template = TemplateModel(
      id: 't1',
      userId: 'u1',
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

    final vm = TimeblockViewModel();
    dynamic result;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
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
    await tester.pump(const Duration(seconds: 1)); // mock data load

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add)); // lặp lại 2 tuần
    await tester.pumpAndSettle();
    await tester.tap(find.text('Áp dụng ngay'));
    await tester.pumpAndSettle();

    // Màn hình gốc vẫn còn -> không bị đen
    expect(find.text('open'), findsOneWidget);
    expect(find.byType(ApplyTemplateDialog), findsNothing);
    expect(result, isA<Map>());
    expect(result['added'], 7 * 2 * 2); // 7 ngày x 2 block x 2 tuần
    expect(vm.tasks.where((t) => t.task.startsWith('Việc')).length, 28);
  });

  group('Nhập lịch mẫu từ link', () {
    test('tách token từ nhiều dạng link', () {
      expect(
        TemplateViewModel.extractShareToken('https://timetribe.app/t/abc'),
        'abc',
      );
      expect(
        TemplateViewModel.extractShareToken('timetribe.app/t/abc/'),
        'abc',
      );
      expect(TemplateViewModel.extractShareToken('abc'), 'abc');
      expect(TemplateViewModel.extractShareToken('   '), isNull);
    });

    test('link không có mẫu -> NOT_FOUND, không thêm mẫu rỗng', () async {
      final vm = TemplateViewModel();
      final before = vm.templates.length;
      expect(
        await vm.importTemplateByLink('https://timetribe.app/t/khong-co'),
        TemplateImportResult.notFound,
      );
      expect(vm.templates.length, before);
    });

    test('link hợp lệ -> chép đủ hoạt động, nhập lại thì báo trùng', () async {
      final vm = TemplateViewModel();
      expect(
        await vm.importTemplateByLink('https://timetribe.app/t/study-week'),
        TemplateImportResult.success,
      );
      expect(vm.templates.last.blocks.length, 2);
      expect(
        await vm.importTemplateByLink('https://timetribe.app/t/study-week'),
        TemplateImportResult.duplicate,
      );
      expect(
        await vm.importTemplateByLink('https://timetribe.app/t/tpl-1'),
        TemplateImportResult.duplicate,
      );
    });
  });
}
