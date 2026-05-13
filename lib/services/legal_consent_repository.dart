import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/legal_consent_record.dart';

/// Wynik weryfikacji dokumentu zgód (bez wyjątku = sieć OK).
enum LegalConsentGate {
  /// Dokument poprawny i `terms` + `privacy` zaakceptowane.
  satisfied,

  /// Brak dokumentu lub dane nieparsowalne / niespełniające [LegalConsentRecord.isSatisfied].
  needsAcceptance,

  /// Błąd odczytu (offline, permission, inne).
  fetchFailed,
}

/// Abstrakcja pod testy i ekran zgód (bez Firebase w widget testach).
abstract class LegalConsentDataSource {
  Future<LegalConsentGate> checkGate(String uid);

  Future<void> saveAcceptance({
    required String uid,
    required String termsVersion,
    required String privacyVersion,
    required String acceptedPlatform,
  });
}

/// Odczyt i zapis `users/{uid}/legal/consents` (tylko właściciel — patrz `firestore.rules`).
class LegalConsentRepository implements LegalConsentDataSource {
  LegalConsentRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      _db.collection('users').doc(uid).collection('legal').doc('consents');

  @override
  Future<LegalConsentGate> checkGate(String uid) async {
    try {
      final snap = await _ref(uid).get();
      if (!snap.exists) return LegalConsentGate.needsAcceptance;
      final data = snap.data();
      final parsed = LegalConsentRecord.tryParse(data);
      if (parsed == null || !parsed.isSatisfied) {
        return LegalConsentGate.needsAcceptance;
      }
      return LegalConsentGate.satisfied;
    } catch (_) {
      return LegalConsentGate.fetchFailed;
    }
  }

  @override
  Future<void> saveAcceptance({
    required String uid,
    required String termsVersion,
    required String privacyVersion,
    required String acceptedPlatform,
  }) async {
    await _ref(uid).set(
      LegalConsentRecord.buildWritePayload(
        termsVersion: termsVersion,
        privacyVersion: privacyVersion,
        acceptedPlatform: acceptedPlatform,
      ),
    );
  }
}
