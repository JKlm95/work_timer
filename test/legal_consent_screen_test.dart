import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:work_timer/l10n/app_localizations.dart';
import 'package:work_timer/models/legal_consent_record.dart';
import 'package:work_timer/screens/legal_consent_screen.dart';
import 'package:work_timer/services/legal_consent_repository.dart';

/// Odzwierciedla logikę „czy można wejść do appki” z [LegalConsentRepository.checkGate]
/// dla danych z dokumentu (bez rozróżnienia „brak dokumentu” vs „same null”).
LegalConsentGate gateForDocData(Map<String, dynamic>? data) {
  if (data == null) return LegalConsentGate.needsAcceptance;
  final parsed = LegalConsentRecord.tryParse(data);
  if (parsed == null || !parsed.isSatisfied) {
    return LegalConsentGate.needsAcceptance;
  }
  return LegalConsentGate.satisfied;
}

class _FakeLegalDs implements LegalConsentDataSource {
  int saveCount = 0;
  Object? throwOnSave;
  Future<void>? blockSaveUntil;

  @override
  Future<LegalConsentGate> checkGate(String uid) async =>
      LegalConsentGate.satisfied;

  @override
  Future<void> saveAcceptance({
    required String uid,
    required String termsVersion,
    required String privacyVersion,
    required String acceptedPlatform,
  }) async {
    saveCount++;
    if (blockSaveUntil != null) await blockSaveUntil!;
    final err = throwOnSave;
    if (err != null) throw err;
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  group('gateForDocData (spójność z repozytorium)', () {
    test('null → needsAcceptance', () {
      expect(gateForDocData(null), LegalConsentGate.needsAcceptance);
    });

    test('uszkodzony dokument → needsAcceptance', () {
      expect(
        gateForDocData({
          'termsAccepted': true,
          'privacyAccepted': true,
          'termsVersion': '1.0',
          'privacyVersion': '1.0',
        }),
        LegalConsentGate.needsAcceptance,
      );
    });

    test('terms false → needsAcceptance', () {
      expect(
        gateForDocData({
          'termsAccepted': false,
          'privacyAccepted': true,
          'acceptedAt': Timestamp.now(),
          'termsVersion': '1.0',
          'privacyVersion': '1.0',
        }),
        LegalConsentGate.needsAcceptance,
      );
    });
  });

  group('LegalConsentScreen', () {
    testWidgets('Continue wyłączone dopóki checkbox nie jest zaznaczony', (
      WidgetTester tester,
    ) async {
      final fake = _FakeLegalDs();
      var saved = false;
      await tester.pumpWidget(
        _wrap(
          LegalConsentScreen(
            uid: 'u1',
            repository: fake,
            onConsentSaved: () => saved = true,
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNull);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(fake.saveCount, 1);
      expect(saved, isTrue);
    });

    testWidgets('błąd zapisu pokazuje komunikat i nie woła onConsentSaved', (
      WidgetTester tester,
    ) async {
      final fake = _FakeLegalDs()..throwOnSave = Exception('offline');
      var saved = false;
      await tester.pumpWidget(
        _wrap(
          LegalConsentScreen(
            uid: 'u1',
            repository: fake,
            onConsentSaved: () => saved = true,
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not save'), findsOneWidget);
      expect(saved, isFalse);
      expect(fake.saveCount, 1);
    });

    testWidgets('w trakcie zapisu drugi submit nie wywołuje ponownego save', (
      WidgetTester tester,
    ) async {
      final c = Completer<void>();
      final fake = _FakeLegalDs()..blockSaveUntil = c.future;

      await tester.pumpWidget(
        _wrap(
          LegalConsentScreen(
            uid: 'u1',
            repository: fake,
            onConsentSaved: () {},
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(fake.saveCount, 1);
      final btnMid = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btnMid.onPressed, isNull);

      c.complete();
      await tester.pumpAndSettle();
      expect(fake.saveCount, 1);
    });
  });
}
