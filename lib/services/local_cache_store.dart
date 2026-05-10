import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/work_entry.dart';
import '../models/work_mode.dart';
import '../models/workspace.dart';

const _legacyEntriesKey = 'work_entries_v1';
const _currentMonthCacheKey = 'work_entries_current_month_v2';
const _pendingQueueKey = 'work_entries_pending_v2';
const _workspacesKey = 'workspaces_v1';
const _activeWorkspaceKey = 'active_workspace_v1';
const _timerSessionKey = 'timer_session_v1';

class LocalTimerSession {
  const LocalTimerSession({
    required this.runState,
    required this.workspaceId,
    required this.sessionMode,
    required this.sessionStart,
    required this.accumulatedMs,
    required this.resumeAt,
  });

  final String runState;
  final String workspaceId;
  final String sessionMode;
  final DateTime sessionStart;
  final int accumulatedMs;
  final DateTime? resumeAt;

  Map<String, dynamic> toJson() => {
    'runState': runState,
    'workspaceId': workspaceId,
    'sessionMode': sessionMode,
    'sessionStart': sessionStart.toIso8601String(),
    'accumulatedMs': accumulatedMs,
    'resumeAt': resumeAt?.toIso8601String(),
  };

  factory LocalTimerSession.fromJson(Map<String, dynamic> json) {
    return LocalTimerSession(
      runState: json['runState'] as String? ?? 'idle',
      workspaceId: json['workspaceId'] as String? ?? Workspace.defaultId,
      sessionMode: json['sessionMode'] as String? ?? WorkMode.office.name,
      sessionStart: DateTime.parse(
        json['sessionStart'] as String? ?? DateTime.now().toIso8601String(),
      ),
      accumulatedMs: (json['accumulatedMs'] as num?)?.toInt() ?? 0,
      resumeAt: (json['resumeAt'] as String?) == null
          ? null
          : DateTime.parse(json['resumeAt'] as String),
    );
  }
}

class LocalCacheStore {
  /// Native (foreground service / Kotlin) can update `FlutterSharedPreferences`
  /// directly; Flutter keeps an in‑memory cache unless we reload first.
  Future<void> reloadPreferencesFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
  }

  Future<List<WorkEntry>> loadCurrentMonthCache(String workspaceId) async {
    return _loadFromKey(_workspaceKey(_currentMonthCacheKey, workspaceId));
  }

  Future<void> saveCurrentMonthCache(
    String workspaceId,
    List<WorkEntry> entries,
  ) async {
    await _saveToKey(
      _workspaceKey(_currentMonthCacheKey, workspaceId),
      entries,
    );
  }

  Future<List<WorkEntry>> loadPendingQueue(String workspaceId) async {
    return _loadFromKey(_workspaceKey(_pendingQueueKey, workspaceId));
  }

  Future<void> savePendingQueue(
    String workspaceId,
    List<WorkEntry> entries,
  ) async {
    await _saveToKey(_workspaceKey(_pendingQueueKey, workspaceId), entries);
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

  Future<List<Workspace>> loadWorkspaces() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_workspacesKey);
    if (raw == null || raw.isEmpty) {
      return [Workspace.defaultWorkspace()];
    }
    final list = jsonDecode(raw) as List<dynamic>;
    final parsed = list
        .map((e) => Workspace.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((w) => !w.isArchived)
        .toList();
    if (parsed.isEmpty) {
      return [Workspace.defaultWorkspace()];
    }
    return parsed;
  }

  Future<void> saveWorkspaces(List<Workspace> workspaces) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(workspaces.map((w) => w.toJson()).toList());
    await prefs.setString(_workspacesKey, raw);
  }

  Future<String?> loadActiveWorkspaceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeWorkspaceKey);
  }

  Future<void> saveActiveWorkspaceId(String workspaceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeWorkspaceKey, workspaceId);
  }

  Future<void> saveTimerSession(LocalTimerSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timerSessionKey, jsonEncode(session.toJson()));
  }

  Future<LocalTimerSession?> loadTimerSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_timerSessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return LocalTimerSession.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearTimerSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timerSessionKey);
  }

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

  String _workspaceKey(String base, String workspaceId) =>
      '${base}_$workspaceId';
}
