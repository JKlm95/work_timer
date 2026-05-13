import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/workspace.dart';

/// Map pod `set(..., SetOptions(merge: true))` dla `users/{uid}/workspaces/{id}`.
///
/// Przy `isSharedWithEmployer == false` usuwa pola udostępniania (`FieldValue.delete()`),
/// żeby merge nie zostawiał starych danych z Firestore.
Map<String, dynamic> workspaceFirestoreMergeWrite(Workspace w) {
  final m = Map<String, dynamic>.from(w.toFirestore());
  const sharingKeys = <String>[
    'companyName',
    'companySlug',
    'employeeWorkEmail',
    'employeeWorkEmailDomain',
    'linkedEmployerEmails',
  ];

  if (!w.isSharedWithEmployer) {
    m['isSharedWithEmployer'] = false;
    for (final k in sharingKeys) {
      m[k] = FieldValue.delete();
    }
    return m;
  }

  m['isSharedWithEmployer'] = true;
  m['linkedEmployerEmails'] = w.linkedEmployerEmails;

  void stringOrDelete(String key, String? v) {
    final t = v?.trim();
    if (t == null || t.isEmpty) {
      m[key] = FieldValue.delete();
    } else {
      m[key] = t;
    }
  }

  stringOrDelete('companyName', w.companyName);
  stringOrDelete('companySlug', w.companySlug);
  stringOrDelete('employeeWorkEmail', w.employeeWorkEmail);
  stringOrDelete('employeeWorkEmailDomain', w.employeeWorkEmailDomain);

  return m;
}
