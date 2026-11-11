import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('vi'),
  ];

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In vi, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get saved;

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa'**
  String get edit;

  /// No description provided for @share.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get copy;

  /// No description provided for @create.
  ///
  /// In vi, this message translates to:
  /// **'Tạo'**
  String get create;

  /// No description provided for @add.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get add;

  /// No description provided for @done.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get done;

  /// No description provided for @hide.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn'**
  String get hide;

  /// No description provided for @continueLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get continueLabel;

  /// No description provided for @selected.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn'**
  String get selected;

  /// No description provided for @clearAll.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ chọn hết'**
  String get clearAll;

  /// No description provided for @viewDetails.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết'**
  String get viewDetails;

  /// No description provided for @menu.
  ///
  /// In vi, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @today.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mai'**
  String get tomorrow;

  /// No description provided for @you.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get you;

  /// No description provided for @busy.
  ///
  /// In vi, this message translates to:
  /// **'Bận'**
  String get busy;

  /// No description provided for @free.
  ///
  /// In vi, this message translates to:
  /// **'Rảnh'**
  String get free;

  /// No description provided for @linkCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép đường link!'**
  String get linkCopied;

  /// No description provided for @weekdaysShort.
  ///
  /// In vi, this message translates to:
  /// **'T2,T3,T4,T5,T6,T7,CN'**
  String get weekdaysShort;

  /// No description provided for @weekdaysLong.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Hai,Thứ Ba,Thứ Tư,Thứ Năm,Thứ Sáu,Thứ Bảy,Chủ Nhật'**
  String get weekdaysLong;

  /// No description provided for @monthYearFormat.
  ///
  /// In vi, this message translates to:
  /// **'{date}'**
  String monthYearFormat(DateTime date);

  /// No description provided for @monthView.
  ///
  /// In vi, this message translates to:
  /// **'Xem lịch tháng'**
  String get monthView;

  /// No description provided for @justNow.
  ///
  /// In vi, this message translates to:
  /// **'Vừa xong'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In vi, this message translates to:
  /// **'{n} phút trước'**
  String minutesAgo(int n);

  /// No description provided for @hoursAgo.
  ///
  /// In vi, this message translates to:
  /// **'{n} giờ trước'**
  String hoursAgo(int n);

  /// No description provided for @daysAgo.
  ///
  /// In vi, this message translates to:
  /// **'{n} ngày trước'**
  String daysAgo(int n);

  /// No description provided for @home.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get profile;

  /// No description provided for @notifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get notifications;

  /// No description provided for @settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// No description provided for @personalSchedule.
  ///
  /// In vi, this message translates to:
  /// **'Lịch cá nhân'**
  String get personalSchedule;

  /// No description provided for @tribes.
  ///
  /// In vi, this message translates to:
  /// **'Lịch nhóm'**
  String get tribes;

  /// No description provided for @templates.
  ///
  /// In vi, this message translates to:
  /// **'Lịch mẫu'**
  String get templates;

  /// No description provided for @workspace.
  ///
  /// In vi, this message translates to:
  /// **'Không gian'**
  String get workspace;

  /// No description provided for @workspaceSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý lịch trình của bạn'**
  String get workspaceSubtitle;

  /// No description provided for @appTagline.
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp thời gian, kết nối mọi người'**
  String get appTagline;

  /// No description provided for @emailOrUsernameHint.
  ///
  /// In vi, this message translates to:
  /// **'Email hoặc tên người dùng'**
  String get emailOrUsernameHint;

  /// No description provided for @passwordHint.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get passwordHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu'**
  String get confirmPasswordHint;

  /// No description provided for @rememberMe.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhớ đăng nhập'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get login;

  /// No description provided for @loginWithGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập với Google'**
  String get loginWithGoogle;

  /// No description provided for @noAccountYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản?'**
  String get noAccountYet;

  /// No description provided for @register.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get register;

  /// No description provided for @createAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản mới'**
  String get createAccount;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ mất chưa tới một phút thôi'**
  String get createAccountSubtitle;

  /// No description provided for @displayName.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị'**
  String get displayName;

  /// No description provided for @email.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @registerSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký thành công! Mời bạn đăng nhập.'**
  String get registerSuccess;

  /// No description provided for @errorIdentifierRequired.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa nhập email hoặc tên người dùng'**
  String get errorIdentifierRequired;

  /// No description provided for @errorPasswordRequired.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa nhập mật khẩu'**
  String get errorPasswordRequired;

  /// No description provided for @errorWrongCredentials.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản hoặc mật khẩu chưa đúng'**
  String get errorWrongCredentials;

  /// No description provided for @errorDisplayNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa nhập tên'**
  String get errorDisplayNameRequired;

  /// No description provided for @errorEmailRequired.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa nhập email'**
  String get errorEmailRequired;

  /// No description provided for @errorEmailInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Email chưa đúng định dạng'**
  String get errorEmailInvalid;

  /// No description provided for @errorCreatePassword.
  ///
  /// In vi, this message translates to:
  /// **'Bạn hãy tạo một mật khẩu'**
  String get errorCreatePassword;

  /// No description provided for @errorPasswordMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu xác nhận chưa khớp'**
  String get errorPasswordMismatch;

  /// No description provided for @personalInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cá nhân'**
  String get personalInfo;

  /// No description provided for @regionTimezone.
  ///
  /// In vi, this message translates to:
  /// **'Khu vực & Múi giờ'**
  String get regionTimezone;

  /// No description provided for @editField.
  ///
  /// In vi, this message translates to:
  /// **'Sửa {field}'**
  String editField(String field);

  /// No description provided for @confirmSaveTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi?'**
  String get confirmSaveTitle;

  /// No description provided for @confirmSaveMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn lưu thay đổi này không?'**
  String get confirmSaveMessage;

  /// No description provided for @confirmSaveTimezone.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn lưu cấu hình múi giờ này không?'**
  String get confirmSaveTimezone;

  /// No description provided for @followDevice.
  ///
  /// In vi, this message translates to:
  /// **'Theo thiết bị · {tz}'**
  String followDevice(String tz);

  /// No description provided for @autoTimezone.
  ///
  /// In vi, this message translates to:
  /// **'Tự động theo múi giờ thiết bị'**
  String get autoTimezone;

  /// No description provided for @country.
  ///
  /// In vi, this message translates to:
  /// **'Quốc gia'**
  String get country;

  /// No description provided for @chooseCountry.
  ///
  /// In vi, this message translates to:
  /// **'Chọn quốc gia'**
  String get chooseCountry;

  /// No description provided for @city.
  ///
  /// In vi, this message translates to:
  /// **'Thành phố'**
  String get city;

  /// No description provided for @cityHint.
  ///
  /// In vi, this message translates to:
  /// **'(kèm múi giờ)'**
  String get cityHint;

  /// No description provided for @chooseCity.
  ///
  /// In vi, this message translates to:
  /// **'Chọn thành phố'**
  String get chooseCity;

  /// No description provided for @errorPickCountryCity.
  ///
  /// In vi, this message translates to:
  /// **'Cần chọn quốc gia và thành phố'**
  String get errorPickCountryCity;

  /// No description provided for @timezoneExplanation.
  ///
  /// In vi, this message translates to:
  /// **'Mọi giờ giấc trong app (lịch cá nhân, lịch nhóm, thông báo) đều hiển thị theo múi giờ này. Bạn bè ở nước khác vẫn thấy đúng giờ của họ.'**
  String get timezoneExplanation;

  /// No description provided for @countryName.
  ///
  /// In vi, this message translates to:
  /// **'{code, select, vn{Việt Nam} ca{Canada} jp{Nhật Bản} kr{Hàn Quốc} gb{Anh} fr{Pháp} us{Mỹ} au{Úc} other{{code}}}'**
  String countryName(String code);

  /// No description provided for @appearance.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ tối'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get language;

  /// No description provided for @account.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get account;

  /// No description provided for @logout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn đăng xuất không?'**
  String get logoutConfirm;

  /// No description provided for @deleteAccount.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá vĩnh viễn tài khoản và dữ liệu'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountWarningTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thao tác này không thể hoàn tác'**
  String get deleteAccountWarningTitle;

  /// No description provided for @deleteConsequence1.
  ///
  /// In vi, this message translates to:
  /// **'Toàn bộ lịch cá nhân và lịch mẫu của bạn sẽ bị xoá.'**
  String get deleteConsequence1;

  /// No description provided for @deleteConsequence2.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ rời khỏi tất cả các nhóm. Nhóm bạn làm trưởng sẽ được chuyển cho người kế tiếp.'**
  String get deleteConsequence2;

  /// No description provided for @deleteConsequence3.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ không đăng nhập lại được bằng tài khoản này.'**
  String get deleteConsequence3;

  /// No description provided for @tribesYouLead.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm bạn đang làm trưởng'**
  String get tribesYouLead;

  /// No description provided for @leadershipGoesTo.
  ///
  /// In vi, this message translates to:
  /// **'{tribe}: {name} sẽ trở thành trưởng nhóm'**
  String leadershipGoesTo(String tribe, String name);

  /// No description provided for @tribeWillBeDissolved.
  ///
  /// In vi, this message translates to:
  /// **'{tribe}: chỉ có mình bạn nên nhóm sẽ bị giải tán'**
  String tribeWillBeDissolved(String tribe);

  /// No description provided for @deleteReasonTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao bạn muốn rời đi?'**
  String get deleteReasonTitle;

  /// No description provided for @reasonNotUsing.
  ///
  /// In vi, this message translates to:
  /// **'Mình không còn dùng nữa'**
  String get reasonNotUsing;

  /// No description provided for @reasonOtherApp.
  ///
  /// In vi, this message translates to:
  /// **'Mình tìm được ứng dụng khác'**
  String get reasonOtherApp;

  /// No description provided for @reasonPrivacy.
  ///
  /// In vi, this message translates to:
  /// **'Mình lo ngại về quyền riêng tư'**
  String get reasonPrivacy;

  /// No description provided for @reasonOther.
  ///
  /// In vi, this message translates to:
  /// **'Lý do khác'**
  String get reasonOther;

  /// No description provided for @reasonOtherHint.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ thêm với tụi mình nhé...'**
  String get reasonOtherHint;

  /// No description provided for @deleteUnderstand.
  ///
  /// In vi, this message translates to:
  /// **'Mình hiểu là thao tác này không thể hoàn tác'**
  String get deleteUnderstand;

  /// No description provided for @deleteAccountPermanently.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản vĩnh viễn'**
  String get deleteAccountPermanently;

  /// No description provided for @deleteAccountHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn lý do và tích vào ô xác nhận để tiếp tục.'**
  String get deleteAccountHint;

  /// No description provided for @deleteAccountFinalTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tài khoản?'**
  String get deleteAccountFinalTitle;

  /// No description provided for @deleteAccountFinalMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đây là bước cuối cùng. Sau khi xoá, dữ liệu của bạn sẽ không khôi phục được.'**
  String get deleteAccountFinalMessage;

  /// No description provided for @accountDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản của bạn đã được xoá. Hẹn gặp lại!'**
  String get accountDeleted;

  /// No description provided for @markAllRead.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu đã đọc tất cả'**
  String get markAllRead;

  /// No description provided for @filterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get filterAll;

  /// No description provided for @filterPersonal.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get filterPersonal;

  /// No description provided for @filterGroup.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm'**
  String get filterGroup;

  /// No description provided for @last30Days.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo trong 30 ngày gần nhất'**
  String get last30Days;

  /// No description provided for @noNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Không có thông báo nào'**
  String get noNotifications;

  /// No description provided for @nTitleNewBlock.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động mới: {task}'**
  String nTitleNewBlock(String task);

  /// No description provided for @nTitleBlockUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật: {task}'**
  String nTitleBlockUpdated(String task);

  /// No description provided for @nTitleBlockRescheduled.
  ///
  /// In vi, this message translates to:
  /// **'Đổi giờ: {task}'**
  String nTitleBlockRescheduled(String task);

  /// No description provided for @nTitleBlockCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động đã bị huỷ'**
  String get nTitleBlockCancelled;

  /// No description provided for @nTitleResponseAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Có người tham gia'**
  String get nTitleResponseAccepted;

  /// No description provided for @nTitleResponseDeclined.
  ///
  /// In vi, this message translates to:
  /// **'Có người không tham gia'**
  String get nTitleResponseDeclined;

  /// No description provided for @nTitleMemberJoined.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên mới'**
  String get nTitleMemberJoined;

  /// No description provided for @nTitleMemberLeft.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên rời nhóm'**
  String get nTitleMemberLeft;

  /// No description provided for @nTitleKicked.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã được mời rời nhóm'**
  String get nTitleKicked;

  /// No description provided for @nTitleRenamed.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm đã đổi tên'**
  String get nTitleRenamed;

  /// No description provided for @nTitleDissolved.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm đã giải tán'**
  String get nTitleDissolved;

  /// No description provided for @nTitleRoleChanged.
  ///
  /// In vi, this message translates to:
  /// **'Thay đổi chức vụ'**
  String get nTitleRoleChanged;

  /// No description provided for @nTitlePersonalAdded.
  ///
  /// In vi, this message translates to:
  /// **'Lịch cá nhân mới'**
  String get nTitlePersonalAdded;

  /// No description provided for @nBodyNewBlock.
  ///
  /// In vi, this message translates to:
  /// **'{actor} vừa thêm hoạt động vào {tribe}. Bạn có tham gia không?'**
  String nBodyNewBlock(String actor, String tribe);

  /// No description provided for @nBodyBlockUpdated.
  ///
  /// In vi, this message translates to:
  /// **'{actor} đã cập nhật thông tin hoạt động.'**
  String nBodyBlockUpdated(String actor);

  /// No description provided for @nBodyBlockRescheduled.
  ///
  /// In vi, this message translates to:
  /// **'{actor} đã đổi giờ, cần xác nhận lại.'**
  String nBodyBlockRescheduled(String actor);

  /// No description provided for @nBodyBlockCancelled.
  ///
  /// In vi, this message translates to:
  /// **'{actor} đã huỷ \"{task}\" của nhóm {tribe}.'**
  String nBodyBlockCancelled(String actor, String task, String tribe);

  /// No description provided for @nBodyResponseAccepted.
  ///
  /// In vi, this message translates to:
  /// **'{actor} sẽ tham gia \"{task}\".'**
  String nBodyResponseAccepted(String actor, String task);

  /// No description provided for @nBodyResponseDeclined.
  ///
  /// In vi, this message translates to:
  /// **'{actor} không tham gia \"{task}\".'**
  String nBodyResponseDeclined(String actor, String task);

  /// No description provided for @nBodyMemberJoined.
  ///
  /// In vi, this message translates to:
  /// **'{actor} vừa tham gia {tribe}.'**
  String nBodyMemberJoined(String actor, String tribe);

  /// No description provided for @nBodyMemberLeft.
  ///
  /// In vi, this message translates to:
  /// **'{actor} không còn ở trong {tribe}.'**
  String nBodyMemberLeft(String actor, String tribe);

  /// No description provided for @nBodyKicked.
  ///
  /// In vi, this message translates to:
  /// **'{actor} đã mời bạn rời nhóm {tribe}.'**
  String nBodyKicked(String actor, String tribe);

  /// No description provided for @nBodyRenamed.
  ///
  /// In vi, this message translates to:
  /// **'{actor} đã đổi tên nhóm \"{oldName}\" thành \"{newName}\".'**
  String nBodyRenamed(String actor, String oldName, String newName);

  /// No description provided for @nBodyDissolved.
  ///
  /// In vi, this message translates to:
  /// **'{actor} đã giải tán nhóm {tribe}.'**
  String nBodyDissolved(String actor, String tribe);

  /// No description provided for @nBodyRoleVice.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã được bổ nhiệm làm phó nhóm {tribe}.'**
  String nBodyRoleVice(String tribe);

  /// No description provided for @nBodyRoleViceRemoved.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không còn là phó nhóm {tribe}.'**
  String nBodyRoleViceRemoved(String tribe);

  /// No description provided for @nBodyRoleLeader.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã được bổ nhiệm làm trưởng nhóm {tribe}.'**
  String nBodyRoleLeader(String tribe);

  /// No description provided for @nBodyPersonalAdded.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã thêm \"{task}\" lúc {time}.'**
  String nBodyPersonalAdded(String task, String time);

  /// No description provided for @itemsTodaySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'{count} hoạt động • Hôm nay {date}'**
  String itemsTodaySubtitle(int count, String date);

  /// No description provided for @emptyDayHint.
  ///
  /// In vi, this message translates to:
  /// **'Ngày trống — chạm vào giờ bất kỳ để thêm hoạt động'**
  String get emptyDayHint;

  /// No description provided for @noGroupActivitiesDay.
  ///
  /// In vi, this message translates to:
  /// **'Không có hoạt động nhóm nào trong ngày này'**
  String get noGroupActivitiesDay;

  /// No description provided for @newActivity.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động mới'**
  String get newActivity;

  /// No description provided for @editActivity.
  ///
  /// In vi, this message translates to:
  /// **'Sửa hoạt động'**
  String get editActivity;

  /// No description provided for @activityNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Tên hoạt động...'**
  String get activityNameHint;

  /// No description provided for @errorNameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa đặt tên cho hoạt động'**
  String get errorNameRequired;

  /// No description provided for @errorNameTooShort.
  ///
  /// In vi, this message translates to:
  /// **'Tên cần ít nhất 2 ký tự'**
  String get errorNameTooShort;

  /// No description provided for @date.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get date;

  /// No description provided for @start.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get start;

  /// No description provided for @end.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc'**
  String get end;

  /// No description provided for @color.
  ///
  /// In vi, this message translates to:
  /// **'Màu sắc'**
  String get color;

  /// No description provided for @colorLongPressHint.
  ///
  /// In vi, this message translates to:
  /// **'(nhấn giữ để đổi màu)'**
  String get colorLongPressHint;

  /// No description provided for @pickNewColor.
  ///
  /// In vi, this message translates to:
  /// **'Chọn màu mới'**
  String get pickNewColor;

  /// No description provided for @reminder.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc nhở'**
  String get reminder;

  /// No description provided for @remindOnTime.
  ///
  /// In vi, this message translates to:
  /// **'Đúng giờ'**
  String get remindOnTime;

  /// No description provided for @remindBefore.
  ///
  /// In vi, this message translates to:
  /// **'Trước {minutes} phút'**
  String remindBefore(int minutes);

  /// No description provided for @note.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get note;

  /// No description provided for @noteHint.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ghi chú...'**
  String get noteHint;

  /// No description provided for @duplicateToOtherDays.
  ///
  /// In vi, this message translates to:
  /// **'Nhân bản sang ngày khác'**
  String get duplicateToOtherDays;

  /// No description provided for @duplicateNone.
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn ngày nào'**
  String get duplicateNone;

  /// No description provided for @duplicateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngày để nhân bản'**
  String get duplicateTitle;

  /// No description provided for @duplicateDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chọn được từ hôm nay trở đi. Ngày đã có lịch trùng khung giờ này sẽ bị khoá.'**
  String get duplicateDescription;

  /// No description provided for @conflictingDay.
  ///
  /// In vi, this message translates to:
  /// **'Trùng giờ'**
  String get conflictingDay;

  /// No description provided for @selectedDays.
  ///
  /// In vi, this message translates to:
  /// **'Chọn {count} ngày'**
  String selectedDays(int count);

  /// No description provided for @savedWithCopies.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu và nhân bản sang {count} ngày'**
  String savedWithCopies(int count);

  /// No description provided for @errorEndBeforeStart.
  ///
  /// In vi, this message translates to:
  /// **'Giờ kết thúc phải sau giờ bắt đầu'**
  String get errorEndBeforeStart;

  /// No description provided for @errorMinDuration.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động cần dài ít nhất 5 phút'**
  String get errorMinDuration;

  /// No description provided for @errorPastDate.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tạo lịch cho ngày đã qua'**
  String get errorPastDate;

  /// No description provided for @errorOverlap.
  ///
  /// In vi, this message translates to:
  /// **'Khung giờ này bị trùng với một hoạt động khác'**
  String get errorOverlap;

  /// No description provided for @errorColorDuplicate.
  ///
  /// In vi, this message translates to:
  /// **'Màu này đã có trong bảng màu của bạn'**
  String get errorColorDuplicate;

  /// No description provided for @deleteActivityTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá hoạt động?'**
  String get deleteActivityTitle;

  /// No description provided for @deleteActivityMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xoá \"{name}\"?'**
  String deleteActivityMessage(String name);

  /// No description provided for @activityDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá hoạt động'**
  String get activityDeleted;

  /// No description provided for @yourTemplates.
  ///
  /// In vi, this message translates to:
  /// **'Mẫu của bạn'**
  String get yourTemplates;

  /// No description provided for @noTemplatesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch mẫu nào'**
  String get noTemplatesTitle;

  /// No description provided for @noTemplatesMessage.
  ///
  /// In vi, this message translates to:
  /// **'Tạo một tuần mẫu để áp dụng nhanh vào lịch, hoặc nhập mẫu bạn bè chia sẻ.'**
  String get noTemplatesMessage;

  /// No description provided for @createTemplate.
  ///
  /// In vi, this message translates to:
  /// **'Tạo lịch mẫu'**
  String get createTemplate;

  /// No description provided for @createTemplateHint.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu từ một tuần trống'**
  String get createTemplateHint;

  /// No description provided for @importTemplate.
  ///
  /// In vi, this message translates to:
  /// **'Nhập bằng liên kết'**
  String get importTemplate;

  /// No description provided for @importTemplateHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã chia sẻ từ bạn bè'**
  String get importTemplateHint;

  /// No description provided for @importAction.
  ///
  /// In vi, this message translates to:
  /// **'Nhập'**
  String get importAction;

  /// No description provided for @templateImported.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm lịch mẫu!'**
  String get templateImported;

  /// No description provided for @errorLinkEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa dán link vào'**
  String get errorLinkEmpty;

  /// No description provided for @errorTemplateNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy lịch mẫu nào với mã này'**
  String get errorTemplateNotFound;

  /// No description provided for @errorTemplateDuplicate.
  ///
  /// In vi, this message translates to:
  /// **'Lịch mẫu này đã có trong kho rồi'**
  String get errorTemplateDuplicate;

  /// No description provided for @errorTemplateLimit.
  ///
  /// In vi, this message translates to:
  /// **'Kho đã đầy (tối đa {max} mẫu)'**
  String errorTemplateLimit(int max);

  /// No description provided for @errorTemplateNameEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa đặt tên cho lịch mẫu'**
  String get errorTemplateNameEmpty;

  /// No description provided for @templateNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Tên lịch mẫu...'**
  String get templateNameHint;

  /// No description provided for @activitiesCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} hoạt động'**
  String activitiesCount(int count);

  /// No description provided for @apply.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng'**
  String get apply;

  /// No description provided for @applyTemplate.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng lịch mẫu'**
  String get applyTemplate;

  /// No description provided for @applyTemplateDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chọn các thứ trong mẫu để chép vào lịch cá nhân.'**
  String get applyTemplateDescription;

  /// No description provided for @applyTemplateNote.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu từ ngày gần nhất (hôm nay hoặc sau đó) ứng với mỗi thứ.'**
  String get applyTemplateNote;

  /// No description provided for @repeatWeeks.
  ///
  /// In vi, this message translates to:
  /// **'Số tuần'**
  String get repeatWeeks;

  /// No description provided for @applyNow.
  ///
  /// In vi, this message translates to:
  /// **'Áp dụng ngay'**
  String get applyNow;

  /// No description provided for @errorPickAtLeastOneDay.
  ///
  /// In vi, this message translates to:
  /// **'Cần chọn ít nhất 1 ngày'**
  String get errorPickAtLeastOneDay;

  /// No description provided for @conflictTitle.
  ///
  /// In vi, this message translates to:
  /// **'Phát hiện trùng lịch'**
  String get conflictTitle;

  /// No description provided for @conflictMessage.
  ///
  /// In vi, this message translates to:
  /// **'Có {count} hoạt động bị trùng giờ vào các ngày: {dates}.\n\nHoạt động cũ bị trùng sẽ bị thay thế.'**
  String conflictMessage(int count, String dates);

  /// No description provided for @replaceAndAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thay thế & thêm'**
  String get replaceAndAdd;

  /// No description provided for @templateApplied.
  ///
  /// In vi, this message translates to:
  /// **'Đã chép {count} hoạt động vào lịch!'**
  String templateApplied(int count);

  /// No description provided for @templateAppliedReplaced.
  ///
  /// In vi, this message translates to:
  /// **'Đã chép {added} hoạt động (thay thế {replaced} hoạt động cũ)'**
  String templateAppliedReplaced(int added, int replaced);

  /// No description provided for @deleteTemplateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá lịch mẫu?'**
  String get deleteTemplateTitle;

  /// No description provided for @deleteTemplateMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xoá \"{name}\"?'**
  String deleteTemplateMessage(String name);

  /// No description provided for @templateDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá lịch mẫu'**
  String get templateDeleted;

  /// No description provided for @shareTemplate.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ lịch mẫu'**
  String get shareTemplate;

  /// No description provided for @shareTemplateDescription.
  ///
  /// In vi, this message translates to:
  /// **'Gửi mã này cho bạn bè, họ nhập mã ở mục Nhập lịch mẫu để chép về tài khoản của họ.'**
  String get shareTemplateDescription;

  /// No description provided for @addActivity.
  ///
  /// In vi, this message translates to:
  /// **'Thêm hoạt động'**
  String get addActivity;

  /// No description provided for @dayOfWeek.
  ///
  /// In vi, this message translates to:
  /// **'Thứ trong tuần'**
  String get dayOfWeek;

  /// No description provided for @yourTribes.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm của bạn'**
  String get yourTribes;

  /// No description provided for @noTribesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa ở trong nhóm nào'**
  String get noTribesTitle;

  /// No description provided for @noTribesMessage.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhóm để cùng bạn bè tìm giờ rảnh chung, hoặc tham gia bằng link được mời.'**
  String get noTribesMessage;

  /// No description provided for @createTribe.
  ///
  /// In vi, this message translates to:
  /// **'Tạo Tribe mới'**
  String get createTribe;

  /// No description provided for @createTribeHint.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ là trưởng nhóm'**
  String get createTribeHint;

  /// No description provided for @joinTribe.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia Tribe'**
  String get joinTribe;

  /// No description provided for @joinTribeHint.
  ///
  /// In vi, this message translates to:
  /// **'Dùng link mời từ bạn bè'**
  String get joinTribeHint;

  /// No description provided for @joinTribeDescription.
  ///
  /// In vi, this message translates to:
  /// **'Dán đường link mời mà bạn nhận được.'**
  String get joinTribeDescription;

  /// No description provided for @join.
  ///
  /// In vi, this message translates to:
  /// **'Vào nhóm'**
  String get join;

  /// No description provided for @openTribe.
  ///
  /// In vi, this message translates to:
  /// **'Mở nhóm'**
  String get openTribe;

  /// No description provided for @tribeNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Nhóm đồ án, CLB cầu lông...'**
  String get tribeNameHint;

  /// No description provided for @tribeCreated.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo nhóm! Mời bạn bè vào bằng link trong mục thành viên.'**
  String get tribeCreated;

  /// No description provided for @joinedTribe.
  ///
  /// In vi, this message translates to:
  /// **'Đã tham gia {name}!'**
  String joinedTribe(String name);

  /// No description provided for @infoAlreadyMember.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã ở trong nhóm này rồi'**
  String get infoAlreadyMember;

  /// No description provided for @infoAlreadyMemberOf.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã là thành viên của \"{name}\" rồi, không cần tham gia lại.'**
  String infoAlreadyMemberOf(String name);

  /// No description provided for @renameTribe.
  ///
  /// In vi, this message translates to:
  /// **'Đổi tên nhóm'**
  String get renameTribe;

  /// No description provided for @tribeRenamed.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi tên nhóm'**
  String get tribeRenamed;

  /// No description provided for @tribeColor.
  ///
  /// In vi, this message translates to:
  /// **'Đổi màu nhóm'**
  String get tribeColor;

  /// No description provided for @tribeColorUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật màu nhóm'**
  String get tribeColorUpdated;

  /// No description provided for @inviteShareLink.
  ///
  /// In vi, this message translates to:
  /// **'Mời / chia sẻ link'**
  String get inviteShareLink;

  /// No description provided for @inviteTo.
  ///
  /// In vi, this message translates to:
  /// **'Mời vào {name}'**
  String inviteTo(String name);

  /// No description provided for @inviteDescription.
  ///
  /// In vi, this message translates to:
  /// **'Ai có link này đều có thể vào nhóm (tối đa {max} thành viên, hiện có {current}).'**
  String inviteDescription(int max, int current);

  /// No description provided for @inviteMembers.
  ///
  /// In vi, this message translates to:
  /// **'Mời thành viên'**
  String get inviteMembers;

  /// No description provided for @dissolveTribe.
  ///
  /// In vi, this message translates to:
  /// **'Giải tán nhóm'**
  String get dissolveTribe;

  /// No description provided for @dissolveTribeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giải tán nhóm?'**
  String get dissolveTribeTitle;

  /// No description provided for @dissolveTribeMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chắc chắn muốn giải tán {name}? Mọi hoạt động của nhóm sẽ bị xoá và các thành viên sẽ nhận được thông báo.'**
  String dissolveTribeMessage(String name);

  /// No description provided for @dissolve.
  ///
  /// In vi, this message translates to:
  /// **'Giải tán'**
  String get dissolve;

  /// No description provided for @tribeDissolved.
  ///
  /// In vi, this message translates to:
  /// **'Đã giải tán {name}'**
  String tribeDissolved(String name);

  /// No description provided for @membersCount.
  ///
  /// In vi, this message translates to:
  /// **'{count}/{max} thành viên'**
  String membersCount(int count, int max);

  /// No description provided for @noUpcomingActivity.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hoạt động sắp tới'**
  String get noUpcomingActivity;

  /// No description provided for @pendingForYou.
  ///
  /// In vi, this message translates to:
  /// **'{count} hoạt động chờ bạn xác nhận'**
  String pendingForYou(int count);

  /// No description provided for @roleLeader.
  ///
  /// In vi, this message translates to:
  /// **'Trưởng nhóm'**
  String get roleLeader;

  /// No description provided for @roleVice.
  ///
  /// In vi, this message translates to:
  /// **'Phó nhóm'**
  String get roleVice;

  /// No description provided for @roleMember.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get roleMember;

  /// No description provided for @members.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên'**
  String get members;

  /// No description provided for @tribeSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'{count} thành viên · Giờ {offset}'**
  String tribeSubtitle(int count, String offset);

  /// No description provided for @createGroupActivity.
  ///
  /// In vi, this message translates to:
  /// **'Tạo hoạt động cho nhóm'**
  String get createGroupActivity;

  /// No description provided for @groupActivitiesToday.
  ///
  /// In vi, this message translates to:
  /// **'{count} hoạt động nhóm • Hôm nay {date}'**
  String groupActivitiesToday(int count, String date);

  /// No description provided for @legendFree.
  ///
  /// In vi, this message translates to:
  /// **'Rảnh'**
  String get legendFree;

  /// No description provided for @legendHalf.
  ///
  /// In vi, this message translates to:
  /// **'Nửa bận'**
  String get legendHalf;

  /// No description provided for @legendBusy.
  ///
  /// In vi, this message translates to:
  /// **'Bận'**
  String get legendBusy;

  /// No description provided for @commonFreeTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ rảnh chung'**
  String get commonFreeTime;

  /// No description provided for @membersSchedule.
  ///
  /// In vi, this message translates to:
  /// **'Lịch thành viên'**
  String get membersSchedule;

  /// No description provided for @groupActivities.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động nhóm'**
  String get groupActivities;

  /// No description provided for @noCommonFreeTime.
  ///
  /// In vi, this message translates to:
  /// **'Ngày này không có khung giờ nào mọi người cùng rảnh. Hãy thử ngày có màu xanh!'**
  String get noCommonFreeTime;

  /// No description provided for @busyCount.
  ///
  /// In vi, this message translates to:
  /// **'{busy}/{total} bận'**
  String busyCount(int busy, int total);

  /// No description provided for @everyoneIsFree.
  ///
  /// In vi, this message translates to:
  /// **'Mọi người đều rảnh'**
  String get everyoneIsFree;

  /// No description provided for @freeSlotTapToCreate.
  ///
  /// In vi, this message translates to:
  /// **'Mọi người rảnh · chạm để tạo'**
  String get freeSlotTapToCreate;

  /// No description provided for @everyoneFree.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả {total} thành viên đều rảnh 🎉'**
  String everyoneFree(int total);

  /// No description provided for @someBusy.
  ///
  /// In vi, this message translates to:
  /// **'{busy}/{total} thành viên bận. Nội dung lịch riêng được ẩn để bảo vệ quyền riêng tư.'**
  String someBusy(int busy, int total);

  /// No description provided for @theirTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ của họ'**
  String get theirTime;

  /// No description provided for @createInThisSlot.
  ///
  /// In vi, this message translates to:
  /// **'Tạo hoạt động trong khung này'**
  String get createInThisSlot;

  /// No description provided for @waitingForYou.
  ///
  /// In vi, this message translates to:
  /// **'Chờ bạn'**
  String get waitingForYou;

  /// No description provided for @leaveTribe.
  ///
  /// In vi, this message translates to:
  /// **'Rời nhóm'**
  String get leaveTribe;

  /// No description provided for @leaveTribeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Rời nhóm?'**
  String get leaveTribeTitle;

  /// No description provided for @leaveTribeMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chắc chắn muốn rời {tribe}? Các thành viên sẽ nhận được thông báo.'**
  String leaveTribeMessage(String tribe);

  /// No description provided for @leaveAloneMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm chỉ còn mình bạn, rời nhóm đồng nghĩa với giải tán {tribe}.'**
  String leaveAloneMessage(String tribe);

  /// No description provided for @leaveAsLeaderMessage.
  ///
  /// In vi, this message translates to:
  /// **'{name} sẽ trở thành trưởng nhóm. Bạn chắc chắn muốn rời {tribe}?'**
  String leaveAsLeaderMessage(String name, String tribe);

  /// No description provided for @leftTribe.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã rời {tribe}'**
  String leftTribe(String tribe);

  /// No description provided for @chooseNewLeader.
  ///
  /// In vi, this message translates to:
  /// **'Chọn trưởng nhóm mới'**
  String get chooseNewLeader;

  /// No description provided for @chooseNewLeaderMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm cần có trưởng nhóm, hãy bổ nhiệm một người trước khi rời nhóm.'**
  String get chooseNewLeaderMessage;

  /// No description provided for @appointVice.
  ///
  /// In vi, this message translates to:
  /// **'Bổ nhiệm phó nhóm'**
  String get appointVice;

  /// No description provided for @appointLeader.
  ///
  /// In vi, this message translates to:
  /// **'Bổ nhiệm trưởng nhóm'**
  String get appointLeader;

  /// No description provided for @dismissVice.
  ///
  /// In vi, this message translates to:
  /// **'Bãi nhiệm phó nhóm'**
  String get dismissVice;

  /// No description provided for @kick.
  ///
  /// In vi, this message translates to:
  /// **'Mời rời nhóm'**
  String get kick;

  /// No description provided for @appoint.
  ///
  /// In vi, this message translates to:
  /// **'Bổ nhiệm'**
  String get appoint;

  /// No description provided for @dismiss.
  ///
  /// In vi, this message translates to:
  /// **'Bãi nhiệm'**
  String get dismiss;

  /// No description provided for @appointedVice.
  ///
  /// In vi, this message translates to:
  /// **'Đã bổ nhiệm {name} làm phó nhóm.'**
  String appointedVice(String name);

  /// No description provided for @appointedLeader.
  ///
  /// In vi, this message translates to:
  /// **'Đã bổ nhiệm {name} làm trưởng nhóm.'**
  String appointedLeader(String name);

  /// No description provided for @dismissedVice.
  ///
  /// In vi, this message translates to:
  /// **'Đã bãi nhiệm {name}.'**
  String dismissedVice(String name);

  /// No description provided for @dismissViceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bãi nhiệm phó nhóm?'**
  String get dismissViceTitle;

  /// No description provided for @dismissViceMessage.
  ///
  /// In vi, this message translates to:
  /// **'{name} sẽ trở lại làm thành viên.'**
  String dismissViceMessage(String name);

  /// No description provided for @transferLeaderTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển quyền trưởng nhóm?'**
  String get transferLeaderTitle;

  /// No description provided for @transferLeaderToVice.
  ///
  /// In vi, this message translates to:
  /// **'{name} sẽ trở thành trưởng nhóm. Bạn sẽ trở thành phó nhóm.'**
  String transferLeaderToVice(String name);

  /// No description provided for @transferLeaderToMember.
  ///
  /// In vi, this message translates to:
  /// **'{name} sẽ trở thành trưởng nhóm. Bạn sẽ trở thành thành viên (nhóm đã đủ 3 phó).'**
  String transferLeaderToMember(String name);

  /// No description provided for @kickTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mời rời nhóm?'**
  String get kickTitle;

  /// No description provided for @kickMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chắc chắn muốn mời {name} rời {tribe}?'**
  String kickMessage(String name, String tribe);

  /// No description provided for @kicked.
  ///
  /// In vi, this message translates to:
  /// **'Đã mời {name} rời nhóm'**
  String kicked(String name);

  /// No description provided for @newGroupActivity.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động nhóm mới'**
  String get newGroupActivity;

  /// No description provided for @activityDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết hoạt động'**
  String get activityDetails;

  /// No description provided for @timezoneNote.
  ///
  /// In vi, this message translates to:
  /// **'Giờ theo múi giờ của bạn ({offset}). Mỗi thành viên sẽ thấy đúng giờ địa phương của họ.'**
  String timezoneNote(String offset);

  /// No description provided for @membersFreeCount.
  ///
  /// In vi, this message translates to:
  /// **'{free}/{total} thành viên rảnh'**
  String membersFreeCount(int free, int total);

  /// No description provided for @areBusy.
  ///
  /// In vi, this message translates to:
  /// **'đang bận'**
  String get areBusy;

  /// No description provided for @eachMembersTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ từng người'**
  String get eachMembersTime;

  /// No description provided for @oneHourBefore.
  ///
  /// In vi, this message translates to:
  /// **'Trước 1 tiếng'**
  String get oneHourBefore;

  /// No description provided for @noteHintGroup.
  ///
  /// In vi, this message translates to:
  /// **'Thêm ghi chú cho mọi người...'**
  String get noteHintGroup;

  /// No description provided for @noNote.
  ///
  /// In vi, this message translates to:
  /// **'Không có ghi chú'**
  String get noNote;

  /// No description provided for @areYouJoining.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có tham gia không?'**
  String get areYouJoining;

  /// No description provided for @attendanceAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia'**
  String get attendanceAccepted;

  /// No description provided for @attendanceDeclined.
  ///
  /// In vi, this message translates to:
  /// **'Không tham gia'**
  String get attendanceDeclined;

  /// No description provided for @attendancePending.
  ///
  /// In vi, this message translates to:
  /// **'Chưa phản hồi'**
  String get attendancePending;

  /// No description provided for @nobodyYet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ai'**
  String get nobodyYet;

  /// No description provided for @saveChangesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi?'**
  String get saveChangesTitle;

  /// No description provided for @createActivityTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo hoạt động?'**
  String get createActivityTitle;

  /// No description provided for @warnOverlapsWith.
  ///
  /// In vi, this message translates to:
  /// **'Trùng giờ với: {list}.'**
  String warnOverlapsWith(String list);

  /// No description provided for @warnMembersBusy.
  ///
  /// In vi, this message translates to:
  /// **'{count} thành viên đang bận trong khung giờ này.'**
  String warnMembersBusy(int count);

  /// No description provided for @warnReconfirm.
  ///
  /// In vi, this message translates to:
  /// **'Đổi giờ sẽ yêu cầu mọi người xác nhận lại.'**
  String get warnReconfirm;

  /// No description provided for @everyoneWillBeNotified.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả thành viên sẽ nhận được thông báo.'**
  String get everyoneWillBeNotified;

  /// No description provided for @savedAndNotified.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu và gửi thông báo cho {count} thành viên'**
  String savedAndNotified(int count);

  /// No description provided for @errorSlotInPast.
  ///
  /// In vi, this message translates to:
  /// **'Khung giờ này đã qua rồi'**
  String get errorSlotInPast;

  /// No description provided for @activityCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động này đã bị huỷ.'**
  String get activityCancelled;

  /// No description provided for @activityEnded.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động đã kết thúc.'**
  String get activityEnded;

  /// No description provided for @respondedAccepted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác nhận tham gia. Hoạt động sẽ hiện trong lịch cá nhân của bạn.'**
  String get respondedAccepted;

  /// No description provided for @respondedDeclined.
  ///
  /// In vi, this message translates to:
  /// **'Đã báo không tham gia. Trưởng/phó nhóm sẽ nhận được thông báo.'**
  String get respondedDeclined;

  /// No description provided for @errorTribeNameEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa nhập tên nhóm'**
  String get errorTribeNameEmpty;

  /// No description provided for @errorTribeNameTooLong.
  ///
  /// In vi, this message translates to:
  /// **'Tên nhóm dài quá rồi (tối đa {max} ký tự)'**
  String errorTribeNameTooLong(int max);

  /// No description provided for @errorTribeLimit.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã ở trong {max} nhóm. Rời bớt một nhóm để tạo hoặc tham gia thêm nhé.'**
  String errorTribeLimit(int max);

  /// No description provided for @errorInvalidLink.
  ///
  /// In vi, this message translates to:
  /// **'Link không hợp lệ, hãy kiểm tra lại đường link'**
  String get errorInvalidLink;

  /// No description provided for @errorTribeNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy nhóm nào với link này. Có thể nhóm đã bị giải tán hoặc link bị sai.'**
  String get errorTribeNotFound;

  /// No description provided for @errorTribeFull.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm đã đủ {max} thành viên'**
  String errorTribeFull(int max);

  /// No description provided for @errorTribeFullNamed.
  ///
  /// In vi, this message translates to:
  /// **'\"{name}\" đã đủ {max} thành viên nên không vào thêm được.'**
  String errorTribeFullNamed(String name, int max);

  /// No description provided for @errorViceLimit.
  ///
  /// In vi, this message translates to:
  /// **'Đã đủ {max} phó nhóm'**
  String errorViceLimit(int max);

  /// No description provided for @errorNeedNewLeader.
  ///
  /// In vi, this message translates to:
  /// **'Bạn cần bổ nhiệm trưởng nhóm mới trước khi rời'**
  String get errorNeedNewLeader;

  /// No description provided for @errorNotAllowed.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền thực hiện thao tác này'**
  String get errorNotAllowed;

  /// No description provided for @errorItemGone.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu này không còn tồn tại'**
  String get errorItemGone;

  /// No description provided for @errorNameLength.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị phải từ 2 đến 100 ký tự'**
  String get errorNameLength;

  /// No description provided for @errorPasswordTooShort.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu tối thiểu 6 ký tự'**
  String get errorPasswordTooShort;

  /// No description provided for @errorEmailTaken.
  ///
  /// In vi, this message translates to:
  /// **'Email này đã được sử dụng'**
  String get errorEmailTaken;

  /// No description provided for @errorNameTaken.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị này đã có người dùng'**
  String get errorNameTaken;

  /// No description provided for @errorAccountBanned.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản của bạn đang bị khoá'**
  String get errorAccountBanned;

  /// No description provided for @errorAccountDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản này đã bị xoá'**
  String get errorAccountDeleted;

  /// No description provided for @errorGoogleAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản này đăng nhập bằng Google, hãy chọn Đăng nhập với Google'**
  String get errorGoogleAccount;

  /// No description provided for @errorGoogleFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập Google không thành công, vui lòng thử lại'**
  String get errorGoogleFailed;

  /// No description provided for @errorGoogleUnsupported.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị này chưa hỗ trợ đăng nhập Google'**
  String get errorGoogleUnsupported;

  /// No description provided for @errorNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được máy chủ, vui lòng kiểm tra mạng'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In vi, this message translates to:
  /// **'Có lỗi xảy ra, vui lòng thử lại'**
  String get errorServer;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nhập email đã đăng ký, chúng tôi sẽ gửi đường dẫn đặt lại mật khẩu.'**
  String get forgotPasswordMessage;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In vi, this message translates to:
  /// **'Nếu email có trong hệ thống, đường dẫn đặt lại mật khẩu đã được gửi'**
  String get forgotPasswordSent;

  /// No description provided for @sendLabel.
  ///
  /// In vi, this message translates to:
  /// **'Gửi'**
  String get sendLabel;

  /// No description provided for @sessionEnded.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã kết thúc, có thể tài khoản vừa đăng nhập trên máy khác'**
  String get sessionEnded;

  /// No description provided for @changeAvatar.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh đại diện'**
  String get changeAvatar;

  /// No description provided for @pickFromGallery.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh từ thư viện'**
  String get pickFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get takePhoto;

  /// No description provided for @avatarUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật ảnh đại diện'**
  String get avatarUpdated;

  /// No description provided for @errorBlockEnded.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động này đã kết thúc'**
  String get errorBlockEnded;

  /// No description provided for @pullToRefresh.
  ///
  /// In vi, this message translates to:
  /// **'Kéo xuống để tải lại'**
  String get pullToRefresh;

  /// No description provided for @importTemplateCodeHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã chia sẻ bạn bè gửi cho bạn, ví dụ GYM4DAY'**
  String get importTemplateCodeHint;

  /// No description provided for @errorCodeEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa nhập mã'**
  String get errorCodeEmpty;

  /// No description provided for @codeCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã!'**
  String get codeCopied;

  /// No description provided for @nTitleReminder.
  ///
  /// In vi, this message translates to:
  /// **'Sắp tới giờ: {task}'**
  String nTitleReminder(String task);

  /// No description provided for @nBodyPersonalReminder.
  ///
  /// In vi, this message translates to:
  /// **'\"{task}\" bắt đầu lúc {time}.'**
  String nBodyPersonalReminder(String task, String time);

  /// No description provided for @nBodyTribeReminder.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động của nhóm {tribe} bắt đầu lúc {time}.'**
  String nBodyTribeReminder(String tribe, String time);

  /// No description provided for @onbSkip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get onbSkip;

  /// No description provided for @onbNext.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get onbNext;

  /// No description provided for @onbBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get onbBack;

  /// No description provided for @onbWelcomeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng bạn đến với TimeTribe!'**
  String get onbWelcomeTitle;

  /// No description provided for @onbWelcomeBody.
  ///
  /// In vi, this message translates to:
  /// **'Nơi bạn sắp xếp thời gian của mình và hẹn lịch với cả nhóm chỉ trong vài chạm.'**
  String get onbWelcomeBody;

  /// No description provided for @onbPersonalTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch cá nhân gọn gàng'**
  String get onbPersonalTitle;

  /// No description provided for @onbPersonalBody.
  ///
  /// In vi, this message translates to:
  /// **'Chia ngày thành các khối thời gian, tô màu từng việc, áp dụng lịch mẫu và nhận nhắc nhở trước khi bắt đầu.'**
  String get onbPersonalBody;

  /// No description provided for @onbTribeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hẹn lịch nhóm dễ dàng'**
  String get onbTribeTitle;

  /// No description provided for @onbTribeBody.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhóm (Tribe), mời bạn bè bằng mã và xem ngay khung giờ mọi người cùng rảnh, kể cả khi mỗi người ở một múi giờ.'**
  String get onbTribeBody;

  /// No description provided for @onbNotiTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không bỏ lỡ điều gì'**
  String get onbNotiTitle;

  /// No description provided for @onbNotiBody.
  ///
  /// In vi, this message translates to:
  /// **'Nhận thông báo khi nhóm có hoạt động mới, trả lời Tham gia / Không tham gia chỉ với một chạm.'**
  String get onbNotiBody;

  /// No description provided for @onbChoiceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã quen với TimeTribe chưa?'**
  String get onbChoiceTitle;

  /// No description provided for @onbChoiceSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một mục để chúng mình hỗ trợ bạn tốt nhất.'**
  String get onbChoiceSubtitle;

  /// No description provided for @onbChoiceExpert.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đã biết sử dụng'**
  String get onbChoiceExpert;

  /// No description provided for @onbChoiceExpertDesc.
  ///
  /// In vi, this message translates to:
  /// **'Vào thẳng trang chủ và bắt đầu ngay.'**
  String get onbChoiceExpertDesc;

  /// No description provided for @onbChoiceNewbie.
  ///
  /// In vi, this message translates to:
  /// **'Tôi là người mới'**
  String get onbChoiceNewbie;

  /// No description provided for @onbChoiceNewbieDesc.
  ///
  /// In vi, this message translates to:
  /// **'Xem hướng dẫn nhanh các chức năng chính (khoảng 1 phút).'**
  String get onbChoiceNewbieDesc;

  /// No description provided for @tourMenuTitle.
  ///
  /// In vi, this message translates to:
  /// **'Menu chức năng'**
  String get tourMenuTitle;

  /// No description provided for @tourMenuBody.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển giữa Lịch cá nhân, Nhóm và Lịch mẫu tại đây.'**
  String get tourMenuBody;

  /// No description provided for @tourContentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch của bạn'**
  String get tourContentTitle;

  /// No description provided for @tourContentBody.
  ///
  /// In vi, this message translates to:
  /// **'Các khối thời gian trong ngày hiện ở đây. Chọn ngày ở phía trên để xem ngày khác, chạm vào một khối để xem hoặc sửa.'**
  String get tourContentBody;

  /// No description provided for @tourAddTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nút tạo mới'**
  String get tourAddTitle;

  /// No description provided for @tourAddBody.
  ///
  /// In vi, this message translates to:
  /// **'Thêm lịch, tạo hoặc tham gia nhóm, tạo lịch mẫu, tuỳ theo mục bạn đang mở.'**
  String get tourAddBody;

  /// No description provided for @tourNotiTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get tourNotiTitle;

  /// No description provided for @tourNotiBody.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc lịch và lời mời tham gia hoạt động nhóm hiện ở đây. Bạn có thể trả lời ngay trong danh sách.'**
  String get tourNotiBody;

  /// No description provided for @tourProfileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get tourProfileTitle;

  /// No description provided for @tourProfileBody.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh đại diện, tên và múi giờ. Đặt đúng múi giờ để nhóm thấy đúng giờ rảnh của bạn.'**
  String get tourProfileBody;

  /// No description provided for @tourSettingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get tourSettingsTitle;

  /// No description provided for @tourSettingsBody.
  ///
  /// In vi, this message translates to:
  /// **'Đổi giao diện sáng/tối, ngôn ngữ và xem lại hướng dẫn này bất cứ lúc nào.'**
  String get tourSettingsBody;

  /// No description provided for @tourDone.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu thôi!'**
  String get tourDone;

  /// No description provided for @help.
  ///
  /// In vi, this message translates to:
  /// **'Trợ giúp'**
  String get help;

  /// No description provided for @replayTour.
  ///
  /// In vi, this message translates to:
  /// **'Xem hướng dẫn sử dụng'**
  String get replayTour;

  /// No description provided for @replayTourSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu nhanh các chức năng chính'**
  String get replayTourSubtitle;

  /// No description provided for @view.
  ///
  /// In vi, this message translates to:
  /// **'Xem'**
  String get view;

  /// No description provided for @testPush.
  ///
  /// In vi, this message translates to:
  /// **'Gửi thông báo thử'**
  String get testPush;

  /// No description provided for @testPushSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra máy có nhận được thông báo đẩy không'**
  String get testPushSubtitle;

  /// No description provided for @testPushSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi, thông báo sẽ hiện sau vài giây'**
  String get testPushSent;

  /// No description provided for @testPushNoToken.
  ///
  /// In vi, this message translates to:
  /// **'Máy chưa có mã nhận thông báo. Hãy cho phép thông báo cho TimeTribe rồi mở lại app.'**
  String get testPushNoToken;

  /// No description provided for @emailPendingLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ xác nhận: {email}'**
  String emailPendingLabel(String email);

  /// No description provided for @emailVerifySent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi link xác nhận tới {email}. Mở email đó và bấm link để hoàn tất đổi email.'**
  String emailVerifySent(String email);

  /// No description provided for @emailPendingCancel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ đổi email'**
  String get emailPendingCancel;

  /// No description provided for @emailPendingCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ yêu cầu đổi email'**
  String get emailPendingCancelled;

  /// No description provided for @emailPendingHint.
  ///
  /// In vi, this message translates to:
  /// **'Email chỉ thay đổi sau khi bạn bấm link xác nhận gửi tới địa chỉ mới.'**
  String get emailPendingHint;

  /// No description provided for @changePassword.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi mật khẩu đăng nhập bằng email'**
  String get changePasswordSubtitle;

  /// No description provided for @setPassword.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mật khẩu'**
  String get setPassword;

  /// No description provided for @setPasswordSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản Google: tạo mật khẩu để đăng nhập bằng email'**
  String get setPasswordSubtitle;

  /// No description provided for @currentPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu hiện tại'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại mật khẩu mới'**
  String get confirmNewPassword;

  /// No description provided for @errorWrongCurrentPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu hiện tại không đúng'**
  String get errorWrongCurrentPassword;

  /// No description provided for @errorSamePassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu mới phải khác mật khẩu hiện tại'**
  String get errorSamePassword;

  /// No description provided for @changePasswordNote.
  ///
  /// In vi, this message translates to:
  /// **'Sau khi đổi, mọi thiết bị sẽ được đăng xuất và bạn cần đăng nhập lại bằng mật khẩu mới.'**
  String get changePasswordNote;

  /// No description provided for @changePasswordPendingEmail.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đổi email sang {email} đang chờ xác nhận sẽ bị huỷ. Bạn có thể gửi lại yêu cầu sau khi đăng nhập.'**
  String changePasswordPendingEmail(String email);

  /// No description provided for @passwordChangedRelogin.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi mật khẩu. Hãy đăng nhập lại bằng mật khẩu mới.'**
  String get passwordChangedRelogin;

  /// No description provided for @errorEmailTypo.
  ///
  /// In vi, this message translates to:
  /// **'Email có vẻ bị gõ nhầm. Có phải ý bạn là {email}?'**
  String errorEmailTypo(String email);

  /// No description provided for @errorEmailDomainInvalid.
  ///
  /// In vi, this message translates to:
  /// **'Tên miền của email này không nhận được thư, hãy kiểm tra lại'**
  String get errorEmailDomainInvalid;

  /// No description provided for @errorEmailUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa gửi được email lúc này, vui lòng thử lại sau'**
  String get errorEmailUnavailable;

  /// No description provided for @useSuggestion.
  ///
  /// In vi, this message translates to:
  /// **'Dùng {email}'**
  String useSuggestion(String email);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
