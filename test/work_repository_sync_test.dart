import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:work_timer/models/work_entry.dart';
import 'package:work_timer/models/work_mode.dart';
import 'package:work_timer/models/workspace.dart';
import 'package:work_timer/services/local_cache_store.dart';
import 'package:work_timer/services/work_repository.dart';

import 'support/work_repository_test_doubles.dart';

void main() {
  const uid = 'test-user-sync';

  Future<void> markMigrationDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('migration_done_v1_$uid', true);
  }

  test('syncPending wysyła kolejkę do zdalnego store i czyści ją przy sukcesie', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await markMigrationDone();

    final cache = LocalCacheStore();
    final remote = FakeWorkRemoteStore();
    final online = FixedOnlineChecker(true);

    final entry = WorkEntry(
      id: 'e1',
      workspaceId: Workspace.defaultId,
      start: DateTime(2026, 5, 10, 9),
      end: DateTime(2026, 5, 10, 10),
      mode: WorkMode.office,
      updatedAt: DateTime(2026, 5, 10, 10),
    );
    await cache.savePendingQueue(Workspace.defaultId, [entry]);

    final repo = WorkRepository(
      localCache: cache,
      remoteStore: remote,
      onlineChecker: online,
    );
    await repo.initForUser(uid);

    expect(remote.upsertedEntries.length, 1);
    expect(remote.upsertedEntries.single.id, 'e1');
    final queueAfter = await cache.loadPendingQueue(Workspace.defaultId);
    expect(queueAfter, isEmpty);
  });

  test('syncPending offline nie wywołuje upsertEntry', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await markMigrationDone();

    final cache = LocalCacheStore();
    final remote = FakeWorkRemoteStore();
    final online = FixedOnlineChecker(false);

    final entry = WorkEntry(
      id: 'e-off',
      workspaceId: Workspace.defaultId,
      start: DateTime(2026, 5, 10, 9),
      end: DateTime(2026, 5, 10, 10),
      mode: WorkMode.office,
      updatedAt: DateTime(2026, 5, 10, 10),
    );
    await cache.savePendingQueue(Workspace.defaultId, [entry]);

    final repo = WorkRepository(
      localCache: cache,
      remoteStore: remote,
      onlineChecker: online,
    );
    await repo.initForUser(uid);

    expect(remote.upsertedEntries, isEmpty);
    final queueAfter = await cache.loadPendingQueue(Workspace.defaultId);
    expect(queueAfter.length, 1);
  });

  test('syncPending zostawia wpis w kolejce po błędzie upsert', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await markMigrationDone();

    final cache = LocalCacheStore();
    final remote = FakeWorkRemoteStore()..failNextUpserts = 1;
    final online = FixedOnlineChecker(true);

    final entry = WorkEntry(
      id: 'e-fail',
      workspaceId: Workspace.defaultId,
      start: DateTime(2026, 5, 10, 9),
      end: DateTime(2026, 5, 10, 10),
      mode: WorkMode.office,
      updatedAt: DateTime(2026, 5, 10, 10),
    );
    await cache.savePendingQueue(Workspace.defaultId, [entry]);

    final repo = WorkRepository(
      localCache: cache,
      remoteStore: remote,
      onlineChecker: online,
    );
    await repo.initForUser(uid);

    expect(remote.upsertedEntries, isEmpty);
    final queueAfter = await cache.loadPendingQueue(Workspace.defaultId);
    expect(queueAfter.length, 1);
    expect(queueAfter.single.id, 'e-fail');
  });

  test('addEntry dokłada do kolejki i przy online wywołuje sync', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await markMigrationDone();

    final cache = LocalCacheStore();
    final remote = FakeWorkRemoteStore();
    final online = FixedOnlineChecker(true);
    final repo = WorkRepository(
      localCache: cache,
      remoteStore: remote,
      onlineChecker: online,
    );
    await repo.initForUser(uid);

    final entry = WorkEntry(
      id: 'e-new',
      workspaceId: Workspace.defaultId,
      start: DateTime(2026, 5, 11, 8),
      end: DateTime(2026, 5, 11, 9),
      mode: WorkMode.remote,
      updatedAt: DateTime(2026, 5, 11, 9),
    );
    await repo.addEntry(entry);

    expect(remote.upsertedEntries.map((e) => e.id), contains('e-new'));
    final queueAfter = await cache.loadPendingQueue(Workspace.defaultId);
    expect(queueAfter, isEmpty);
  });
}
