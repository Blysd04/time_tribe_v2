import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Định dạng ngày giờ theo ngôn ngữ đang chọn.
class Fmt {
  Fmt._();

  static String _locale(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  /// Giờ: "20:00" (vi, fr) hoặc "8:00 PM" (en).
  static String time(BuildContext context, DateTime dt) =>
      DateFormat.jm(_locale(context)).format(dt);

  static String tod(BuildContext context, TimeOfDay t) =>
      time(context, DateTime(2000, 1, 1, t.hour, t.minute));

  static String range(BuildContext context, DateTime start, DateTime end) =>
      '${time(context, start)} – ${time(context, end)}';

  static String todRange(
    BuildContext context,
    TimeOfDay start,
    TimeOfDay end,
  ) => '${tod(context, start)} – ${tod(context, end)}';

  /// "04/11/2026" (vi, fr) hoặc "11/4/2026" (en).
  static String date(BuildContext context, DateTime dt) =>
      DateFormat.yMd(_locale(context)).format(dt);

  /// "Thứ Tư, 4 tháng 11, 2026" ...
  static String longDate(BuildContext context, DateTime dt) {
    final s = DateFormat.yMMMMEEEEd(_locale(context)).format(dt);
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }

  /// "04/11" (vi, fr) hoặc "11/4" (en).
  static String dayMonth(BuildContext context, DateTime dt) =>
      DateFormat.Md(_locale(context)).format(dt);

  /// Nhãn giờ trên lưới thời gian: "09:00" hoặc "9 AM".
  static String hourLabel(BuildContext context, int hour) {
    final locale = _locale(context);
    final dt = DateTime(2000, 1, 1, hour);
    return locale == 'en'
        ? DateFormat.j('en').format(dt)
        : DateFormat.Hm(locale).format(dt);
  }
}
