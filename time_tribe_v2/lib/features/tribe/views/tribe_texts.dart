import '../../../core/l10n/l10n.dart';
import '../models/tribe_block_model.dart';
import '../models/tribe_model.dart';
import '../viewmodels/tribe_viewmodel.dart';

/// Câu chữ đa ngôn ngữ cho các giá trị của tính năng Tribe.
extension TribeTextsX on AppLocalizations {
  /// Tên chức vụ: Trưởng nhóm, Phó nhóm, Thành viên.
  String roleLabel(TribeRole role) => switch (role) {
    TribeRole.leader => roleLeader,
    TribeRole.viceLeader => roleVice,
    TribeRole.member => roleMember,
  };

  /// Tên trạng thái trả lời: Tham gia, Không tham gia, Đang chờ.
  String attendanceLabel(AttendanceStatus s) => switch (s) {
    AttendanceStatus.accepted => attendanceAccepted,
    AttendanceStatus.declined => attendanceDeclined,
    AttendanceStatus.pending => attendancePending,
  };

  /// Câu báo kết quả cho từng thao tác trong nhóm.
  String tribeResult(TribeResult r) => switch (r) {
    TribeResult.success => done,
    TribeResult.emptyName => errorTribeNameEmpty,
    TribeResult.nameTooLong => errorTribeNameTooLong(TribeLimits.maxNameLength),
    TribeResult.tribeLimit => errorTribeLimit(TribeLimits.maxTribesPerUser),
    TribeResult.invalidCode => errorCodeEmpty,
    TribeResult.notFound => errorTribeNotFound,
    TribeResult.alreadyMember => infoAlreadyMember,
    TribeResult.tribeFull => errorTribeFull(TribeLimits.maxMembersPerTribe),
    TribeResult.viceLimit => errorViceLimit(TribeLimits.maxViceLeaders),
    TribeResult.needNewLeader => errorNeedNewLeader,
    TribeResult.notAllowed => errorNotAllowed,
    TribeResult.notFoundItem => errorItemGone,
    TribeResult.pastTime => errorSlotInPast,
    TribeResult.blockEnded => errorBlockEnded,
    TribeResult.network => errorNetwork,
    TribeResult.failed => errorServer,
  };
}
