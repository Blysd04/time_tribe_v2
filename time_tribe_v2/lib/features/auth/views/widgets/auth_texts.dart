import '../../../../core/l10n/l10n.dart';
import '../../viewmodels/auth_viewmodel.dart';

extension AuthTextsX on AppLocalizations {
  /// Đổi mã lỗi xác thực thành câu chữ theo ngôn ngữ đang chọn.
  String? authError(AuthError? e) => switch (e) {
    null => null,
    AuthError.identifierRequired => errorIdentifierRequired,
    AuthError.passwordRequired => errorPasswordRequired,
    AuthError.wrongCredentials => errorWrongCredentials,
    AuthError.nameRequired => errorDisplayNameRequired,
    AuthError.emailRequired => errorEmailRequired,
    AuthError.createPasswordRequired => errorCreatePassword,
    AuthError.passwordMismatch => errorPasswordMismatch,
    AuthError.nameLength => errorNameLength,
    AuthError.emailInvalid => errorEmailInvalid,
    // Câu có gợi ý email đúng do màn hình tự dựng (cần vm.emailSuggestion)
    AuthError.emailTypo => errorEmailInvalid,
    AuthError.emailDomainInvalid => errorEmailDomainInvalid,
    AuthError.passwordTooShort => errorPasswordTooShort,
    AuthError.emailTaken => errorEmailTaken,
    AuthError.nameTaken => errorNameTaken,
    AuthError.accountBanned => errorAccountBanned,
    AuthError.accountDeleted => errorAccountDeleted,
    AuthError.googleAccount => errorGoogleAccount,
    AuthError.googleFailed => errorGoogleFailed,
    AuthError.googleUnsupported => errorGoogleUnsupported,
    AuthError.network => errorNetwork,
    AuthError.server => errorServer,
  };
}
