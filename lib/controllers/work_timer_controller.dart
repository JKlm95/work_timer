import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/work_entry.dart';
import '../models/work_mode.dart';
import '../services/work_storage.dart';

enum TimerRunState { idle, running, paused }

class WorkTimerController extends ChangeNotifier {
  WorkTimerController(this._storage);

  final WorkStorage _storage;

  WorkMode _nextSessionMode = WorkMode.office;
  WorkMode get nextSessionMode => _nextSessionMode;

  TimerRunState _runState = TimerRunState.idle;
  TimerRunState get runState => _runState;

  DateTime? _sessionStart;
  WorkMode? _sessionMode;
  Duration _accumulated = Duration.zero;
  DateTime? _resumeAt;

  List<WorkEntry> _entries = [];
  List<WorkEntry> get entries => List.unmodifiable(_entries);

  Timer? _tick;

  bool get canChangeMode =>
      _runState == TimerRunState.idle;

  Duration get elapsed {
    if (_runState == TimerRunState.running && _resumeAt != null) {
      return _accumulated + DateTime.now().difference(_resumeAt!);
    }
    return _accumulated;
  }

  Future<void> init() async {
    _entries = await _storage.loadEntries();
    _entries.sort((a, b) => b.start.compareTo(a.start));
    notifyListeners();
  }

  void setNextMode(WorkMode mode) {
    if (!canChangeMode) return;
    _nextSessionMode = mode;
    notifyListeners();
  }

  void play() {
    if (_runState == TimerRunState.running) return;
    if (_runState == TimerRunState.idle) {
      _sessionMode = _nextSessionMode;
      _sessionStart = DateTime.now();
      _accumulated = Duration.zero;
      _resumeAt = DateTime.now();
      _runState = TimerRunState.running;
    } else if (_runState == TimerRunState.paused) {
      _resumeAt = DateTime.now();
      _runState = TimerRunState.running;
    }
    _startTick();
    notifyListeners();
  }

  void pause() {
    if (_runState != TimerRunState.running || _resumeAt == null) return;
    _accumulated += DateTime.now().difference(_resumeAt!);
    _resumeAt = null;
    _runState = TimerRunState.paused;
    _stopTick();
    notifyListeners();
  }

  Future<void> stop() async {
    if (_runState == TimerRunState.idle) return;

    Duration total = _accumulated;
    if (_runState == TimerRunState.running && _resumeAt != null) {
      total += DateTime.now().difference(_resumeAt!);
    }

    _stopTick();
    final start = _sessionStart ?? DateTime.now();
    final end = start.add(total);

    if (total > Duration.zero) {
      final mode = _sessionMode ?? _nextSessionMode;
      final entry = WorkEntry(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        start: start,
        end: end,
        mode: mode,
      );
      _entries = [entry, ..._entries];
      _entries.sort((a, b) => b.start.compareTo(a.start));
      await _storage.saveEntries(_entries);
    }

    _sessionStart = null;
    _sessionMode = null;
    _accumulated = Duration.zero;
    _resumeAt = null;
    _runState = TimerRunState.idle;
    notifyListeners();
  }

  void _startTick() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      notifyListeners();
    });
  }

  void _stopTick() {
    _tick?.cancel();
    _tick = null;
  }

  @override
  void dispose() {
    _stopTick();
    super.dispose();
  }
}
