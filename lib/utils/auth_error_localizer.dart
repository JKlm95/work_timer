import 'package:firebase_auth/firebase_auth.dart';

import '../l10n/app_localizations.dart';

/// Zamienia wyjątki Firebase Auth na czytelny komunikat UI (bez surowego [Object.toString]).
String localizedAuthError(Object error, AppLocalizations l10n) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return l10n.errorAuthInvalidEmail;
      case 'user-not-found':
        return l10n.errorAuthUserNotFound;
      case 'wrong-password':
        return l10n.errorAuthWrongPassword;
      case 'email-already-in-use':
        return l10n.errorAuthEmailInUse;
      case 'weak-password':
        return l10n.errorAuthWeakPassword;
      case 'network-request-failed':
        return l10n.errorAuthNetwork;
      case 'too-many-requests':
        return l10n.errorAuthTooManyRequests;
      case 'user-disabled':
        return l10n.errorAuthUserDisabled;
      case 'invalid-credential':
      case 'invalid-verification-code':
      case 'invalid-verification-id':
        return l10n.errorAuthInvalidCredential;
      case 'operation-not-allowed':
        return l10n.errorAuthOperationNotAllowed;
      default:
        return l10n.errorAuthGeneric;
    }
  }
  return l10n.errorAuthGeneric;
}
