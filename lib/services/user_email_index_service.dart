import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

/// Zapis pod MVP: `userEmailIndex/{emailLower}` dla panelu pracodawcy (lookup UID po emailu).
/// Nie blokuje apki przy błędzie — tylko log. Zwraca `true` przy sukcesie.
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

  /// Wyświetlana nazwa w indeksie: imię+nazwisko z profilu → displayName z Auth → email.
  static String resolveIndexDisplayName({
    required User user,
    UserProfile? profile,
  }) {
    if (profile != null &&
        UserProfile.hasAnyName(profile.firstName, profile.lastName)) {
      return UserProfile.composeDisplayName(
        profile.firstName,
        profile.lastName,
      );
    }
    final authName = user.displayName?.trim();
    if (authName != null && authName.isNotEmpty) return authName;
    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    return '';
  }

  Future<bool> upsertForUser(User user, {UserProfile? profile}) async {
    final email = user.email?.trim();
    if (email == null || email.isEmpty) return false;

    final emailLower = email.toLowerCase();

    final data = <String, Object?>{
      'uid': user.uid,
      'email': email,
      'emailLower': emailLower,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final resolvedDisplay = resolveIndexDisplayName(
      user: user,
      profile: profile,
    );
    if (resolvedDisplay.isNotEmpty) {
      data['displayName'] = resolvedDisplay;
    }

    if (profile != null) {
      data['firstName'] = profile.firstName.trim();
      data['lastName'] = profile.lastName.trim();
    } else {
      data['firstName'] = '';
      data['lastName'] = '';
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
      return true;
    } catch (e, st) {
      debugPrint('UserEmailIndexService.upsertForUser: $e\n$st');
      return false;
    }
  }
}
