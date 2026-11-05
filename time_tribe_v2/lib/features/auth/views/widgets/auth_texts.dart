import '../../../../core/l10n/l10n.dart';
import '../../viewmodels/auth_viewmodel.dart';

extension AuthTextsX on AppLocalizations {
  String? authError(AuthError? e) => switch (e) {
    null => null,
    AuthError.identifierRequired => errorIdentifierRequired,
    AuthError.passwordRequired => errorPasswordRequired,
    AuthError.wrongCredentials => errorWrongCredentials,
    AuthError.nameRequired => errorDisplayNameRequired,
    AuthError.emailRequired => errorEmailRequired,
    AuthError.createPasswordRequired => errorCreatePassword,
    AuthError.passwordMismatch => errorPasswordMismatch,
  };
}
