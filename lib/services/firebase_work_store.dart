import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/work_entry.dart';

class FirebaseWorkStore {
  FirebaseWorkStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _entriesRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('entries');
  }

  Future<void> upsertEntry({
    required String uid,
    required WorkEntry entry,
  }) async {
    await _entriesRef(
      uid,
    ).doc(entry.id).set(entry.toFirestore(), SetOptions(merge: true));
  }

  Future<List<WorkEntry>> fetchEntriesInRange({
    required String uid,
    required DateTime from,
    required DateTime to,
  }) async {
    final snapshot = await _entriesRef(uid)
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('start', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('start', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => WorkEntry.fromFirestore(doc.id, doc.data()))
        .where((e) => !e.isDeleted)
        .toList();
  }
}
