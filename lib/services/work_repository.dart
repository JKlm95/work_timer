import 'package:flutter/material.dart';

import '../models/work_entry.dart';
import '../models/workspace.dart';
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
  }) : _localCache = localCache,
       _remoteStore = remoteStore,
       _onlineChecker = onlineChecker ?? ConnectivityOnlineChecker();

  final LocalCacheStore _localCache;
  final WorkRemoteStore _remoteStore;
  final OnlineChecker _onlineChecker;

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
  String get activeWorkspaceId => _activeWorkspaceId;
  LocalCacheStore get localCache => _localCache;

  Future<void> _loadWorkspaceState() async {
    final localWorkspaces = await _localCache.loadWorkspaces();
    _workspaces = _sortWorkspaces(localWorkspaces);
    _activeWorkspaceId = await _localCache.loadActiveWorkspaceId() ??
        _workspaces.first.id;

    if (await _onlineChecker.check()) {
      final uid = _uid;
      if (uid != null) {
        try {
          final remote = await _remoteStore.fetchWorkspaces(uid);
          final merged = _mergeWorkspaces(_workspaces, remote);
          _workspaces = _sortWorkspaces(merged);
          await _localCache.saveWorkspaces(_workspaces);
          for (final workspace in _workspaces) {
            if (remote.every((r) => r.id != workspace.id)) {
              await _remoteStore.upsertWorkspace(uid: uid, workspace: workspace);
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
  }

  Future<void> selectWorkspace(String workspaceId) async {
    if (_workspaces.every((w) => w.id != workspaceId)) return;
    _activeWorkspaceId = workspaceId;
    await _localCache.saveActiveWorkspaceId(workspaceId);
    await syncPending();
  }

  Future<Workspace> createWorkspace(String name) async {
    final workspace = Workspace(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'Workspace' : name.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _workspaces = _sortWorkspaces(_mergeWorkspaces(_workspaces, [workspace]));
    await _localCache.saveWorkspaces(_workspaces);
    await _localCache.saveActiveWorkspaceId(workspace.id);
    _activeWorkspaceId = workspace.id;
    final uid = _uid;
    if (uid != null && await _onlineChecker.check()) {
      try {
        await _remoteStore.upsertWorkspace(uid: uid, workspace: workspace);
      } catch (_) {}
    }
    return workspace;
  }

  Future<void> renameWorkspace({
    required String workspaceId,
    required String name,
  }) async {
    _workspaces = _workspaces
        .map(
          (w) => w.id == workspaceId
              ? w.copyWith(name: name.trim(), updatedAt: DateTime.now())
              : w,
        )
        .toList();
    await _localCache.saveWorkspaces(_workspaces);
    final uid = _uid;
    final target = _workspaces.firstWhere((w) => w.id == workspaceId);
    if (uid != null && await _onlineChecker.check()) {
      try {
        await _remoteStore.upsertWorkspace(uid: uid, workspace: target);
      } catch (_) {}
    }
  }

  Future<void> addEntry(WorkEntry entry) async {
    final queue = await _localCache.loadPendingQueue(entry.workspaceId);
    final updatedQueue = _upsertById(queue, entry);
    await _localCache.savePendingQueue(entry.workspaceId, updatedQueue);

    if (_isCurrentMonth(entry.start)) {
      final cached = await _localCache.loadCurrentMonthCache(entry.workspaceId);
      final updatedCached = _sortDesc(_upsertById(cached, entry));
      await _localCache.saveCurrentMonthCache(entry.workspaceId, updatedCached);
    }

    await syncPending();
  }

  Future<void> updateEntry(WorkEntry entry) async {
    await addEntry(entry);
  }

  Future<void> deleteEntry(WorkEntry entry) async {
    await addEntry(
      WorkEntry(
        id: entry.id,
        workspaceId: entry.workspaceId,
        start: entry.start,
        end: entry.end,
        mode: entry.mode,
        updatedAt: DateTime.now(),
        isDeleted: true,
      ),
    );
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
      await _localCache.saveCurrentMonthCache(_activeWorkspaceId, remote);
      return EntriesResult(entries: remote, offlineFallback: false);
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
      if (_isCurrentMonthRange(range)) {
        final local = await _localCache.loadCurrentMonthCache(workspaceId);
        if (!await _onlineChecker.check()) {
          results.addAll(local.where((e) => !e.isDeleted));
          continue;
        }
      }
      if (!await _onlineChecker.check()) continue;
      final uid = _uid;
      if (uid == null) continue;
      final remote = await _remoteStore.fetchEntriesInRange(
        uid: uid,
        workspaceId: workspaceId,
        from: from,
        to: to,
      );
      if (_isCurrentMonthRange(range)) {
        await _localCache.saveCurrentMonthCache(workspaceId, remote);
      }
      results.addAll(remote);
    }

    return _sortDesc(results);
  }

  Future<void> syncPending() async {
    final uid = _uid;
    if (uid == null || !await _onlineChecker.check()) return;

    for (final workspace in _workspaces) {
      final queue = await _localCache.loadPendingQueue(workspace.id);
      if (queue.isEmpty) continue;

      final remaining = <WorkEntry>[];
      for (final entry in queue) {
        try {
          await _remoteStore.upsertEntry(uid: uid, entry: entry);
        } catch (e) {
          debugPrint('syncPending error for ${workspace.id}: $e');
          remaining.add(entry);
        }
      }
      await _localCache.savePendingQueue(workspace.id, remaining);
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
      final cache = await _localCache.loadCurrentMonthCache(Workspace.defaultId);
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
