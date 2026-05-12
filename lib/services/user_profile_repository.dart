import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const docId = 'main';

  DocumentReference<Map<String, dynamic>> _ref(String uid) {
    return _db.collection('users').doc(uid).collection('profile').doc(docId);
  }

  Future<UserProfile?> load(String uid) async {
    final snap = await _ref(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return UserProfile.fromFirestore(snap.data()!);
  }

  /// Wymaga co najmniej jednego niepustego imienia lub nazwiska (walidacja w warstwie wyżej).
  Future<void> save({
    required String uid,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final profile = UserProfile(
      firstName: firstName,
      lastName: lastName,
      displayName: UserProfile.composeDisplayName(firstName, lastName),
      email: email,
    );
    await _ref(uid).set(
      profile.toFirestore(updatedAt: FieldValue.serverTimestamp()),
      SetOptions(merge: true),
    );
  }
}
