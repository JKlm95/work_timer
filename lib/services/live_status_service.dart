import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../bloc/timer_cubit.dart';
import '../models/workspace.dart';
import 'live_status_app_binding.dart';
import 'live_status_sync_plan.dart';

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

  Map<String, dynamic> _workspaceFields(Workspace w) {
    return {
      'activeWorkspaceId': w.id,
      'activeCompanySlug': w.companySlug ?? '',
      'activeWorkspaceName': w.name,
    };
  }

  Map<String, dynamic> _billingFieldsMap(LiveBillingFieldPlan plan) {
    return {
      if (plan.shouldDeleteHourly)
        'hourlyRate': FieldValue.delete()
      else
        'hourlyRate': plan.hourlyRate,
      if (plan.shouldDeleteCurrency)
        'currency': FieldValue.delete()
      else
        'currency': plan.currency,
    };
  }

  /// Pełny zapis po stanie timera / workspace / lifecycle.
  Future<void> syncFromTimerState(TimerState state) async {
    final uid = state.uid;
    final now = DateTime.now();
    final w = state.activeWorkspace;
    final online = liveStatusIsOnlineForPanel(
      runState: state.runState,
      appIsForeground: _isForeground(),
    );
    final timerStr = liveTimerStateForFirestore(state.runState);
    final sessionPlan = LiveSessionFieldPlan.fromTimer(
      runState: state.runState,
      accumulated: state.accumulated,
      resumeAt: state.resumeAt,
      now: now,
    );
    final billingPlan = LiveBillingFieldPlan.fromWorkspace(w);

    final data = <String, dynamic>{
      'uid': uid,
      'isOnline': online,
      'timerState': timerStr,
      ..._workspaceFields(w),
      'billingRatePercent': 100,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      ..._billingFieldsMap(billingPlan),
    };

    data['accumulatedSecondsBeforePause'] =
        sessionPlan.accumulatedSecondsBeforePause;
    if (sessionPlan.sessionStartedDelete) {
      data['sessionStartedAt'] = FieldValue.delete();
    } else {
      data['sessionStartedAt'] = Timestamp.fromDate(
        sessionPlan.sessionStartedAt!,
      );
    }
    if (sessionPlan.sessionPausedDelete) {
      data['sessionPausedAt'] = FieldValue.delete();
    } else {
      data['sessionPausedAt'] = Timestamp.fromDate(
        sessionPlan.sessionPausedAt!,
      );
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
        'timerState': liveTimerStateForFirestore(TimerRunState.idle),
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
        'timerState': liveTimerStateForFirestore(TimerRunState.idle),
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
