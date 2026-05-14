import 'dart:async';

import 'package:flutter/material.dart';

import '../models/billing_currency.dart';
import '../models/work_entry.dart';
import '../models/workspace.dart';
import 'employee_work_email_index_service.dart';
import 'local_cache_store.dart';
import 'online_checker.dart';
import 'work_remote_store.dart';

class EntriesResult {
  EntriesResult({required this.entries, required this.offlineFallback});

  final List<WorkEntry> entries;
  final bool offlineFallback;
}

class WorkRepository {
  WorkRepository({
    required LocalCacheStore localCache,
    required WorkRemoteStore remoteStore,
    OnlineChecker? onlineChecker,
    EmployeeWorkEmailIndexService? workEmailIndex,
  }) : _localCache = localCache,
       _remoteStore = remoteStore,
       _onlineChecker = onlineChecker ?? ConnectivityOnlineChecker(),
       _workEmailIndex = workEmailIndex;

  final LocalCacheStore _localCache;
  final WorkRemoteStore _remoteStore;
  final OnlineChecker _onlineChecker;
  final EmployeeWorkEmailIndexService? _workEmailIndex;

  String? _uid;
  List<Workspace> _workspaces = const [];
  String _activeWorkspaceId = Workspace.defaultId;

  Future<void> initForUser(String uid) async {
    _uid = uid;
    await _runLegacyMigrationOnce();
    await _loadWorkspaceState();
    await syncPending();
  }

  List<Workspace> get workspaces => _workspaces;

  /// Aktualnie wybrany projekt (workspace) — po [selectWorkspace] / [saveWorkspace].
  String get activeWorkspaceId => _activeWorkspaceId;
  LocalCacheStore get localCache => _localCache;

  Future<void> _loadWorkspaceState() async {
    final localWorkspaces = await _localCache.loadWorkspaces();
    _workspaces = _sortWorkspaces(localWorkspaces);
    _activeWorkspaceId =
        await _localCache.loadActiveWorkspaceId() ?? _workspaces.first.id;

    if (await _onlineChecker.check()) {
      final uid = _uid;
      if (uid != null) {
        try {
          final remote = await _remoteStore.fetchWorkspaces(uid);
          final beforeFetch = List<Workspace>.from(_workspaces);
          final merged = _mergeWorkspaces(_workspaces, remote);
          _workspaces = _sortWorkspaces(merged);
          await _localCache.saveWorkspaces(_workspaces);
          await _reconcileWorkEmailIndex(beforeFetch, _workspaces);
          for (final workspace in _workspaces) {
            if (remote.every((r) => r.id != workspace.id)) {
              await _scheduleWorkspaceRemoteUpsert(workspace);
            }
          }
        } catch (e) {
          debugPrint('fetchWorkspaces failed: $e');
        }
      }
    }

    if (_workspaces.every((w) => w.id != _activeWorkspaceId)) {
      _activeWorkspaceId = _workspaces.first.id;
      await _localCache.saveActiveWorkspaceId(_activeWorkspaceId);
    }
    await _ensureActiveNotArchivedPreferably();
  }

  /// Jeśli aktywny jest zarchiwizowany, ustaw pierwszy niezarchiwizowany (best effort).
  Future<void> _ensureActiveNotArchivedPreferably() async {
    final candidates = [
      ..._workspaces.where((w) => w.id == _activeWorkspaceId),
      ..._workspaces.where((w) => w.id != _activeWorkspaceId),
    ];
    Workspace? pick;
    for (final w in candidates) {
      if (!w.isArchived) {
        pick = w;
        break;
      }
    }
    pick ??= candidates.isEmpty
        ? Workspace.defaultWorkspace()
        : candidates.first;
    if (pick.id != _activeWorkspaceId) {
      _activeWorkspaceId = pick.id;
      await _localCache.saveActiveWorkspaceId(_activeWorkspaceId);
    }
  }

  Future<void> selectWorkspace(String workspaceId) async {
    if (_workspaces.every((w) => w.id != workspaceId)) return;
    _activeWorkspaceId = workspaceId;
    await _localCache.saveActiveWorkspaceId(workspaceId);
    await syncPending();
  }

  Future<Workspace> createWorkspace(String name) async {
    final before = List<Workspace>.from(_workspaces);
    final workspace = Workspace(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Workspace' : name.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      currencyCode: BillingCurrency.defaultCode,
    );
    _workspaces = _sortWorkspaces(_mergeWorkspaces(_workspaces, [workspace]));
    await _localCache.saveWorkspaces(_workspaces);
    await _localCache.saveActiveWorkspaceId(workspace.id);
    _activeWorkspaceId = workspace.id;
    await _scheduleWorkspaceRemoteUpsert(workspace);
    await _reconcileWorkEmailIndex(before, List<Workspace>.from(_workspaces));
    return workspace;
  }

  Future<void> renameWorkspace({
    required String workspaceId,
    required String name,
  }) async {
    await saveWorkspace(
      _workspaces
          .firstWhere((w) => w.id == workspaceId)
          .copyWith(name: name.trim(), updatedAt: DateTime.now()),
    );
  }

  Future<void> saveWorkspace(Workspace workspace) async {
    final before = List<Workspace>.from(_workspaces);
    final idx = _workspaces.indexWhere((w) => w.id == workspace.id);
    if (idx >= 0) {
      final next = [..._workspaces];
      next[idx] = workspace;
      _workspaces = _sortWorkspaces(next);
    } else {
      _workspaces = _sortWorkspaces(_mergeWorkspaces(_workspaces, [workspace]));
      _activeWorkspaceId = workspace.id;
      await _localCache.saveActiveWorkspaceId(_activeWorkspaceId);
    }
    await _localCache.saveWorkspaces(_workspaces);
    await _scheduleWorkspaceRemoteUpsert(workspace);
    await _reconcileWorkEmailIndex(before, List<Workspace>.from(_workspaces));
    await _ensureActiveNotArchivedPreferably();
  }

  Future<void> setArchived(String workspaceId, bool archived) async {
    final w = _workspaces.firstWhere((x) => x.id == workspaceId);
    await saveWorkspace(
      w.copyWith(isArchived: archived, updatedAt: DateTime.now()),
    );
  }

  Future<void> addEntry(WorkEntry entry, {bool awaitRemoteSync = true}) async {
    final queue = await _localCache.loadPendingQueue(entry.workspaceId);
    final updatedQueue = _upsertById(queue, entry);
    await _localCache.savePendingQueue(entry.workspaceId, updatedQueue);

    if (_isCurrentMonth(entry.start)) {
      final cached = await _localCache.loadCurrentMonthCache(entry.workspaceId);
      final updatedCached = _sortDesc(_upsertById(cached, entry));
      await _localCache.saveCurrentMonthCache(entry.workspaceId, updatedCached);
    }

    if (awaitRemoteSync) {
      await syncPending();
    } else {
      unawaited(syncPending());
    }
  }

  Future<void> updateEntry(WorkEntry entry) async {
    await addEntry(entry);
  }

  Future<void> deleteEntry(WorkEntry entry) async {
    await addEntry(entry.copyWith(isDeleted: true, updatedAt: DateTime.now()));
  }

  Future<EntriesResult> loadEntriesForRange(DateTimeRange range) async {
    final from = _dayStart(range.start);
    final to = _dayEnd(range.end);

    if (_isCurrentMonthRange(range)) {
      final local = _sortDesc(
        await _localCache.loadCurrentMonthCache(_activeWorkspaceId),
      );
      if (!await _onlineChecker.check()) {
        return EntriesResult(entries: local, offlineFallback: true);
      }

      final remote = await _fetchRemote(from: from, to: to);
      final merged = _sortDesc(
        _mergedVisibleMonthEntries(remote: remote, local: local),
      );
      await _localCache.saveCurrentMonthCache(_activeWorkspaceId, merged);
      return EntriesResult(entries: merged, offlineFallback: false);
    }

    if (!await _onlineChecker.check()) {
      return EntriesResult(entries: [], offlineFallback: true);
    }

    final remote = await _fetchRemote(from: from, to: to);
    return EntriesResult(entries: remote, offlineFallback: false);
  }

  Future<List<WorkEntry>> loadEntriesForWorkspaces({
    required DateTimeRange range,
    required Set<String> workspaceIds,
  }) async {
    final targetIds = workspaceIds.isEmpty
        ? _workspaces.map((w) => w.id).toList()
        : workspaceIds.toList();
    final from = _dayStart(range.start);
    final to = _dayEnd(range.end);
    final results = <WorkEntry>[];

    for (final workspaceId in targetIds) {
      final online = await _onlineChecker.check();

      if (_isCurrentMonthRange(range)) {
        final localMonth = await _localCache.loadCurrentMonthCache(workspaceId);
        if (!online) {
          results.addAll(localMonth.where((e) => e.countsInTimeAggregates));
          continue;
        }
        final uid = _uid;
        if (uid == null) continue;
        final remote = await _remoteStore.fetchEntriesInRange(
          uid: uid,
          workspaceId: workspaceId,
          from: from,
          to: to,
        );
        final merged = _sortDesc(
          _mergedVisibleMonthEntries(remote: remote, local: localMonth),
        );
        await _localCache.saveCurrentMonthCache(workspaceId, merged);
        results.addAll(merged);
        continue;
      }

      if (!online) continue;
      final uid = _uid;
      if (uid == null) continue;
      results.addAll(
        await _remoteStore.fetchEntriesInRange(
          uid: uid,
          workspaceId: workspaceId,
          from: from,
          to: to,
        ),
      );
    }

    return _sortDesc(results);
  }

  Future<void> syncPending() async {
    final uid = _uid;
    if (uid == null || !await _onlineChecker.check()) return;

    final beforeWorkspaceFlush = List<Workspace>.from(_workspaces);
    await _flushPendingWorkspaceUpserts();
    await _reconcileWorkEmailIndex(
      beforeWorkspaceFlush,
      List<Workspace>.from(_workspaces),
    );

    for (final workspace in _workspaces) {
      final queue = await _localCache.loadPendingQueue(workspace.id);
      if (queue.isEmpty) continue;

      final remaining = <WorkEntry>[];
      for (final entry in queue) {
        try {
          final remote = await _remoteStore.fetchEntry(
            uid: uid,
            entryId: entry.id,
          );
          if (remote != null && remote.updatedAt.isAfter(entry.updatedAt)) {
            // Serwer (np. panel pracodawcy) ma nowszą wersję — nie nadpisujemy.
            continue;
          }
          await _remoteStore.upsertEntry(uid: uid, entry: entry);
        } catch (e) {
          debugPrint('syncPending error for ${workspace.id}: $e');
          remaining.add(entry);
        }
      }
      await _localCache.savePendingQueue(workspace.id, remaining);
    }
  }

  Future<void> _reconcileWorkEmailIndex(
    List<Workspace> before,
    List<Workspace> after,
  ) async {
    final svc = _workEmailIndex;
    final uid = _uid;
    if (svc == null || uid == null) return;
    try {
      await svc.reconcile(uid: uid, before: before, after: after);
    } catch (e, st) {
      debugPrint('WorkRepository._reconcileWorkEmailIndex: $e\n$st');
    }
  }

  Future<void> _flushPendingWorkspaceUpserts() async {
    final uid = _uid;
    if (uid == null) return;

    final pending = await _localCache.loadWorkspacesUpsertPending();
    if (pending.isEmpty) return;

    final remaining = <Workspace>[];
    for (final w in pending) {
      try {
        await _remoteStore.upsertWorkspace(uid: uid, workspace: w);
      } catch (e) {
        debugPrint('syncPending workspace ${w.id}: $e');
        remaining.add(w);
      }
    }
    await _localCache.saveWorkspacesUpsertPending(remaining);
  }

  /// Zapis workspace’u do Firestore; przy braku sieci / błędzie — kolejka lokalna.
  Future<void> _scheduleWorkspaceRemoteUpsert(Workspace workspace) async {
    final uid = _uid;
    if (uid == null) {
      await _localCache.enqueueWorkspaceUpsert(workspace);
      return;
    }
    if (!await _onlineChecker.check()) {
      await _localCache.enqueueWorkspaceUpsert(workspace);
      return;
    }
    try {
      await _remoteStore.upsertWorkspace(uid: uid, workspace: workspace);
    } catch (e) {
      debugPrint('upsertWorkspace ${workspace.id}: $e');
      await _localCache.enqueueWorkspaceUpsert(workspace);
    }
  }

  Future<void> _runLegacyMigrationOnce() async {
    final uid = _uid;
    if (uid == null) return;

    if (await _localCache.isMigrationDone(uid)) return;

    final legacy = await _localCache.loadLegacyEntries();
    final currentMonth = legacy.where((e) => _isCurrentMonth(e.start)).toList();
    final normalizedCurrent = currentMonth
        .map(
          (e) => WorkEntry(
            id: e.id,
            workspaceId: e.workspaceId,
            start: e.start,
            end: e.end,
            mode: e.mode,
            updatedAt: e.updatedAt,
            isDeleted: e.isDeleted,
          ),
        )
        .toList();
    if (currentMonth.isNotEmpty) {
      final cache = await _localCache.loadCurrentMonthCache(
        Workspace.defaultId,
      );
      final merged = [...cache];
      for (final entry in normalizedCurrent) {
        merged.removeWhere((e) => e.id == entry.id);
        merged.add(entry);
      }
      await _localCache.saveCurrentMonthCache(
        Workspace.defaultId,
        _sortDesc(merged),
      );

      final queue = await _localCache.loadPendingQueue(Workspace.defaultId);
      final withQueued = [...queue];
      for (final entry in normalizedCurrent) {
        withQueued.removeWhere((e) => e.id == entry.id);
        withQueued.add(entry);
      }
      await _localCache.savePendingQueue(
        Workspace.defaultId,
        _sortDesc(withQueued),
      );
    }

    final existingWorkspaces = await _localCache.loadWorkspaces();
    if (existingWorkspaces.isEmpty) {
      await _localCache.saveWorkspaces([Workspace.defaultWorkspace()]);
    }
    final active = await _localCache.loadActiveWorkspaceId();
    if (active == null) {
      await _localCache.saveActiveWorkspaceId(Workspace.defaultId);
    }

    await _localCache.markMigrationDone(uid);
  }

  Future<List<WorkEntry>> _fetchRemote({
    required DateTime from,
    required DateTime to,
  }) async {
    final uid = _uid;
    if (uid == null) return [];
    final remote = await _remoteStore.fetchEntriesInRange(
      uid: uid,
      workspaceId: _activeWorkspaceId,
      from: from,
      to: to,
    );
    return _sortDesc(remote);
  }

  bool _isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  bool _isCurrentMonthRange(DateTimeRange range) {
    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month, 1);
    final endMonth = DateTime(now.year, now.month + 1, 0);
    return !range.start.isBefore(startMonth) && !range.end.isAfter(endMonth);
  }

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _dayEnd(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  List<WorkEntry> _sortDesc(List<WorkEntry> items) {
    items.sort((a, b) => b.start.compareTo(a.start));
    return items;
  }

  /// Scala Firestore z cache miesięcznym przy **online**.
  /// Sam „remote” mógł wyzerować listę zaraz po świeżym wpiszie (Firestore jeszcze
  /// nie widzi dokumentu lub `syncPending` w toku); wcześniej nadpisywaliśmy cache
  /// tylko serwerem i **traciliśmy** lokalnie zapisane wpisy nowego workspace’u.
  List<WorkEntry> _mergedVisibleMonthEntries({
    required List<WorkEntry> remote,
    required List<WorkEntry> local,
  }) {
    final byId = <String, WorkEntry>{};
    void mergeIn(Iterable<WorkEntry> list) {
      for (final e in list) {
        final prev = byId[e.id];
        if (prev == null || !e.updatedAt.isBefore(prev.updatedAt)) {
          byId[e.id] = e;
        }
      }
    }

    mergeIn(remote);
    mergeIn(local);
    return byId.values.where((e) => e.countsInTimeAggregates).toList();
  }

  List<WorkEntry> _upsertById(List<WorkEntry> source, WorkEntry entry) {
    final updated = [...source];
    updated.removeWhere((e) => e.id == entry.id);
    updated.add(entry);
    return updated;
  }

  List<Workspace> _sortWorkspaces(List<Workspace> workspaces) {
    workspaces.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return workspaces;
  }

  List<Workspace> _mergeWorkspaces(
    List<Workspace> local,
    List<Workspace> remote,
  ) {
    final byId = <String, Workspace>{for (final w in local) w.id: w};
    for (final w in remote) {
      byId[w.id] = w;
    }
    if (byId.isEmpty) {
      byId[Workspace.defaultId] = Workspace.defaultWorkspace();
    }
    return byId.values.toList();
  }
}
