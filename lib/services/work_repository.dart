import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../models/work_entry.dart';
import 'firebase_work_store.dart';
import 'local_cache_store.dart';

class EntriesResult {
  EntriesResult({required this.entries, required this.offlineFallback});

  final List<WorkEntry> entries;
  final bool offlineFallback;
}

class WorkRepository {
  WorkRepository({
    required LocalCacheStore localCache,
    required FirebaseWorkStore remoteStore,
    Connectivity? connectivity,
  }) : _localCache = localCache,
       _remoteStore = remoteStore,
       _connectivity = connectivity ?? Connectivity();

  final LocalCacheStore _localCache;
  final FirebaseWorkStore _remoteStore;
  final Connectivity _connectivity;

  String? _uid;

  Future<void> initForUser(String uid) async {
    _uid = uid;
    await _runLegacyMigrationOnce();
    await syncPending();
  }

  Future<void> addEntry(WorkEntry entry) async {
    final queue = await _localCache.loadPendingQueue();
    final updatedQueue = _upsertById(queue, entry);
    await _localCache.savePendingQueue(updatedQueue);

    if (_isCurrentMonth(entry.start)) {
      final cached = await _localCache.loadCurrentMonthCache();
      final updatedCached = _sortDesc(_upsertById(cached, entry));
      await _localCache.saveCurrentMonthCache(updatedCached);
    }

    await syncPending();
  }

  Future<EntriesResult> loadEntriesForRange(DateTimeRange range) async {
    final from = _dayStart(range.start);
    final to = _dayEnd(range.end);

    if (_isCurrentMonthRange(range)) {
      final local = _sortDesc(await _localCache.loadCurrentMonthCache());
      if (!await _isOnline()) {
        return EntriesResult(entries: local, offlineFallback: true);
      }

      final remote = await _fetchRemote(from: from, to: to);
      await _localCache.saveCurrentMonthCache(remote);
      return EntriesResult(entries: remote, offlineFallback: false);
    }

    if (!await _isOnline()) {
      return EntriesResult(entries: [], offlineFallback: true);
    }

    final remote = await _fetchRemote(from: from, to: to);
    return EntriesResult(entries: remote, offlineFallback: false);
  }

  Future<void> syncPending() async {
    final uid = _uid;
    if (uid == null || !await _isOnline()) return;

    final queue = await _localCache.loadPendingQueue();
    if (queue.isEmpty) return;

    final remaining = <WorkEntry>[];
    for (final entry in queue) {
      try {
        await _remoteStore.upsertEntry(uid: uid, entry: entry);
      } catch (_) {
        remaining.add(entry);
      }
    }
    await _localCache.savePendingQueue(remaining);
  }

  Future<void> _runLegacyMigrationOnce() async {
    final uid = _uid;
    if (uid == null) return;

    if (await _localCache.isMigrationDone(uid)) return;

    final legacy = await _localCache.loadLegacyEntries();
    final currentMonth = legacy.where((e) => _isCurrentMonth(e.start)).toList();
    if (currentMonth.isNotEmpty) {
      final cache = await _localCache.loadCurrentMonthCache();
      final merged = [...cache];
      for (final entry in currentMonth) {
        merged.removeWhere((e) => e.id == entry.id);
        merged.add(entry);
      }
      await _localCache.saveCurrentMonthCache(_sortDesc(merged));

      final queue = await _localCache.loadPendingQueue();
      final withQueued = [...queue];
      for (final entry in currentMonth) {
        withQueued.removeWhere((e) => e.id == entry.id);
        withQueued.add(entry);
      }
      await _localCache.savePendingQueue(_sortDesc(withQueued));
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
      from: from,
      to: to,
    );
    return _sortDesc(remote);
  }

  Future<bool> _isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
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
}
