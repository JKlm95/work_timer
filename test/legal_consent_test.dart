import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:work_timer/models/legal_consent_record.dart';

void main() {
  group('LegalConsentRecord', () {
    test('tryParse null → null', () {
      expect(LegalConsentRecord.tryParse(null), isNull);
    });

    test('tryParse missing acceptedAt → null', () {
      final r = LegalConsentRecord.tryParse({
        'termsAccepted': true,
        'privacyAccepted': true,
        'termsVersion': '1.0',
        'privacyVersion': '1.0',
      });
      expect(r, isNull);
    });

    test('tryParse terms false → isSatisfied false', () {
      final r = LegalConsentRecord.tryParse({
        'termsAccepted': false,
        'privacyAccepted': true,
        'acceptedAt': Timestamp.now(),
        'termsVersion': '1.0',
        'privacyVersion': '1.0',
      });
      expect(r, isNotNull);
      expect(r!.isSatisfied, isFalse);
    });

    test('tryParse empty version → null', () {
      final r = LegalConsentRecord.tryParse({
        'termsAccepted': true,
        'privacyAccepted': true,
        'acceptedAt': Timestamp.now(),
        'termsVersion': '',
        'privacyVersion': '1.0',
      });
      expect(r, isNull);
    });

    test('tryParse valid → isSatisfied true', () {
      final r = LegalConsentRecord.tryParse({
        'termsAccepted': true,
        'privacyAccepted': true,
        'acceptedAt': Timestamp.now(),
        'termsVersion': '1.0',
        'privacyVersion': '1.0',
        'acceptedPlatform': 'android',
      });
      expect(r, isNotNull);
      expect(r!.isSatisfied, isTrue);
    });

    test('buildWritePayload contains required keys', () {
      final m = LegalConsentRecord.buildWritePayload(
        termsVersion: '1.0',
        privacyVersion: '1.0',
        acceptedPlatform: 'android',
      );
      expect(m['termsAccepted'], true);
      expect(m['privacyAccepted'], true);
      expect(m['termsVersion'], '1.0');
      expect(m['privacyVersion'], '1.0');
      expect(m['acceptedPlatform'], 'android');
      expect(m['acceptedAt'], isA<FieldValue>());
      expect(m['updatedAt'], isA<FieldValue>());
    });
  });
}
