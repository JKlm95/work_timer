import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/work_entry.dart';
import '../models/workspace.dart';
import 'work_remote_store.dart';

class FirebaseWorkStore implements WorkRemoteStore {
  FirebaseWorkStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _entriesRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('entries');
  }

  CollectionReference<Map<String, dynamic>> _workspacesRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('workspaces');
  }

  @override
  Future<void> upsertEntry({
    required String uid,
    required WorkEntry entry,
  }) async {
    await _entriesRef(
      uid,
    ).doc(entry.id).set(entry.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<List<WorkEntry>> fetchEntriesInRange({
    required String uid,
    required String workspaceId,
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
        .where((e) => !e.isDeleted && e.workspaceId == workspaceId)
        .toList();
  }

  @override
  Future<void> upsertWorkspace({
    required String uid,
    required Workspace workspace,
  }) async {
    await _workspacesRef(
      uid,
    ).doc(workspace.id).set(workspace.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<List<Workspace>> fetchWorkspaces(String uid) async {
    final snapshot = await _workspacesRef(
      uid,
    ).where('isArchived', isEqualTo: false).get();
    return snapshot.docs.map((doc) {
      String toIso(dynamic value) {
        if (value is Timestamp) return value.toDate().toIso8601String();
        if (value is DateTime) return value.toIso8601String();
        if (value is String) return value;
        return DateTime.now().toIso8601String();
      }

      return Workspace.fromJson({
        'id': doc.id,
        ...doc.data(),
        'createdAt': toIso(doc.data()['createdAt']),
        'updatedAt': toIso(doc.data()['updatedAt']),
      });
    }).toList();
  }
}
