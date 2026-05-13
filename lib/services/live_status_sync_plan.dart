import '../bloc/timer_cubit.dart';
import '../models/billing_currency.dart';
import '../models/live_status.dart';
import '../models/workspace.dart';

/// Wartość `timerState` w Firestore — spójna z [LiveTimerState].
String liveTimerStateForFirestore(TimerRunState runState) {
  switch (runState) {
    case TimerRunState.idle:
      return LiveTimerState.idle;
    case TimerRunState.running:
      return LiveTimerState.running;
    case TimerRunState.paused:
      return LiveTimerState.paused;
  }
}

/// Pola sesji w `users/{uid}/live/status` (bez `FieldValue` — mapowanie w [LiveStatusService]).
final class LiveSessionFieldPlan {
  const LiveSessionFieldPlan({
    required this.accumulatedSecondsBeforePause,
    required this.sessionStartedDelete,
    this.sessionStartedAt,
    required this.sessionPausedDelete,
    this.sessionPausedAt,
  });

  final int accumulatedSecondsBeforePause;
  final bool sessionStartedDelete;
  final DateTime? sessionStartedAt;
  final bool sessionPausedDelete;
  final DateTime? sessionPausedAt;

  static LiveSessionFieldPlan fromTimer({
    required TimerRunState runState,
    required Duration accumulated,
    required DateTime? resumeAt,
    required DateTime now,
  }) {
    if (runState == TimerRunState.idle) {
      return const LiveSessionFieldPlan(
        accumulatedSecondsBeforePause: 0,
        sessionStartedDelete: true,
        sessionPausedDelete: true,
      );
    }
    if (runState == TimerRunState.paused) {
      return LiveSessionFieldPlan(
        accumulatedSecondsBeforePause: accumulated.inSeconds,
        sessionStartedDelete: true,
        sessionPausedDelete: false,
        sessionPausedAt: now,
      );
    }
    final ra = resumeAt;
    return LiveSessionFieldPlan(
      accumulatedSecondsBeforePause: accumulated.inSeconds,
      sessionStartedDelete: ra == null,
      sessionStartedAt: ra,
      sessionPausedDelete: true,
    );
  }
}

/// Stawka i waluta dla live statusu: `null` oznacza usunięcie pola w Firestore (brak stawki).
final class LiveBillingFieldPlan {
  const LiveBillingFieldPlan({this.hourlyRate, this.currency});

  final double? hourlyRate;
  final String? currency;

  static LiveBillingFieldPlan fromWorkspace(Workspace w) {
    final rate = w.hourlyRate;
    final code = BillingCurrency.normalizeOrNull(w.currencyCode);
    if (rate != null && rate > 0) {
      return LiveBillingFieldPlan(hourlyRate: rate, currency: code);
    }
    return LiveBillingFieldPlan(hourlyRate: null, currency: code);
  }

  bool get shouldDeleteHourly => hourlyRate == null;
  bool get shouldDeleteCurrency => currency == null;
}

bool liveStatusIsOnlineForPanel({
  required TimerRunState runState,
  required bool appIsForeground,
}) {
  if (runState != TimerRunState.idle) return true;
  return appIsForeground;
}
