// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get share => 'Share';

  @override
  String get copy => 'Copy';

  @override
  String get create => 'Create';

  @override
  String get add => 'Add';

  @override
  String get done => 'Done';

  @override
  String get hide => 'Hide';

  @override
  String get continueLabel => 'Continue';

  @override
  String get selected => 'Selected';

  @override
  String get clearAll => 'Clear all';

  @override
  String get viewDetails => 'View details';

  @override
  String get menu => 'Menu';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get you => 'You';

  @override
  String get busy => 'Busy';

  @override
  String get free => 'Free';

  @override
  String get linkCopied => 'Link copied!';

  @override
  String get weekdaysShort => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get weekdaysLong =>
      'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';

  @override
  String monthYearFormat(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get monthView => 'Month view';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get settings => 'Settings';

  @override
  String get personalSchedule => 'My schedule';

  @override
  String get tribes => 'Tribes';

  @override
  String get templates => 'Templates';

  @override
  String get workspace => 'Workspace';

  @override
  String get workspaceSubtitle => 'Manage your schedule';

  @override
  String get appTagline => 'Plan your time, together';

  @override
  String get emailOrUsernameHint => 'Email or username';

  @override
  String get passwordHint => 'Password';

  @override
  String get confirmPasswordHint => 'Confirm password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Log in';

  @override
  String get loginWithGoogle => 'Continue with Google';

  @override
  String get noAccountYet => 'Don\'t have an account?';

  @override
  String get register => 'Sign up';

  @override
  String get createAccount => 'Create an account';

  @override
  String get createAccountSubtitle => 'It takes less than a minute';

  @override
  String get displayName => 'Display name';

  @override
  String get email => 'Email';

  @override
  String get registerSuccess => 'Account created! Please log in.';

  @override
  String get errorIdentifierRequired => 'Please enter your email or username';

  @override
  String get errorPasswordRequired => 'Please enter your password';

  @override
  String get errorWrongCredentials => 'Incorrect username or password';

  @override
  String get errorDisplayNameRequired => 'Please enter a name';

  @override
  String get errorEmailRequired => 'Please enter your email';

  @override
  String get errorEmailInvalid => 'This email looks invalid';

  @override
  String get errorCreatePassword => 'Please create a password';

  @override
  String get errorPasswordMismatch => 'Passwords don\'t match';

  @override
  String get personalInfo => 'Personal info';

  @override
  String get regionTimezone => 'Region & time zone';

  @override
  String editField(String field) {
    return 'Edit $field';
  }

  @override
  String get confirmSaveTitle => 'Save changes?';

  @override
  String get confirmSaveMessage => 'Do you want to save this change?';

  @override
  String get confirmSaveTimezone =>
      'Do you want to save this time zone setting?';

  @override
  String followDevice(String tz) {
    return 'Device · $tz';
  }

  @override
  String get autoTimezone => 'Use device time zone';

  @override
  String get country => 'Country';

  @override
  String get chooseCountry => 'Choose a country';

  @override
  String get city => 'City';

  @override
  String get cityHint => '(with time zone)';

  @override
  String get chooseCity => 'Choose a city';

  @override
  String get errorPickCountryCity => 'Please choose a country and a city';

  @override
  String get timezoneExplanation =>
      'Every time in the app (your schedule, tribes, notifications) is shown in this time zone. Friends abroad still see their own local time.';

  @override
  String countryName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'vn': 'Vietnam',
      'ca': 'Canada',
      'jp': 'Japan',
      'kr': 'South Korea',
      'gb': 'United Kingdom',
      'fr': 'France',
      'us': 'United States',
      'au': 'Australia',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get language => 'Language';

  @override
  String get account => 'Account';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirm => 'Do you want to log out?';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountSubtitle =>
      'Permanently delete your account and data';

  @override
  String get deleteAccountWarningTitle => 'This cannot be undone';

  @override
  String get deleteConsequence1 =>
      'All your personal schedules and templates will be deleted.';

  @override
  String get deleteConsequence2 =>
      'You will leave all your tribes. Tribes you lead will be handed to the next person.';

  @override
  String get deleteConsequence3 =>
      'You won\'t be able to log in with this account again.';

  @override
  String get tribesYouLead => 'Tribes you lead';

  @override
  String leadershipGoesTo(String tribe, String name) {
    return '$tribe: $name will become the leader';
  }

  @override
  String tribeWillBeDissolved(String tribe) {
    return '$tribe: you\'re the only member, so it will be dissolved';
  }

  @override
  String get deleteReasonTitle => 'Why are you leaving?';

  @override
  String get reasonNotUsing => 'I don\'t use it anymore';

  @override
  String get reasonOtherApp => 'I found another app';

  @override
  String get reasonPrivacy => 'I\'m worried about privacy';

  @override
  String get reasonOther => 'Other reason';

  @override
  String get reasonOtherHint => 'Tell us a bit more...';

  @override
  String get deleteUnderstand => 'I understand this cannot be undone';

  @override
  String get deleteAccountPermanently => 'Delete my account';

  @override
  String get deleteAccountHint => 'Pick a reason and tick the box to continue.';

  @override
  String get deleteAccountFinalTitle => 'Delete account?';

  @override
  String get deleteAccountFinalMessage =>
      'This is the last step. Your data can\'t be recovered afterwards.';

  @override
  String get accountDeleted => 'Your account has been deleted. Take care!';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get filterAll => 'All';

  @override
  String get filterPersonal => 'Personal';

  @override
  String get filterGroup => 'Tribes';

  @override
  String get last30Days => 'Notifications from the last 30 days';

  @override
  String get noNotifications => 'No notifications';

  @override
  String nTitleNewBlock(String task) {
    return 'New activity: $task';
  }

  @override
  String nTitleBlockUpdated(String task) {
    return 'Updated: $task';
  }

  @override
  String nTitleBlockRescheduled(String task) {
    return 'Rescheduled: $task';
  }

  @override
  String get nTitleBlockCancelled => 'Activity cancelled';

  @override
  String get nTitleResponseAccepted => 'Someone is joining';

  @override
  String get nTitleResponseDeclined => 'Someone can\'t join';

  @override
  String get nTitleMemberJoined => 'New member';

  @override
  String get nTitleMemberLeft => 'A member left';

  @override
  String get nTitleKicked => 'You were removed from a tribe';

  @override
  String get nTitleRenamed => 'Tribe renamed';

  @override
  String get nTitleDissolved => 'Tribe dissolved';

  @override
  String get nTitleRoleChanged => 'Role changed';

  @override
  String get nTitlePersonalAdded => 'New personal activity';

  @override
  String nBodyNewBlock(String actor, String tribe) {
    return '$actor added an activity to $tribe. Are you joining?';
  }

  @override
  String nBodyBlockUpdated(String actor) {
    return '$actor updated the activity details.';
  }

  @override
  String nBodyBlockRescheduled(String actor) {
    return '$actor changed the time — please confirm again.';
  }

  @override
  String nBodyBlockCancelled(String actor, String task, String tribe) {
    return '$actor cancelled \"$task\" in $tribe.';
  }

  @override
  String nBodyResponseAccepted(String actor, String task) {
    return '$actor is joining \"$task\".';
  }

  @override
  String nBodyResponseDeclined(String actor, String task) {
    return '$actor can\'t join \"$task\".';
  }

  @override
  String nBodyMemberJoined(String actor, String tribe) {
    return '$actor joined $tribe.';
  }

  @override
  String nBodyMemberLeft(String actor, String tribe) {
    return '$actor is no longer in $tribe.';
  }

  @override
  String nBodyKicked(String actor, String tribe) {
    return '$actor removed you from $tribe.';
  }

  @override
  String nBodyRenamed(String actor, String oldName, String newName) {
    return '$actor renamed \"$oldName\" to \"$newName\".';
  }

  @override
  String nBodyDissolved(String actor, String tribe) {
    return '$actor dissolved $tribe.';
  }

  @override
  String nBodyRoleVice(String tribe) {
    return 'You\'re now a co-leader of $tribe.';
  }

  @override
  String nBodyRoleViceRemoved(String tribe) {
    return 'You\'re no longer a co-leader of $tribe.';
  }

  @override
  String nBodyRoleLeader(String tribe) {
    return 'You\'re now the leader of $tribe.';
  }

  @override
  String nBodyPersonalAdded(String task, String time) {
    return 'You added \"$task\" at $time.';
  }

  @override
  String itemsTodaySubtitle(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities',
      one: '1 activity',
    );
    return '$_temp0 • Today $date';
  }

  @override
  String get emptyDayHint =>
      'Nothing planned — tap any hour to add an activity';

  @override
  String get noGroupActivitiesDay => 'No tribe activities on this day';

  @override
  String get newActivity => 'New activity';

  @override
  String get editActivity => 'Edit activity';

  @override
  String get activityNameHint => 'Activity name...';

  @override
  String get errorNameRequired => 'Please give the activity a name';

  @override
  String get errorNameTooShort => 'Name needs at least 2 characters';

  @override
  String get date => 'Date';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get color => 'Color';

  @override
  String get colorLongPressHint => '(long-press to change)';

  @override
  String get pickNewColor => 'Pick a new color';

  @override
  String get reminder => 'Reminder';

  @override
  String get remindOnTime => 'At start time';

  @override
  String remindBefore(int minutes) {
    return '$minutes min before';
  }

  @override
  String get note => 'Notes';

  @override
  String get noteHint => 'Add a note...';

  @override
  String get duplicateToOtherDays => 'Copy to other days';

  @override
  String get duplicateNone => 'No days selected';

  @override
  String get duplicateTitle => 'Choose days to copy to';

  @override
  String get duplicateDescription =>
      'Only today onwards. Days that already have something at this time are locked.';

  @override
  String get conflictingDay => 'Time conflict';

  @override
  String selectedDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Select $count days',
      one: 'Select 1 day',
    );
    return '$_temp0';
  }

  @override
  String savedWithCopies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved and copied to $count days',
      one: 'Saved and copied to 1 day',
    );
    return '$_temp0';
  }

  @override
  String get errorEndBeforeStart => 'End time must be after start time';

  @override
  String get errorMinDuration => 'An activity must last at least 5 minutes';

  @override
  String get errorPastDate => 'You can\'t schedule on a past day';

  @override
  String get errorOverlap => 'This time overlaps another activity';

  @override
  String get errorColorDuplicate => 'This color is already in your palette';

  @override
  String get deleteActivityTitle => 'Delete activity?';

  @override
  String deleteActivityMessage(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get activityDeleted => 'Activity deleted';

  @override
  String get yourTemplates => 'Your templates';

  @override
  String get noTemplatesTitle => 'No templates yet';

  @override
  String get noTemplatesMessage =>
      'Create a weekly template to fill your schedule fast, or import one a friend shared.';

  @override
  String get createTemplate => 'Create template';

  @override
  String get createTemplateHint => 'Start from an empty week';

  @override
  String get importTemplate => 'Import from link';

  @override
  String get importTemplateHint => 'Paste a link a friend shared';

  @override
  String get importAction => 'Import';

  @override
  String get templateImported => 'Template added!';

  @override
  String get errorLinkEmpty => 'Please paste a link';

  @override
  String get errorTemplateNotFound => 'No template found for this link';

  @override
  String get errorTemplateDuplicate => 'You already have this template';

  @override
  String errorTemplateLimit(int max) {
    return 'Your library is full (max $max templates)';
  }

  @override
  String get errorTemplateNameEmpty => 'Please name your template';

  @override
  String get templateNameHint => 'Template name...';

  @override
  String activitiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities',
      one: '1 activity',
    );
    return '$_temp0';
  }

  @override
  String get apply => 'Apply';

  @override
  String get applyTemplate => 'Apply template';

  @override
  String get applyTemplateDescription =>
      'Pick the weekdays to copy into your schedule.';

  @override
  String get applyTemplateNote =>
      'Starts from the nearest matching day (today or later).';

  @override
  String get repeatWeeks => 'Weeks';

  @override
  String get applyNow => 'Apply now';

  @override
  String get errorPickAtLeastOneDay => 'Please pick at least one day';

  @override
  String get conflictTitle => 'Schedule conflict';

  @override
  String conflictMessage(int count, String dates) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities overlap',
      one: '1 activity overlaps',
    );
    return '$_temp0 on: $dates.\n\nOverlapping activities will be replaced.';
  }

  @override
  String get replaceAndAdd => 'Replace & add';

  @override
  String templateApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count activities to your schedule!',
      one: 'Added 1 activity to your schedule!',
    );
    return '$_temp0';
  }

  @override
  String templateAppliedReplaced(int added, int replaced) {
    return 'Added $added activities (replaced $replaced)';
  }

  @override
  String get deleteTemplateTitle => 'Delete template?';

  @override
  String deleteTemplateMessage(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get templateDeleted => 'Template deleted';

  @override
  String get shareTemplate => 'Share template';

  @override
  String get shareTemplateDescription =>
      'Anyone with this link can view and copy this template.';

  @override
  String get addActivity => 'Add activity';

  @override
  String get dayOfWeek => 'Day of week';

  @override
  String get yourTribes => 'Your tribes';

  @override
  String get noTribesTitle => 'You\'re not in any tribe yet';

  @override
  String get noTribesMessage =>
      'Create a tribe to find common free time with friends, or join with an invite link.';

  @override
  String get createTribe => 'Create a tribe';

  @override
  String get createTribeHint => 'You\'ll be the leader';

  @override
  String get joinTribe => 'Join a tribe';

  @override
  String get joinTribeHint => 'Use an invite link from a friend';

  @override
  String get joinTribeDescription => 'Paste the invite link you received.';

  @override
  String get join => 'Join';

  @override
  String get openTribe => 'Open tribe';

  @override
  String get tribeNameHint => 'e.g. Project team, Badminton club...';

  @override
  String get tribeCreated =>
      'Tribe created! Invite friends from the members panel.';

  @override
  String joinedTribe(String name) {
    return 'You joined $name!';
  }

  @override
  String get infoAlreadyMember => 'You\'re already in this tribe';

  @override
  String infoAlreadyMemberOf(String name) {
    return 'You\'re already a member of \"$name\" — no need to join again.';
  }

  @override
  String get renameTribe => 'Rename tribe';

  @override
  String get tribeRenamed => 'Tribe renamed';

  @override
  String get tribeColor => 'Tribe color';

  @override
  String get tribeColorUpdated => 'Tribe color updated';

  @override
  String get inviteShareLink => 'Invite / share link';

  @override
  String inviteTo(String name) {
    return 'Invite to $name';
  }

  @override
  String inviteDescription(int max, int current) {
    return 'Anyone with this link can join (max $max members, currently $current).';
  }

  @override
  String get inviteMembers => 'Invite members';

  @override
  String get dissolveTribe => 'Dissolve tribe';

  @override
  String get dissolveTribeTitle => 'Dissolve tribe?';

  @override
  String dissolveTribeMessage(String name) {
    return 'Dissolve $name? All its activities will be deleted and members will be notified.';
  }

  @override
  String get dissolve => 'Dissolve';

  @override
  String tribeDissolved(String name) {
    return '$name was dissolved';
  }

  @override
  String membersCount(int count, int max) {
    return '$count/$max members';
  }

  @override
  String get noUpcomingActivity => 'No upcoming activity';

  @override
  String pendingForYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count activities await your reply',
      one: '1 activity awaits your reply',
    );
    return '$_temp0';
  }

  @override
  String get roleLeader => 'Leader';

  @override
  String get roleVice => 'Co-leader';

  @override
  String get roleMember => 'Member';

  @override
  String get members => 'Members';

  @override
  String tribeSubtitle(int count, String offset) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0 · $offset';
  }

  @override
  String get createGroupActivity => 'Create a tribe activity';

  @override
  String groupActivitiesToday(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tribe activities',
      one: '1 tribe activity',
    );
    return '$_temp0 • Today $date';
  }

  @override
  String get legendFree => 'Free';

  @override
  String get legendHalf => 'Half busy';

  @override
  String get legendBusy => 'Busy';

  @override
  String get commonFreeTime => 'Common free time';

  @override
  String get membersSchedule => 'Members\' time';

  @override
  String get groupActivities => 'Tribe activities';

  @override
  String get noCommonFreeTime =>
      'No common free time on this day. Try a green day!';

  @override
  String busyCount(int busy, int total) {
    return '$busy/$total busy';
  }

  @override
  String get everyoneIsFree => 'Everyone is free';

  @override
  String get freeSlotTapToCreate => 'Everyone free · tap to create';

  @override
  String everyoneFree(int total) {
    return 'All $total members are free 🎉';
  }

  @override
  String someBusy(int busy, int total) {
    return '$busy/$total members are busy. Personal details stay private.';
  }

  @override
  String get theirTime => 'Their time';

  @override
  String get createInThisSlot => 'Create an activity in this slot';

  @override
  String get waitingForYou => 'Reply';

  @override
  String get leaveTribe => 'Leave tribe';

  @override
  String get leaveTribeTitle => 'Leave tribe?';

  @override
  String leaveTribeMessage(String tribe) {
    return 'Leave $tribe? Members will be notified.';
  }

  @override
  String leaveAloneMessage(String tribe) {
    return 'You\'re the only member — leaving will dissolve $tribe.';
  }

  @override
  String leaveAsLeaderMessage(String name, String tribe) {
    return '$name will become the leader. Leave $tribe?';
  }

  @override
  String leftTribe(String tribe) {
    return 'You left $tribe';
  }

  @override
  String get chooseNewLeader => 'Choose a new leader';

  @override
  String get chooseNewLeaderMessage =>
      'A tribe needs a leader — please appoint someone before leaving.';

  @override
  String get appointVice => 'Make co-leader';

  @override
  String get appointLeader => 'Make leader';

  @override
  String get dismissVice => 'Remove co-leader';

  @override
  String get kick => 'Remove from tribe';

  @override
  String get appoint => 'Appoint';

  @override
  String get dismiss => 'Remove';

  @override
  String appointedVice(String name) {
    return '$name is now a co-leader.';
  }

  @override
  String appointedLeader(String name) {
    return '$name is now the leader.';
  }

  @override
  String dismissedVice(String name) {
    return '$name is no longer a co-leader.';
  }

  @override
  String get dismissViceTitle => 'Remove co-leader?';

  @override
  String dismissViceMessage(String name) {
    return '$name will become a regular member.';
  }

  @override
  String get transferLeaderTitle => 'Transfer leadership?';

  @override
  String transferLeaderToVice(String name) {
    return '$name will become the leader. You\'ll become a co-leader.';
  }

  @override
  String transferLeaderToMember(String name) {
    return '$name will become the leader. You\'ll become a member (the tribe already has 3 co-leaders).';
  }

  @override
  String get kickTitle => 'Remove member?';

  @override
  String kickMessage(String name, String tribe) {
    return 'Remove $name from $tribe?';
  }

  @override
  String kicked(String name) {
    return '$name was removed';
  }

  @override
  String get newGroupActivity => 'New tribe activity';

  @override
  String get activityDetails => 'Activity details';

  @override
  String timezoneNote(String offset) {
    return 'Times are in your time zone ($offset). Each member sees their own local time.';
  }

  @override
  String membersFreeCount(int free, int total) {
    return '$free/$total members free';
  }

  @override
  String get areBusy => 'are busy';

  @override
  String get eachMembersTime => 'Each member\'s time';

  @override
  String get oneHourBefore => '1 hour before';

  @override
  String get noteHintGroup => 'Add a note for everyone...';

  @override
  String get noNote => 'No notes';

  @override
  String get areYouJoining => 'Are you joining?';

  @override
  String get attendanceAccepted => 'Going';

  @override
  String get attendanceDeclined => 'Can\'t go';

  @override
  String get attendancePending => 'No reply';

  @override
  String get nobodyYet => 'Nobody yet';

  @override
  String get saveChangesTitle => 'Save changes?';

  @override
  String get createActivityTitle => 'Create activity?';

  @override
  String warnOverlapsWith(String list) {
    return 'Overlaps with: $list.';
  }

  @override
  String warnMembersBusy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members are busy at this time.',
      one: '1 member is busy at this time.',
    );
    return '$_temp0';
  }

  @override
  String get warnReconfirm =>
      'Changing the time asks everyone to confirm again.';

  @override
  String get everyoneWillBeNotified => 'All members will be notified.';

  @override
  String savedAndNotified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved and sent to $count members',
      one: 'Saved and sent to 1 member',
    );
    return '$_temp0';
  }

  @override
  String get errorSlotInPast => 'This time slot has already passed';

  @override
  String get activityCancelled => 'This activity was cancelled.';

  @override
  String get activityEnded => 'This activity has ended.';

  @override
  String get respondedAccepted =>
      'You\'re going! It now shows in your schedule.';

  @override
  String get respondedDeclined => 'Got it. The leaders have been notified.';

  @override
  String get errorTribeNameEmpty => 'Please enter a tribe name';

  @override
  String errorTribeNameTooLong(int max) {
    return 'Name is too long (max $max characters)';
  }

  @override
  String errorTribeLimit(int max) {
    return 'You\'re already in $max tribes. Leave one to create or join another.';
  }

  @override
  String get errorInvalidLink =>
      'This link doesn\'t look right, please check it';

  @override
  String get errorTribeNotFound =>
      'No tribe found for this link. It may have been dissolved or the link is wrong.';

  @override
  String errorTribeFull(int max) {
    return 'This tribe is full ($max members)';
  }

  @override
  String errorTribeFullNamed(String name, int max) {
    return '\"$name\" already has $max members and can\'t take more.';
  }

  @override
  String errorViceLimit(int max) {
    return 'Already $max co-leaders';
  }

  @override
  String get errorNeedNewLeader => 'Please appoint a new leader before leaving';

  @override
  String get errorNotAllowed => 'You don\'t have permission to do this';

  @override
  String get errorItemGone => 'This item no longer exists';
}
