// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get cancel => 'Hủy';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Lưu';

  @override
  String get saved => 'Đã lưu';

  @override
  String get delete => 'Xoá';

  @override
  String get edit => 'Chỉnh sửa';

  @override
  String get share => 'Chia sẻ';

  @override
  String get copy => 'Sao chép';

  @override
  String get create => 'Tạo';

  @override
  String get add => 'Thêm';

  @override
  String get done => 'Xong';

  @override
  String get hide => 'Ẩn';

  @override
  String get continueLabel => 'Tiếp tục';

  @override
  String get selected => 'Đã chọn';

  @override
  String get clearAll => 'Bỏ chọn hết';

  @override
  String get viewDetails => 'Xem chi tiết';

  @override
  String get menu => 'Menu';

  @override
  String get today => 'Hôm nay';

  @override
  String get tomorrow => 'Ngày mai';

  @override
  String get you => 'Bạn';

  @override
  String get busy => 'Bận';

  @override
  String get free => 'Rảnh';

  @override
  String get linkCopied => 'Đã sao chép đường link!';

  @override
  String get weekdaysShort => 'T2,T3,T4,T5,T6,T7,CN';

  @override
  String get weekdaysLong =>
      'Thứ Hai,Thứ Ba,Thứ Tư,Thứ Năm,Thứ Sáu,Thứ Bảy,Chủ Nhật';

  @override
  String monthYearFormat(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMM(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get monthView => 'Xem lịch tháng';

  @override
  String get justNow => 'Vừa xong';

  @override
  String minutesAgo(int n) {
    return '$n phút trước';
  }

  @override
  String hoursAgo(int n) {
    return '$n giờ trước';
  }

  @override
  String daysAgo(int n) {
    return '$n ngày trước';
  }

  @override
  String get home => 'Trang chủ';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get notifications => 'Thông báo';

  @override
  String get settings => 'Cài đặt';

  @override
  String get personalSchedule => 'Lịch cá nhân';

  @override
  String get tribes => 'Lịch nhóm';

  @override
  String get templates => 'Lịch mẫu';

  @override
  String get workspace => 'Không gian';

  @override
  String get workspaceSubtitle => 'Quản lý lịch trình của bạn';

  @override
  String get appTagline => 'Sắp xếp thời gian, kết nối mọi người';

  @override
  String get emailOrUsernameHint => 'Email hoặc tên người dùng';

  @override
  String get passwordHint => 'Mật khẩu';

  @override
  String get confirmPasswordHint => 'Xác nhận mật khẩu';

  @override
  String get rememberMe => 'Ghi nhớ đăng nhập';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get login => 'Đăng nhập';

  @override
  String get loginWithGoogle => 'Đăng nhập với Google';

  @override
  String get noAccountYet => 'Chưa có tài khoản?';

  @override
  String get register => 'Đăng ký';

  @override
  String get createAccount => 'Tạo tài khoản mới';

  @override
  String get createAccountSubtitle => 'Chỉ mất chưa tới một phút thôi';

  @override
  String get displayName => 'Tên hiển thị';

  @override
  String get email => 'Email';

  @override
  String get registerSuccess => 'Đăng ký thành công! Mời bạn đăng nhập.';

  @override
  String get errorIdentifierRequired =>
      'Bạn chưa nhập email hoặc tên người dùng';

  @override
  String get errorPasswordRequired => 'Bạn chưa nhập mật khẩu';

  @override
  String get errorWrongCredentials => 'Tài khoản hoặc mật khẩu chưa đúng';

  @override
  String get errorDisplayNameRequired => 'Bạn chưa nhập tên';

  @override
  String get errorEmailRequired => 'Bạn chưa nhập email';

  @override
  String get errorEmailInvalid => 'Email chưa đúng định dạng';

  @override
  String get errorCreatePassword => 'Bạn hãy tạo một mật khẩu';

  @override
  String get errorPasswordMismatch => 'Mật khẩu xác nhận chưa khớp';

  @override
  String get personalInfo => 'Thông tin cá nhân';

  @override
  String get regionTimezone => 'Khu vực & Múi giờ';

  @override
  String editField(String field) {
    return 'Sửa $field';
  }

  @override
  String get confirmSaveTitle => 'Lưu thay đổi?';

  @override
  String get confirmSaveMessage => 'Bạn có chắc muốn lưu thay đổi này không?';

  @override
  String get confirmSaveTimezone =>
      'Bạn có chắc muốn lưu cấu hình múi giờ này không?';

  @override
  String followDevice(String tz) {
    return 'Theo thiết bị · $tz';
  }

  @override
  String get autoTimezone => 'Tự động theo múi giờ thiết bị';

  @override
  String get country => 'Quốc gia';

  @override
  String get chooseCountry => 'Chọn quốc gia';

  @override
  String get city => 'Thành phố';

  @override
  String get cityHint => '(kèm múi giờ)';

  @override
  String get chooseCity => 'Chọn thành phố';

  @override
  String get errorPickCountryCity => 'Cần chọn quốc gia và thành phố';

  @override
  String get timezoneExplanation =>
      'Mọi giờ giấc trong app (lịch cá nhân, lịch nhóm, thông báo) đều hiển thị theo múi giờ này. Bạn bè ở nước khác vẫn thấy đúng giờ của họ.';

  @override
  String countryName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'vn': 'Việt Nam',
      'ca': 'Canada',
      'jp': 'Nhật Bản',
      'kr': 'Hàn Quốc',
      'gb': 'Anh',
      'fr': 'Pháp',
      'us': 'Mỹ',
      'au': 'Úc',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get appearance => 'Giao diện';

  @override
  String get darkMode => 'Chế độ tối';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get account => 'Tài khoản';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get logoutConfirm => 'Bạn có chắc muốn đăng xuất không?';

  @override
  String get deleteAccount => 'Xoá tài khoản';

  @override
  String get deleteAccountSubtitle => 'Xoá vĩnh viễn tài khoản và dữ liệu';

  @override
  String get deleteAccountWarningTitle => 'Thao tác này không thể hoàn tác';

  @override
  String get deleteConsequence1 =>
      'Toàn bộ lịch cá nhân và lịch mẫu của bạn sẽ bị xoá.';

  @override
  String get deleteConsequence2 =>
      'Bạn sẽ rời khỏi tất cả các nhóm. Nhóm bạn làm trưởng sẽ được chuyển cho người kế tiếp.';

  @override
  String get deleteConsequence3 =>
      'Bạn sẽ không đăng nhập lại được bằng tài khoản này.';

  @override
  String get tribesYouLead => 'Nhóm bạn đang làm trưởng';

  @override
  String leadershipGoesTo(String tribe, String name) {
    return '$tribe: $name sẽ trở thành trưởng nhóm';
  }

  @override
  String tribeWillBeDissolved(String tribe) {
    return '$tribe: chỉ có mình bạn nên nhóm sẽ bị giải tán';
  }

  @override
  String get deleteReasonTitle => 'Vì sao bạn muốn rời đi?';

  @override
  String get reasonNotUsing => 'Mình không còn dùng nữa';

  @override
  String get reasonOtherApp => 'Mình tìm được ứng dụng khác';

  @override
  String get reasonPrivacy => 'Mình lo ngại về quyền riêng tư';

  @override
  String get reasonOther => 'Lý do khác';

  @override
  String get reasonOtherHint => 'Chia sẻ thêm với tụi mình nhé...';

  @override
  String get deleteUnderstand => 'Mình hiểu là thao tác này không thể hoàn tác';

  @override
  String get deleteAccountPermanently => 'Xoá tài khoản vĩnh viễn';

  @override
  String get deleteAccountHint =>
      'Chọn lý do và tích vào ô xác nhận để tiếp tục.';

  @override
  String get deleteAccountFinalTitle => 'Xoá tài khoản?';

  @override
  String get deleteAccountFinalMessage =>
      'Đây là bước cuối cùng. Sau khi xoá, dữ liệu của bạn sẽ không khôi phục được.';

  @override
  String get accountDeleted => 'Tài khoản của bạn đã được xoá. Hẹn gặp lại!';

  @override
  String get markAllRead => 'Đánh dấu đã đọc tất cả';

  @override
  String get filterAll => 'Tất cả';

  @override
  String get filterPersonal => 'Cá nhân';

  @override
  String get filterGroup => 'Nhóm';

  @override
  String get last30Days => 'Thông báo trong 30 ngày gần nhất';

  @override
  String get noNotifications => 'Không có thông báo nào';

  @override
  String nTitleNewBlock(String task) {
    return 'Hoạt động mới: $task';
  }

  @override
  String nTitleBlockUpdated(String task) {
    return 'Đã cập nhật: $task';
  }

  @override
  String nTitleBlockRescheduled(String task) {
    return 'Đổi giờ: $task';
  }

  @override
  String get nTitleBlockCancelled => 'Hoạt động đã bị huỷ';

  @override
  String get nTitleResponseAccepted => 'Có người tham gia';

  @override
  String get nTitleResponseDeclined => 'Có người không tham gia';

  @override
  String get nTitleMemberJoined => 'Thành viên mới';

  @override
  String get nTitleMemberLeft => 'Thành viên rời nhóm';

  @override
  String get nTitleKicked => 'Bạn đã được mời rời nhóm';

  @override
  String get nTitleRenamed => 'Nhóm đã đổi tên';

  @override
  String get nTitleDissolved => 'Nhóm đã giải tán';

  @override
  String get nTitleRoleChanged => 'Thay đổi chức vụ';

  @override
  String get nTitlePersonalAdded => 'Lịch cá nhân mới';

  @override
  String nBodyNewBlock(String actor, String tribe) {
    return '$actor vừa thêm hoạt động vào $tribe. Bạn có tham gia không?';
  }

  @override
  String nBodyBlockUpdated(String actor) {
    return '$actor đã cập nhật thông tin hoạt động.';
  }

  @override
  String nBodyBlockRescheduled(String actor) {
    return '$actor đã đổi giờ, cần xác nhận lại.';
  }

  @override
  String nBodyBlockCancelled(String actor, String task, String tribe) {
    return '$actor đã huỷ \"$task\" của nhóm $tribe.';
  }

  @override
  String nBodyResponseAccepted(String actor, String task) {
    return '$actor sẽ tham gia \"$task\".';
  }

  @override
  String nBodyResponseDeclined(String actor, String task) {
    return '$actor không tham gia \"$task\".';
  }

  @override
  String nBodyMemberJoined(String actor, String tribe) {
    return '$actor vừa tham gia $tribe.';
  }

  @override
  String nBodyMemberLeft(String actor, String tribe) {
    return '$actor không còn ở trong $tribe.';
  }

  @override
  String nBodyKicked(String actor, String tribe) {
    return '$actor đã mời bạn rời nhóm $tribe.';
  }

  @override
  String nBodyRenamed(String actor, String oldName, String newName) {
    return '$actor đã đổi tên nhóm \"$oldName\" thành \"$newName\".';
  }

  @override
  String nBodyDissolved(String actor, String tribe) {
    return '$actor đã giải tán nhóm $tribe.';
  }

  @override
  String nBodyRoleVice(String tribe) {
    return 'Bạn đã được bổ nhiệm làm phó nhóm $tribe.';
  }

  @override
  String nBodyRoleViceRemoved(String tribe) {
    return 'Bạn không còn là phó nhóm $tribe.';
  }

  @override
  String nBodyRoleLeader(String tribe) {
    return 'Bạn đã được bổ nhiệm làm trưởng nhóm $tribe.';
  }

  @override
  String nBodyPersonalAdded(String task, String time) {
    return 'Bạn đã thêm \"$task\" lúc $time.';
  }

  @override
  String itemsTodaySubtitle(int count, String date) {
    return '$count hoạt động • Hôm nay $date';
  }

  @override
  String get emptyDayHint =>
      'Ngày trống — chạm vào giờ bất kỳ để thêm hoạt động';

  @override
  String get noGroupActivitiesDay =>
      'Không có hoạt động nhóm nào trong ngày này';

  @override
  String get newActivity => 'Hoạt động mới';

  @override
  String get editActivity => 'Sửa hoạt động';

  @override
  String get activityNameHint => 'Tên hoạt động...';

  @override
  String get errorNameRequired => 'Bạn chưa đặt tên cho hoạt động';

  @override
  String get errorNameTooShort => 'Tên cần ít nhất 2 ký tự';

  @override
  String get date => 'Ngày';

  @override
  String get start => 'Bắt đầu';

  @override
  String get end => 'Kết thúc';

  @override
  String get color => 'Màu sắc';

  @override
  String get colorLongPressHint => '(nhấn giữ để đổi màu)';

  @override
  String get pickNewColor => 'Chọn màu mới';

  @override
  String get reminder => 'Nhắc nhở';

  @override
  String get remindOnTime => 'Đúng giờ';

  @override
  String remindBefore(int minutes) {
    return 'Trước $minutes phút';
  }

  @override
  String get note => 'Ghi chú';

  @override
  String get noteHint => 'Thêm ghi chú...';

  @override
  String get duplicateToOtherDays => 'Nhân bản sang ngày khác';

  @override
  String get duplicateNone => 'Chưa chọn ngày nào';

  @override
  String get duplicateTitle => 'Chọn ngày để nhân bản';

  @override
  String get duplicateDescription =>
      'Chỉ chọn được từ hôm nay trở đi. Ngày đã có lịch trùng khung giờ này sẽ bị khoá.';

  @override
  String get conflictingDay => 'Trùng giờ';

  @override
  String selectedDays(int count) {
    return 'Chọn $count ngày';
  }

  @override
  String savedWithCopies(int count) {
    return 'Đã lưu và nhân bản sang $count ngày';
  }

  @override
  String get errorEndBeforeStart => 'Giờ kết thúc phải sau giờ bắt đầu';

  @override
  String get errorMinDuration => 'Hoạt động cần dài ít nhất 5 phút';

  @override
  String get errorPastDate => 'Không thể tạo lịch cho ngày đã qua';

  @override
  String get errorOverlap => 'Khung giờ này bị trùng với một hoạt động khác';

  @override
  String get errorColorDuplicate => 'Màu này đã có trong bảng màu của bạn';

  @override
  String get deleteActivityTitle => 'Xoá hoạt động?';

  @override
  String deleteActivityMessage(String name) {
    return 'Bạn có chắc muốn xoá \"$name\"?';
  }

  @override
  String get activityDeleted => 'Đã xoá hoạt động';

  @override
  String get yourTemplates => 'Mẫu của bạn';

  @override
  String get noTemplatesTitle => 'Chưa có lịch mẫu nào';

  @override
  String get noTemplatesMessage =>
      'Tạo một tuần mẫu để áp dụng nhanh vào lịch, hoặc nhập mẫu bạn bè chia sẻ.';

  @override
  String get createTemplate => 'Tạo lịch mẫu';

  @override
  String get createTemplateHint => 'Bắt đầu từ một tuần trống';

  @override
  String get importTemplate => 'Nhập bằng liên kết';

  @override
  String get importTemplateHint => 'Dán link chia sẻ từ bạn bè';

  @override
  String get importAction => 'Nhập';

  @override
  String get templateImported => 'Đã thêm lịch mẫu!';

  @override
  String get errorLinkEmpty => 'Bạn chưa dán link vào';

  @override
  String get errorTemplateNotFound =>
      'Không tìm thấy lịch mẫu nào với link này';

  @override
  String get errorTemplateDuplicate => 'Lịch mẫu này đã có trong kho rồi';

  @override
  String errorTemplateLimit(int max) {
    return 'Kho đã đầy (tối đa $max mẫu)';
  }

  @override
  String get errorTemplateNameEmpty => 'Bạn chưa đặt tên cho lịch mẫu';

  @override
  String get templateNameHint => 'Tên lịch mẫu...';

  @override
  String activitiesCount(int count) {
    return '$count hoạt động';
  }

  @override
  String get apply => 'Áp dụng';

  @override
  String get applyTemplate => 'Áp dụng lịch mẫu';

  @override
  String get applyTemplateDescription =>
      'Chọn các thứ trong mẫu để chép vào lịch cá nhân.';

  @override
  String get applyTemplateNote =>
      'Bắt đầu từ ngày gần nhất (hôm nay hoặc sau đó) ứng với mỗi thứ.';

  @override
  String get repeatWeeks => 'Số tuần';

  @override
  String get applyNow => 'Áp dụng ngay';

  @override
  String get errorPickAtLeastOneDay => 'Cần chọn ít nhất 1 ngày';

  @override
  String get conflictTitle => 'Phát hiện trùng lịch';

  @override
  String conflictMessage(int count, String dates) {
    return 'Có $count hoạt động bị trùng giờ vào các ngày: $dates.\n\nHoạt động cũ bị trùng sẽ bị thay thế.';
  }

  @override
  String get replaceAndAdd => 'Thay thế & thêm';

  @override
  String templateApplied(int count) {
    return 'Đã chép $count hoạt động vào lịch!';
  }

  @override
  String templateAppliedReplaced(int added, int replaced) {
    return 'Đã chép $added hoạt động (thay thế $replaced hoạt động cũ)';
  }

  @override
  String get deleteTemplateTitle => 'Xoá lịch mẫu?';

  @override
  String deleteTemplateMessage(String name) {
    return 'Bạn có chắc muốn xoá \"$name\"?';
  }

  @override
  String get templateDeleted => 'Đã xoá lịch mẫu';

  @override
  String get shareTemplate => 'Chia sẻ lịch mẫu';

  @override
  String get shareTemplateDescription =>
      'Ai có link này đều có thể xem và chép lịch mẫu này về tài khoản của họ.';

  @override
  String get addActivity => 'Thêm hoạt động';

  @override
  String get dayOfWeek => 'Thứ trong tuần';

  @override
  String get yourTribes => 'Nhóm của bạn';

  @override
  String get noTribesTitle => 'Bạn chưa ở trong nhóm nào';

  @override
  String get noTribesMessage =>
      'Tạo nhóm để cùng bạn bè tìm giờ rảnh chung, hoặc tham gia bằng link được mời.';

  @override
  String get createTribe => 'Tạo Tribe mới';

  @override
  String get createTribeHint => 'Bạn sẽ là trưởng nhóm';

  @override
  String get joinTribe => 'Tham gia Tribe';

  @override
  String get joinTribeHint => 'Dùng link mời từ bạn bè';

  @override
  String get joinTribeDescription => 'Dán đường link mời mà bạn nhận được.';

  @override
  String get join => 'Vào nhóm';

  @override
  String get openTribe => 'Mở nhóm';

  @override
  String get tribeNameHint => 'VD: Nhóm đồ án, CLB cầu lông...';

  @override
  String get tribeCreated =>
      'Đã tạo nhóm! Mời bạn bè vào bằng link trong mục thành viên.';

  @override
  String joinedTribe(String name) {
    return 'Đã tham gia $name!';
  }

  @override
  String get infoAlreadyMember => 'Bạn đã ở trong nhóm này rồi';

  @override
  String infoAlreadyMemberOf(String name) {
    return 'Bạn đã là thành viên của \"$name\" rồi, không cần tham gia lại.';
  }

  @override
  String get renameTribe => 'Đổi tên nhóm';

  @override
  String get tribeRenamed => 'Đã đổi tên nhóm';

  @override
  String get tribeColor => 'Đổi màu nhóm';

  @override
  String get tribeColorUpdated => 'Đã cập nhật màu nhóm';

  @override
  String get inviteShareLink => 'Mời / chia sẻ link';

  @override
  String inviteTo(String name) {
    return 'Mời vào $name';
  }

  @override
  String inviteDescription(int max, int current) {
    return 'Ai có link này đều có thể vào nhóm (tối đa $max thành viên, hiện có $current).';
  }

  @override
  String get inviteMembers => 'Mời thành viên';

  @override
  String get dissolveTribe => 'Giải tán nhóm';

  @override
  String get dissolveTribeTitle => 'Giải tán nhóm?';

  @override
  String dissolveTribeMessage(String name) {
    return 'Bạn chắc chắn muốn giải tán $name? Mọi hoạt động của nhóm sẽ bị xoá và các thành viên sẽ nhận được thông báo.';
  }

  @override
  String get dissolve => 'Giải tán';

  @override
  String tribeDissolved(String name) {
    return 'Đã giải tán $name';
  }

  @override
  String membersCount(int count, int max) {
    return '$count/$max thành viên';
  }

  @override
  String get noUpcomingActivity => 'Chưa có hoạt động sắp tới';

  @override
  String pendingForYou(int count) {
    return '$count hoạt động chờ bạn xác nhận';
  }

  @override
  String get roleLeader => 'Trưởng nhóm';

  @override
  String get roleVice => 'Phó nhóm';

  @override
  String get roleMember => 'Thành viên';

  @override
  String get members => 'Thành viên';

  @override
  String tribeSubtitle(int count, String offset) {
    return '$count thành viên · Giờ $offset';
  }

  @override
  String get createGroupActivity => 'Tạo hoạt động cho nhóm';

  @override
  String groupActivitiesToday(int count, String date) {
    return '$count hoạt động nhóm • Hôm nay $date';
  }

  @override
  String get legendFree => 'Rảnh';

  @override
  String get legendHalf => 'Nửa bận';

  @override
  String get legendBusy => 'Bận';

  @override
  String get commonFreeTime => 'Giờ rảnh chung';

  @override
  String get membersSchedule => 'Lịch thành viên';

  @override
  String get groupActivities => 'Hoạt động nhóm';

  @override
  String get noCommonFreeTime =>
      'Ngày này không có khung giờ nào mọi người cùng rảnh. Hãy thử ngày có màu xanh!';

  @override
  String busyCount(int busy, int total) {
    return '$busy/$total bận';
  }

  @override
  String get everyoneIsFree => 'Mọi người đều rảnh';

  @override
  String get freeSlotTapToCreate => 'Mọi người rảnh · chạm để tạo';

  @override
  String everyoneFree(int total) {
    return 'Tất cả $total thành viên đều rảnh 🎉';
  }

  @override
  String someBusy(int busy, int total) {
    return '$busy/$total thành viên bận. Nội dung lịch riêng được ẩn để bảo vệ quyền riêng tư.';
  }

  @override
  String get theirTime => 'Giờ của họ';

  @override
  String get createInThisSlot => 'Tạo hoạt động trong khung này';

  @override
  String get waitingForYou => 'Chờ bạn';

  @override
  String get leaveTribe => 'Rời nhóm';

  @override
  String get leaveTribeTitle => 'Rời nhóm?';

  @override
  String leaveTribeMessage(String tribe) {
    return 'Bạn chắc chắn muốn rời $tribe? Các thành viên sẽ nhận được thông báo.';
  }

  @override
  String leaveAloneMessage(String tribe) {
    return 'Nhóm chỉ còn mình bạn, rời nhóm đồng nghĩa với giải tán $tribe.';
  }

  @override
  String leaveAsLeaderMessage(String name, String tribe) {
    return '$name sẽ trở thành trưởng nhóm. Bạn chắc chắn muốn rời $tribe?';
  }

  @override
  String leftTribe(String tribe) {
    return 'Bạn đã rời $tribe';
  }

  @override
  String get chooseNewLeader => 'Chọn trưởng nhóm mới';

  @override
  String get chooseNewLeaderMessage =>
      'Nhóm cần có trưởng nhóm, hãy bổ nhiệm một người trước khi rời nhóm.';

  @override
  String get appointVice => 'Bổ nhiệm phó nhóm';

  @override
  String get appointLeader => 'Bổ nhiệm trưởng nhóm';

  @override
  String get dismissVice => 'Bãi nhiệm phó nhóm';

  @override
  String get kick => 'Mời rời nhóm';

  @override
  String get appoint => 'Bổ nhiệm';

  @override
  String get dismiss => 'Bãi nhiệm';

  @override
  String appointedVice(String name) {
    return 'Đã bổ nhiệm $name làm phó nhóm.';
  }

  @override
  String appointedLeader(String name) {
    return 'Đã bổ nhiệm $name làm trưởng nhóm.';
  }

  @override
  String dismissedVice(String name) {
    return 'Đã bãi nhiệm $name.';
  }

  @override
  String get dismissViceTitle => 'Bãi nhiệm phó nhóm?';

  @override
  String dismissViceMessage(String name) {
    return '$name sẽ trở lại làm thành viên.';
  }

  @override
  String get transferLeaderTitle => 'Chuyển quyền trưởng nhóm?';

  @override
  String transferLeaderToVice(String name) {
    return '$name sẽ trở thành trưởng nhóm. Bạn sẽ trở thành phó nhóm.';
  }

  @override
  String transferLeaderToMember(String name) {
    return '$name sẽ trở thành trưởng nhóm. Bạn sẽ trở thành thành viên (nhóm đã đủ 3 phó).';
  }

  @override
  String get kickTitle => 'Mời rời nhóm?';

  @override
  String kickMessage(String name, String tribe) {
    return 'Bạn chắc chắn muốn mời $name rời $tribe?';
  }

  @override
  String kicked(String name) {
    return 'Đã mời $name rời nhóm';
  }

  @override
  String get newGroupActivity => 'Hoạt động nhóm mới';

  @override
  String get activityDetails => 'Chi tiết hoạt động';

  @override
  String timezoneNote(String offset) {
    return 'Giờ theo múi giờ của bạn ($offset). Mỗi thành viên sẽ thấy đúng giờ địa phương của họ.';
  }

  @override
  String membersFreeCount(int free, int total) {
    return '$free/$total thành viên rảnh';
  }

  @override
  String get areBusy => 'đang bận';

  @override
  String get eachMembersTime => 'Giờ từng người';

  @override
  String get oneHourBefore => 'Trước 1 tiếng';

  @override
  String get noteHintGroup => 'Thêm ghi chú cho mọi người...';

  @override
  String get noNote => 'Không có ghi chú';

  @override
  String get areYouJoining => 'Bạn có tham gia không?';

  @override
  String get attendanceAccepted => 'Tham gia';

  @override
  String get attendanceDeclined => 'Không tham gia';

  @override
  String get attendancePending => 'Chưa phản hồi';

  @override
  String get nobodyYet => 'Chưa có ai';

  @override
  String get saveChangesTitle => 'Lưu thay đổi?';

  @override
  String get createActivityTitle => 'Tạo hoạt động?';

  @override
  String warnOverlapsWith(String list) {
    return 'Trùng giờ với: $list.';
  }

  @override
  String warnMembersBusy(int count) {
    return '$count thành viên đang bận trong khung giờ này.';
  }

  @override
  String get warnReconfirm => 'Đổi giờ sẽ yêu cầu mọi người xác nhận lại.';

  @override
  String get everyoneWillBeNotified =>
      'Tất cả thành viên sẽ nhận được thông báo.';

  @override
  String savedAndNotified(int count) {
    return 'Đã lưu và gửi thông báo cho $count thành viên';
  }

  @override
  String get errorSlotInPast => 'Khung giờ này đã qua rồi';

  @override
  String get activityCancelled => 'Hoạt động này đã bị huỷ.';

  @override
  String get activityEnded => 'Hoạt động đã kết thúc.';

  @override
  String get respondedAccepted =>
      'Đã xác nhận tham gia. Hoạt động sẽ hiện trong lịch cá nhân của bạn.';

  @override
  String get respondedDeclined =>
      'Đã báo không tham gia. Trưởng/phó nhóm sẽ nhận được thông báo.';

  @override
  String get errorTribeNameEmpty => 'Bạn chưa nhập tên nhóm';

  @override
  String errorTribeNameTooLong(int max) {
    return 'Tên nhóm dài quá rồi (tối đa $max ký tự)';
  }

  @override
  String errorTribeLimit(int max) {
    return 'Bạn đã ở trong $max nhóm. Rời bớt một nhóm để tạo hoặc tham gia thêm nhé.';
  }

  @override
  String get errorInvalidLink =>
      'Link không hợp lệ, hãy kiểm tra lại đường link';

  @override
  String get errorTribeNotFound =>
      'Không tìm thấy nhóm nào với link này. Có thể nhóm đã bị giải tán hoặc link bị sai.';

  @override
  String errorTribeFull(int max) {
    return 'Nhóm đã đủ $max thành viên';
  }

  @override
  String errorTribeFullNamed(String name, int max) {
    return '\"$name\" đã đủ $max thành viên nên không vào thêm được.';
  }

  @override
  String errorViceLimit(int max) {
    return 'Đã đủ $max phó nhóm';
  }

  @override
  String get errorNeedNewLeader =>
      'Bạn cần bổ nhiệm trưởng nhóm mới trước khi rời';

  @override
  String get errorNotAllowed => 'Bạn không có quyền thực hiện thao tác này';

  @override
  String get errorItemGone => 'Dữ liệu này không còn tồn tại';
}
