import '../../../core/l10n/l10n.dart';
import '../models/app_notification.dart';

/// Dựng tiêu đề & nội dung thông báo theo ngôn ngữ đang chọn.
extension NotificationTextX on AppLocalizations {
  String notificationTitle(AppNotification n) {
    final a = n.args;
    return switch (n.kind) {
      NotificationKind.tribeNewBlock => nTitleNewBlock(a['task'] ?? ''),
      NotificationKind.tribeBlockUpdated => nTitleBlockUpdated(a['task'] ?? ''),
      NotificationKind.tribeBlockRescheduled => nTitleBlockRescheduled(
        a['task'] ?? '',
      ),
      NotificationKind.tribeBlockCancelled => nTitleBlockCancelled,
      NotificationKind.tribeResponseAccepted => nTitleResponseAccepted,
      NotificationKind.tribeResponseDeclined => nTitleResponseDeclined,
      NotificationKind.tribeMemberJoined => nTitleMemberJoined,
      NotificationKind.tribeMemberLeft => nTitleMemberLeft,
      NotificationKind.tribeKickedYou => nTitleKicked,
      NotificationKind.tribeRenamed => nTitleRenamed,
      NotificationKind.tribeDissolved => nTitleDissolved,
      NotificationKind.tribeRoleVice ||
      NotificationKind.tribeRoleViceRemoved ||
      NotificationKind.tribeRoleLeader => nTitleRoleChanged,
      NotificationKind.personalBlockAdded => nTitlePersonalAdded,
    };
  }

  String notificationBody(AppNotification n) {
    final a = n.args;
    final actor = a['actor'] ?? '';
    final tribe = a['tribe'] ?? '';
    final task = a['task'] ?? '';
    return switch (n.kind) {
      NotificationKind.tribeNewBlock => nBodyNewBlock(actor, tribe),
      NotificationKind.tribeBlockUpdated => nBodyBlockUpdated(actor),
      NotificationKind.tribeBlockRescheduled => nBodyBlockRescheduled(actor),
      NotificationKind.tribeBlockCancelled => nBodyBlockCancelled(
        actor,
        task,
        tribe,
      ),
      NotificationKind.tribeResponseAccepted => nBodyResponseAccepted(
        actor,
        task,
      ),
      NotificationKind.tribeResponseDeclined => nBodyResponseDeclined(
        actor,
        task,
      ),
      NotificationKind.tribeMemberJoined => nBodyMemberJoined(actor, tribe),
      NotificationKind.tribeMemberLeft => nBodyMemberLeft(actor, tribe),
      NotificationKind.tribeKickedYou => nBodyKicked(actor, tribe),
      NotificationKind.tribeRenamed => nBodyRenamed(
        actor,
        a['old'] ?? '',
        a['new'] ?? '',
      ),
      NotificationKind.tribeDissolved => nBodyDissolved(actor, tribe),
      NotificationKind.tribeRoleVice => nBodyRoleVice(tribe),
      NotificationKind.tribeRoleViceRemoved => nBodyRoleViceRemoved(tribe),
      NotificationKind.tribeRoleLeader => nBodyRoleLeader(tribe),
      NotificationKind.personalBlockAdded => nBodyPersonalAdded(
        task,
        a['time'] ?? '',
      ),
    };
  }
}
