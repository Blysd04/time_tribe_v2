import 'package:flutter/material.dart';
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
