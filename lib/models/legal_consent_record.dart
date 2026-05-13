import 'package:cloud_firestore/cloud_firestore.dart';

/// Dokument Firestore: `users/{uid}/legal/consents`.
class LegalConsentRecord {
  const LegalConsentRecord({
    required this.termsAccepted,
    required this.privacyAccepted,
    required this.acceptedAt,
    required this.termsVersion,
    required this.privacyVersion,
    this.updatedAt,
    this.acceptedPlatform,
  });

  final bool termsAccepted;
  final bool privacyAccepted;
  final DateTime acceptedAt;
  final String termsVersion;
  final String privacyVersion;
  final DateTime? updatedAt;
  final String? acceptedPlatform;

  /// Odczyt lokalny: dokument istnieje i spełnia minimalne wymagania aplikacji.
  bool get isSatisfied =>
      termsAccepted &&
      privacyAccepted &&
      termsVersion.isNotEmpty &&
      privacyVersion.isNotEmpty;

  static Map<String, dynamic> buildWritePayload({
    required String termsVersion,
    required String privacyVersion,
    required String acceptedPlatform,
  }) {
    final now = FieldValue.serverTimestamp();
    return {
      'termsAccepted': true,
      'privacyAccepted': true,
      'acceptedAt': now,
      'termsVersion': termsVersion,
      'privacyVersion': privacyVersion,
      'updatedAt': now,
      'acceptedPlatform': acceptedPlatform,
    };
  }

  static LegalConsentRecord? tryParse(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    try {
      final terms = raw['termsAccepted'];
      final privacy = raw['privacyAccepted'];
      final at = raw['acceptedAt'];
      final tv = raw['termsVersion'];
      final pv = raw['privacyVersion'];
      if (terms is! bool || privacy is! bool) return null;
      if (tv is! String || pv is! String) return null;
      if (tv.isEmpty || pv.isEmpty) return null;
      DateTime? accepted;
      if (at is Timestamp) {
        accepted = at.toDate();
      } else if (at is DateTime) {
        accepted = at;
      }
      if (accepted == null) return null;
      DateTime? updated;
      final u = raw['updatedAt'];
      if (u is Timestamp) {
        updated = u.toDate();
      } else if (u is DateTime) {
        updated = u;
      }
      final platform = raw['acceptedPlatform'];
      return LegalConsentRecord(
        termsAccepted: terms,
        privacyAccepted: privacy,
        acceptedAt: accepted,
        termsVersion: tv,
        privacyVersion: pv,
        updatedAt: updated,
        acceptedPlatform: platform is String ? platform : null,
      );
    } catch (_) {
      return null;
    }
  }
}
