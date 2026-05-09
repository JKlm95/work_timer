import 'package:work_timer/models/work_entry.dart';
import 'package:work_timer/models/workspace.dart';
import 'package:work_timer/services/online_checker.dart';
import 'package:work_timer/services/work_remote_store.dart';

/// Stały wynik online/offline do testów [WorkRepository].
class FixedOnlineChecker implements OnlineChecker {
  FixedOnlineChecker(this.online);

  bool online;

  @override
  Future<bool> check() async => online;
}

/// Fałszywy zdalny store — brak Firestore, rejestruje [upsertEntry] i zwraca skonfigurowane listy.
class FakeWorkRemoteStore implements WorkRemoteStore {
  final List<WorkEntry> upsertedEntries = [];
  List<Workspace> workspacesResponse = const [];
  final Map<String, List<WorkEntry>> entriesByWorkspace = {};
  /// Ile następnych wywołań [upsertEntry] ma rzucić wyjątek (symulacja sieci).
  int failNextUpserts = 0;

  void setRangeResult(String workspaceId, List<WorkEntry> entries) {
    entriesByWorkspace[workspaceId] = entries;
  }

  @override
  Future<void> upsertEntry({
    required String uid,
    required WorkEntry entry,
  }) async {
    if (failNextUpserts > 0) {
      failNextUpserts--;
      throw Exception('upsert failed');
    }
    upsertedEntries.add(entry);
  }

  @override
  Future<List<WorkEntry>> fetchEntriesInRange({
    required String uid,
    required String workspaceId,
    required DateTime from,
    required DateTime to,
  }) async {
    return List<WorkEntry>.from(
      entriesByWorkspace[workspaceId] ?? const <WorkEntry>[],
    );
  }

  @override
  Future<void> upsertWorkspace({
    required String uid,
    required Workspace workspace,
  }) async {}

  @override
  Future<List<Workspace>> fetchWorkspaces(String uid) async {
    return List<Workspace>.from(workspacesResponse);
  }
}
