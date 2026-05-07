import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';
import 'package:uuid/uuid.dart';

import '../models/work_entry.dart';
import '../models/work_mode.dart';
import '../models/workspace.dart';
import '../services/work_repository.dart';

enum TimerRunState { idle, running, paused }

class TimerState {
  const TimerState({
    required this.uid,
    required this.nextSessionMode,
    required this.runState,
    required this.elapsed,
    required this.entries,
    required this.currentMonthEntries,
    required this.historyOfflineFallback,
    required this.historyLoading,
    required this.sessionStart,
    required this.sessionMode,
    required this.accumulated,
    required this.resumeAt,
    required this.workspaces,
    required this.activeWorkspaceId,
    required this.statsEntries,
  });

  final String uid;
  final WorkMode nextSessionMode;
  final TimerRunState runState;
  final Duration elapsed;
  final List<WorkEntry> entries;
  final List<WorkEntry> currentMonthEntries;
  final bool historyOfflineFallback;
  final bool historyLoading;
  final DateTime? sessionStart;
  final WorkMode? sessionMode;
  final Duration accumulated;
  final DateTime? resumeAt;
  final List<Workspace> workspaces;
  final String activeWorkspaceId;
  final List<WorkEntry> statsEntries;

  bool get canChangeMode => runState == TimerRunState.idle;
  Workspace get activeWorkspace {
    return workspaces.firstWhere(
      (w) => w.id == activeWorkspaceId,
      orElse: Workspace.defaultWorkspace,
    );
  }

  factory TimerState.initial(String uid) => TimerState(
    uid: uid,
    nextSessionMode: WorkMode.office,
    runState: TimerRunState.idle,
    elapsed: Duration.zero,
    entries: const [],
    currentMonthEntries: const [],
    historyOfflineFallback: false,
    historyLoading: false,
    sessionStart: null,
    sessionMode: null,
    accumulated: Duration.zero,
    resumeAt: null,
    workspaces: const [],
    activeWorkspaceId: Workspace.defaultId,
    statsEntries: const [],
  );

  TimerState copyWith({
    WorkMode? nextSessionMode,
    TimerRunState? runState,
    Duration? elapsed,
    List<WorkEntry>? entries,
    List<WorkEntry>? currentMonthEntries,
    bool? historyOfflineFallback,
    bool? historyLoading,
    DateTime? sessionStart,
    bool clearSessionStart = false,
    WorkMode? sessionMode,
    bool clearSessionMode = false,
    Duration? accumulated,
    DateTime? resumeAt,
    bool clearResumeAt = false,
    List<Workspace>? workspaces,
    String? activeWorkspaceId,
    List<WorkEntry>? statsEntries,
  }) {
    return TimerState(
      uid: uid,
      nextSessionMode: nextSessionMode ?? this.nextSessionMode,
      runState: runState ?? this.runState,
      elapsed: elapsed ?? this.elapsed,
      entries: entries ?? this.entries,
      currentMonthEntries: currentMonthEntries ?? this.currentMonthEntries,
      historyOfflineFallback:
          historyOfflineFallback ?? this.historyOfflineFallback,
      historyLoading: historyLoading ?? this.historyLoading,
      sessionStart: clearSessionStart
          ? null
          : (sessionStart ?? this.sessionStart),
      sessionMode: clearSessionMode ? null : (sessionMode ?? this.sessionMode),
      accumulated: accumulated ?? this.accumulated,
      resumeAt: clearResumeAt ? null : (resumeAt ?? this.resumeAt),
      workspaces: workspaces ?? this.workspaces,
      activeWorkspaceId: activeWorkspaceId ?? this.activeWorkspaceId,
      statsEntries: statsEntries ?? this.statsEntries,
    );
  }
}

class TimerCubit extends Cubit<TimerState> {
  TimerCubit({required String uid, required WorkRepository repository})
    : _repository = repository,
      super(TimerState.initial(uid));

  final WorkRepository _repository;
  final Uuid _uuid = const Uuid();
  Timer? _tick;

  Future<void> init() async {
    await _repository.initForUser(state.uid);
    final workspaces = _repository.workspaces;
    final activeWorkspaceId = _repository.activeWorkspaceId;
    final now = DateTime.now();
    final currentRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    final result = await _repository.loadEntriesForRange(currentRange);
    emit(
      state.copyWith(
        entries: result.entries,
        currentMonthEntries: result.entries,
        historyOfflineFallback: result.offlineFallback,
        workspaces: workspaces,
        activeWorkspaceId: activeWorkspaceId,
      ),
    );
    await refreshStatsEntries();
    await _writeWidgetSnapshot();
  }

  Future<void> setActiveWorkspace(String workspaceId) async {
    await _repository.selectWorkspace(workspaceId);
    emit(state.copyWith(activeWorkspaceId: workspaceId));
    final now = DateTime.now();
    await loadHistory(
      DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    await refreshStatsEntries();
    await _writeWidgetSnapshot();
  }

  Future<void> createWorkspace(String name) async {
    final created = await _repository.createWorkspace(name);
    emit(
      state.copyWith(
        workspaces: _repository.workspaces,
        activeWorkspaceId: created.id,
      ),
    );
    final now = DateTime.now();
    await loadHistory(
      DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    await refreshStatsEntries();
    await _writeWidgetSnapshot();
  }

  Future<void> renameWorkspace({
    required String workspaceId,
    required String name,
  }) async {
    await _repository.renameWorkspace(workspaceId: workspaceId, name: name);
    emit(state.copyWith(workspaces: _repository.workspaces));
    await _writeWidgetSnapshot();
  }

  void setNextMode(WorkMode mode) {
    if (!state.canChangeMode) return;
    emit(state.copyWith(nextSessionMode: mode));
  }

  void play() {
    if (state.runState == TimerRunState.running) return;
    if (state.runState == TimerRunState.idle) {
      final now = DateTime.now();
      emit(
        state.copyWith(
          sessionMode: state.nextSessionMode,
          sessionStart: now,
          accumulated: Duration.zero,
          resumeAt: now,
          runState: TimerRunState.running,
        ),
      );
    } else if (state.runState == TimerRunState.paused) {
      emit(
        state.copyWith(
          resumeAt: DateTime.now(),
          runState: TimerRunState.running,
        ),
      );
    }
    _startTick();
    _emitElapsed();
    _writeWidgetSnapshot();
  }

  void pause() {
    final resumeAt = state.resumeAt;
    if (state.runState != TimerRunState.running || resumeAt == null) return;
    emit(
      state.copyWith(
        accumulated: state.accumulated + DateTime.now().difference(resumeAt),
        clearResumeAt: true,
        runState: TimerRunState.paused,
        elapsed: state.accumulated + DateTime.now().difference(resumeAt),
      ),
    );
    _stopTick();
    _writeWidgetSnapshot();
  }

  Future<void> stop() async {
    if (state.runState == TimerRunState.idle) return;

    Duration total = state.accumulated;
    if (state.runState == TimerRunState.running && state.resumeAt != null) {
      total += DateTime.now().difference(state.resumeAt!);
    }

    _stopTick();
    final start = state.sessionStart ?? DateTime.now();
    final end = start.add(total);

    var entries = state.entries;
    var currentMonthEntries = state.currentMonthEntries;
    if (total > Duration.zero) {
      final mode = state.sessionMode ?? state.nextSessionMode;
      final entry = WorkEntry(
        id: _uuid.v4(),
        workspaceId: state.activeWorkspaceId,
        start: start,
        end: end,
        mode: mode,
        updatedAt: DateTime.now(),
      );
      entries = [entry, ...entries]..sort((a, b) => b.start.compareTo(a.start));
      currentMonthEntries = [entry, ...currentMonthEntries]
        ..sort((a, b) => b.start.compareTo(a.start));
      await _repository.addEntry(entry);
    }

    emit(
      state.copyWith(
        entries: entries,
        currentMonthEntries: currentMonthEntries,
        runState: TimerRunState.idle,
        clearSessionStart: true,
        clearSessionMode: true,
        accumulated: Duration.zero,
        clearResumeAt: true,
        elapsed: Duration.zero,
      ),
    );
    await _writeWidgetSnapshot();
  }

  Future<void> addManualEntry({
    required DateTime start,
    required DateTime end,
    required WorkMode mode,
  }) async {
    if (!end.isAfter(start)) return;
    final entry = WorkEntry(
      id: _uuid.v4(),
      workspaceId: state.activeWorkspaceId,
      start: start,
      end: end,
      mode: mode,
      updatedAt: DateTime.now(),
    );
    await _repository.addEntry(entry);
    await loadHistory(DateTimeRange(start: start, end: end));
    await refreshStatsEntries();
  }

  Future<void> updateEntry({
    required WorkEntry original,
    required DateTime start,
    required DateTime end,
    required WorkMode mode,
  }) async {
    if (!end.isAfter(start)) return;
    final updated = WorkEntry(
      id: original.id,
      workspaceId: original.workspaceId,
      start: start,
      end: end,
      mode: mode,
      updatedAt: DateTime.now(),
      isDeleted: false,
    );
    await _repository.updateEntry(updated);
    await loadHistory(DateTimeRange(start: start, end: end));
    await refreshStatsEntries();
  }

  Future<void> deleteEntry(WorkEntry entry) async {
    await _repository.deleteEntry(entry);
    final now = DateTime.now();
    await loadHistory(
      DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    await refreshStatsEntries();
  }

  Future<void> loadHistory(DateTimeRange range) async {
    emit(state.copyWith(historyLoading: true));
    try {
      final result = await _repository.loadEntriesForRange(range);
      final now = DateTime.now();
      final isCurrentMonth =
          range.start.year == now.year &&
          range.start.month == now.month &&
          range.end.year == now.year &&
          range.end.month == now.month;
      emit(
        state.copyWith(
          entries: result.entries,
          currentMonthEntries: isCurrentMonth
              ? result.entries
              : state.currentMonthEntries,
          historyOfflineFallback: result.offlineFallback,
          historyLoading: false,
        ),
      );
      await _writeWidgetSnapshot();
    } catch (_) {
      emit(state.copyWith(historyLoading: false));
    }
  }

  Future<void> refreshStatsEntries({DateTimeRange? range}) async {
    final now = DateTime.now();
    final selectedRange =
        range ??
        DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
    final entries = await _repository.loadEntriesForWorkspaces(
      range: selectedRange,
      workspaceIds: const {},
    );
    emit(state.copyWith(statsEntries: entries));
  }

  void _emitElapsed() {
    final elapsed = _computeElapsed();
    emit(state.copyWith(elapsed: elapsed));
  }

  Duration _computeElapsed() {
    if (state.runState == TimerRunState.running && state.resumeAt != null) {
      return state.accumulated + DateTime.now().difference(state.resumeAt!);
    }
    return state.accumulated;
  }

  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _emitElapsed();
    });
  }

  void _stopTick() {
    _tick?.cancel();
    _tick = null;
  }

  @override
  Future<void> close() {
    _stopTick();
    return super.close();
  }

  Future<void> _writeWidgetSnapshot() async {
    try {
      await HomeWidget.saveWidgetData<String>(
        'workspaceName',
        state.activeWorkspace.name,
      );
      await HomeWidget.saveWidgetData<String>('runState', state.runState.name);
      await HomeWidget.saveWidgetData<int>('elapsedSeconds', state.elapsed.inSeconds);
      await HomeWidget.updateWidget(
        name: 'WorkTimerWidgetProvider',
        androidName: 'WorkTimerWidgetProvider',
      );
    } catch (_) {}
  }
}
