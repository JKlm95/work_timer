import '../models/work_entry.dart';
import '../models/workspace.dart';

/// Warstwa zdalna (Firestore) — implementacja produkcyjna: [FirebaseWorkStore].
abstract class WorkRemoteStore {
  Future<void> upsertEntry({required String uid, required WorkEntry entry});

  Future<List<WorkEntry>> fetchEntriesInRange({
    required String uid,
    required String workspaceId,
    required DateTime from,
    required DateTime to,
  });

  /// Pojedynczy wpis (np. przed wysłaniem kolejki — porównanie `updatedAt` z serwerem).
  Future<WorkEntry?> fetchEntry({required String uid, required String entryId});

  Future<void> upsertWorkspace({
    required String uid,
    required Workspace workspace,
  });

  Future<List<Workspace>> fetchWorkspaces(String uid);
}
