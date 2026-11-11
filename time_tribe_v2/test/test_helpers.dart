import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:time_tribe_v2/core/l10n/l10n.dart';

/// MaterialApp có đủ delegate đa ngôn ngữ để dựng widget trong test.
Widget localizedApp(Widget home, {Locale locale = const Locale('vi')}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('vi'), Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );

/// Cho thời gian thật trôi (để request giả trả về) rồi vẽ lại, lặp tới khi [done] đúng.
Future<void> pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 50 && !done(); i++) {
    await tester.runAsync(
      () => Future.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(done(), isTrue);
}
