import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';

export '../../l10n/gen/app_localizations.dart';

extension L10nX on BuildContext {
  /// Chuỗi đa ngôn ngữ: `context.l10n.save`
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension AppLocalizationsX on AppLocalizations {
  /// Tên thứ viết tắt, 1 = Thứ Hai ... 7 = Chủ Nhật.
  String weekdayShort(int weekday) => weekdaysShort.split(',')[weekday - 1];

  /// Tên thứ đầy đủ.
  String weekdayLong(int weekday) => weekdaysLong.split(',')[weekday - 1];

  /// "Tháng 11, 2026" / "November 2026" / "Novembre 2026"
  String monthYear(DateTime date) {
    final text = monthYearFormat(date);
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }
}
