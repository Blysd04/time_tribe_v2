import 'l10n.dart';

extension ApiErrorTextX on AppLocalizations {
  /// Đổi mã lỗi backend trả về thành câu chữ cho người dùng.
  /// Mã nào chưa có câu riêng thì dùng câu chung "Có lỗi xảy ra".
  String apiError(String? code) => switch (code) {
    'network_error' => errorNetwork,
    'overlap' => errorOverlap,
    'past_date' || 'past_time' => errorPastDate,
    'duration_too_short' => errorMinDuration,
    'invalid_time' => errorEndBeforeStart,
    'invalid_task' => errorNameTooShort,
    'invalid_color' || 'invalid_remind' || 'validation_error' => errorServer,
    'not_allowed' => errorNotAllowed,
    'not_found_item' || 'not_found' => errorItemGone,
    'block_ended' => errorBlockEnded,
    _ => errorServer,
  };
}
