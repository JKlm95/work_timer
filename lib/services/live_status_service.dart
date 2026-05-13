import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../bloc/timer_cubit.dart';
import '../models/billing_currency.dart';
import '../models/live_status.dart';
import '../models/workspace.dart';
import 'live_status_app_binding.dart';

/// `users/{uid}/live/status` — podgląd online / timera dla panelu pracodawcy.
class LiveStatusService {
  LiveStatusService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const docId = 'status';

  DocumentReference<Map<String, dynamic>> _ref(String uid) {
    return _db.collection('users').doc(uid).collection('live').doc(docId);
  }

  bool _isForeground() {
    return LiveStatusAppBinding.lifecycle == AppLifecycleState.resumed;
  }

  bool _computeIsOnline(TimerState state) {
    if (state.runState != TimerRunState.idle) return true;
    return _isForeground();
  }

  Map<String, dynamic> _workspaceFields(Workspace w) {
    return {
      'activeWorkspaceId': w.id,
      'activeCompanySlug': w.companySlug ?? '',
      'activeWorkspaceName': w.name,
    };
  }

  Map<String, dynamic> _billingFields(Workspace w) {
    final rate = w.hourlyRate;
    final code = BillingCurrency.normalizeOrNull(w.currencyCode);
    return {
      if (rate != null && rate > 0)
        'hourlyRate': rate
      else
        'hourlyRate': FieldValue.delete(),
      if (code != null) 'currency': code else 'currency': FieldValue.delete(),
    };
  }

  String _timerStateString(TimerRunState rs) {
    switch (rs) {
      case TimerRunState.idle:
        return LiveTimerState.idle;
      case TimerRunState.running:
        return LiveTimerState.running;
      case TimerRunState.paused:
        return LiveTimerState.paused;
    }
  }

  /// Pełny zapis po stanie timera / workspace / lifecycle.
  Future<void> syncFromTimerState(TimerState state) async {
    final uid = state.uid;
    final now = DateTime.now();
    final w = state.activeWorkspace;
    final online = _computeIsOnline(state);
    final timerStr = _timerStateString(state.runState);

    final data = <String, dynamic>{
      'uid': uid,
      'isOnline': online,
      'timerState': timerStr,
      ..._workspaceFields(w),
      'billingRatePercent': 100,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      ..._billingFields(w),
    };

    if (state.runState == TimerRunState.idle) {
      data['accumulatedSecondsBeforePause'] = 0;
      data['sessionStartedAt'] = FieldValue.delete();
      data['sessionPausedAt'] = FieldValue.delete();
    } else if (state.runState == TimerRunState.paused) {
      data['accumulatedSecondsBeforePause'] = state.accumulated.inSeconds;
      data['sessionStartedAt'] = FieldValue.delete();
      data['sessionPausedAt'] = Timestamp.fromDate(now);
    } else {
      data['accumulatedSecondsBeforePause'] = state.accumulated.inSeconds;
      final ra = state.resumeAt;
      if (ra != null) {
        data['sessionStartedAt'] = Timestamp.fromDate(ra);
      } else {
        data['sessionStartedAt'] = FieldValue.delete();
      }
      data['sessionPausedAt'] = FieldValue.delete();
    }

    if (kDebugMode) {
      final sessionStartDesc = state.resumeAt?.toIso8601String() ?? 'null';
      debugPrint(
        '[LiveStatus] syncFromTimerState uid=$uid timerState=$timerStr '
        'isOnline=$online runState=${state.runState.name} '
        'accumulatedSec=${state.accumulated.inSeconds} resumeAt=$sessionStartDesc '
        'workspace=${w.id} lifecycle=${LiveStatusAppBinding.lifecycle.name}',
      );
      debugPrint(
        '[LiveStatus] firestore payload keys: ${data.keys.toList()} '
        '(serverTimestamp on lastSeenAt/updatedAt)',
      );
    }

    try {
      await _ref(uid).set(data, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('LiveStatusService.syncFromTimerState: $e\n$st');
    }
  }

  /// Krótko po zalogowaniu (zanim TimerCubit ustawi workspace).
  Future<void> markSignedIn(String uid) async {
    try {
      await _ref(uid).set({
        'uid': uid,
        'isOnline': true,
        'timerState': LiveTimerState.idle,
        'activeWorkspaceId': '',
        'activeCompanySlug': '',
        'activeWorkspaceName': '',
        'accumulatedSecondsBeforePause': 0,
        'billingRatePercent': 100,
        'hourlyRate': FieldValue.delete(),
        'currency': FieldValue.delete(),
        'sessionStartedAt': FieldValue.delete(),
        'sessionPausedAt': FieldValue.delete(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('LiveStatusService.markSignedIn: $e\n$st');
    }
  }

  /// Przed wylogowaniem — `await` z AuthCubit.
  Future<void> markSignedOut(String uid) async {
    try {
      await _ref(uid).set({
        'uid': uid,
        'isOnline': false,
        'timerState': LiveTimerState.idle,
        'activeWorkspaceId': '',
        'activeCompanySlug': '',
        'activeWorkspaceName': '',
        'accumulatedSecondsBeforePause': 0,
        'billingRatePercent': 100,
        'hourlyRate': FieldValue.delete(),
        'currency': FieldValue.delete(),
        'sessionStartedAt': FieldValue.delete(),
        'sessionPausedAt': FieldValue.delete(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('LiveStatusService.markSignedOut: $e\n$st');
    }
  }

  /// Heartbeat: tylko znaczniki czasu (merge).
  Future<void> heartbeat(String uid) async {
    try {
      await _ref(uid).set({
        'lastSeenAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, st) {
      debugPrint('LiveStatusService.heartbeat: $e\n$st');
    }
  }
}
