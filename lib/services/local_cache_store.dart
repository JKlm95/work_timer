import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/work_entry.dart';

const _legacyEntriesKey = 'work_entries_v1';
const _currentMonthCacheKey = 'work_entries_current_month_v2';
const _pendingQueueKey = 'work_entries_pending_v2';

class LocalCacheStore {
  Future<List<WorkEntry>> loadCurrentMonthCache() async {
    return _loadFromKey(_currentMonthCacheKey);
  }

  Future<void> saveCurrentMonthCache(List<WorkEntry> entries) async {
    await _saveToKey(_currentMonthCacheKey, entries);
  }

  Future<List<WorkEntry>> loadPendingQueue() async {
    return _loadFromKey(_pendingQueueKey);
  }

  Future<void> savePendingQueue(List<WorkEntry> entries) async {
    await _saveToKey(_pendingQueueKey, entries);
  }

  Future<List<WorkEntry>> loadLegacyEntries() async {
    return _loadFromKey(_legacyEntriesKey);
  }

  Future<bool> isMigrationDone(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migrationKey(uid)) ?? false;
  }

  Future<void> markMigrationDone(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationKey(uid), true);
  }

  String _migrationKey(String uid) => 'migration_done_v1_$uid';

  Future<List<WorkEntry>> _loadFromKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => WorkEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _saveToKey(String key, List<WorkEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(key, raw);
  }
}
