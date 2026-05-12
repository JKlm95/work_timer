import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Zapis pod MVP: `userEmailIndex/{emailLower}` dla panelu pracodawcy (lookup UID po emailu).
/// Nie blokuje apki przy błędzie — tylko log.
class UserEmailIndexService {
  UserEmailIndexService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const collectionName = 'userEmailIndex';

  /// Zwraca znormalizowany klucz dokumentu albo `null`, gdy nie ma sensu indeksować.
  static String? documentIdForUser(User user) => emailLowerIndexKey(user.email);

  /// Do testów i spójności z [documentIdForUser].
  static String? emailLowerIndexKey(String? email) {
    final raw = email?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw.toLowerCase();
  }

  Future<void> upsertForUser(User user) async {
    final email = user.email?.trim();
    if (email == null || email.isEmpty) return;

    final emailLower = email.toLowerCase();

    final data = <String, Object?>{
      'uid': user.uid,
      'email': email,
      'emailLower': emailLower,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      data['displayName'] = name;
    }

    final ids = user.providerData.map((p) => p.providerId).toSet().toList()
      ..sort();
    if (ids.isNotEmpty) {
      data['providerIds'] = ids;
    }

    try {
      await _db
          .collection(collectionName)
          .doc(emailLower)
          .set(data, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('UserEmailIndexService.upsertForUser: $e\n$st');
    }
  }
}
