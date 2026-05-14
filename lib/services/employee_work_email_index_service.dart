import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/workspace.dart';
import '../utils/project_field_utils.dart';

/// Indeks `employeeWorkEmailIndex/{workEmailLower}` — lookup UID + workspace’y po służbowym e-mailu (panel web).
///
/// Nie blokuje apki przy błędzie — tylko log.
class EmployeeWorkEmailIndexService {
  EmployeeWorkEmailIndexService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const collectionName = 'employeeWorkEmailIndex';

  /// Mapa: znormalizowany work email → posortowane id workspace’ów (tylko shared + poprawny e-mail).
  @visibleForTesting
  static Map<String, List<String>> buildDesiredEmailWorkspaceMap(
    List<Workspace> workspaces,
  ) {
    final m = <String, List<String>>{};
    for (final w in workspaces) {
      if (!w.isSharedWithEmployer) continue;
      final em = normalizeEmployeeWorkEmail(w.employeeWorkEmail);
      if (em == null) continue;
      m.putIfAbsent(em, () => []).add(w.id);
    }
    for (final k in m.keys.toList()) {
      m[k] = (m[k]!.toSet().toList()..sort());
    }
    return m;
  }

  /// Uaktualnia dokumenty indeksu na podstawie pełnej listy workspace’ów przed i po zmianie.
  Future<void> reconcile({
    required String uid,
    required List<Workspace> before,
    required List<Workspace> after,
  }) async {
    final oldM = buildDesiredEmailWorkspaceMap(before);
    final newM = buildDesiredEmailWorkspaceMap(after);
    final emails = {...oldM.keys, ...newM.keys};
    for (final email in emails) {
      final oldIds = oldM[email] ?? const <String>[];
      final newIds = newM[email] ?? const <String>[];
      if (_listEq(oldIds, newIds)) continue;
      await _writeOne(uid: uid, workEmailLower: email, workspaceIds: newIds);
    }
  }

  bool _listEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _writeOne({
    required String uid,
    required String workEmailLower,
    required List<String> workspaceIds,
  }) async {
    final ref = _db.collection(collectionName).doc(workEmailLower);
    if (workspaceIds.isEmpty) {
      try {
        final snap = await ref.get();
        if (!snap.exists) return;
        final d = snap.data();
        if (d == null) return;
        if (d['uid'] == uid) {
          await ref.delete();
        }
      } catch (e, st) {
        debugPrint(
          'EmployeeWorkEmailIndexService delete $workEmailLower: $e\n$st',
        );
      }
      return;
    }

    final domain = extractEmailDomain(workEmailLower);
    if (domain == null || domain.isEmpty) return;

    try {
      await ref.set({
        'uid': uid,
        'workEmailLower': workEmailLower,
        'domain': domain,
        'workspaceIds': workspaceIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      debugPrint('EmployeeWorkEmailIndexService set $workEmailLower: $e\n$st');
    }
  }
}
