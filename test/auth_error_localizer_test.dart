import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:work_timer/l10n/app_localizations.dart';
import 'package:work_timer/utils/auth_error_localizer.dart';

void main() {
  late AppLocalizations en;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    en = lookupAppLocalizations(const Locale('en'));
  });

  test('wrong-password → wrong password message', () {
    expect(
      localizedAuthError(FirebaseAuthException(code: 'wrong-password'), en),
      en.errorAuthWrongPassword,
    );
  });

  test('user-not-found', () {
    expect(
      localizedAuthError(FirebaseAuthException(code: 'user-not-found'), en),
      en.errorAuthUserNotFound,
    );
  });

  test('network-request-failed', () {
    expect(
      localizedAuthError(
        FirebaseAuthException(code: 'network-request-failed'),
        en,
      ),
      en.errorAuthNetwork,
    );
  });

  test('unknown Firebase code → generic', () {
    expect(
      localizedAuthError(FirebaseAuthException(code: 'unknown-code-xyz'), en),
      en.errorAuthGeneric,
    );
  });

  test('non-Firebase → generic', () {
    expect(localizedAuthError(FormatException('bad'), en), en.errorAuthGeneric);
  });
}
