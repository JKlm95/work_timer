import 'package:flutter_test/flutter_test.dart';
import 'package:work_timer/bloc/timer_cubit.dart';
import 'package:work_timer/models/billing_currency.dart';
import 'package:work_timer/models/live_status.dart';
import 'package:work_timer/models/workspace.dart';
import 'package:work_timer/services/live_status_sync_plan.dart';

void main() {
  group('liveTimerStateForFirestore', () {
    test('mapuje stany timera na stringi panelu', () {
      expect(
        liveTimerStateForFirestore(TimerRunState.idle),
        LiveTimerState.idle,
      );
      expect(
        liveTimerStateForFirestore(TimerRunState.running),
        LiveTimerState.running,
      );
      expect(
        liveTimerStateForFirestore(TimerRunState.paused),
        LiveTimerState.paused,
      );
    });
  });

  group('LiveSessionFieldPlan.fromTimer', () {
    final t0 = DateTime.utc(2026, 5, 10, 12, 0, 0);
    final resume = DateTime.utc(2026, 5, 10, 11, 30, 0);

    test('idle — zeruje akumulator i usuwa oba znaczniki sesji', () {
      final p = LiveSessionFieldPlan.fromTimer(
        runState: TimerRunState.idle,
        accumulated: const Duration(minutes: 42),
        resumeAt: resume,
        now: t0,
      );
      expect(p.accumulatedSecondsBeforePause, 0);
      expect(p.sessionStartedDelete, true);
      expect(p.sessionPausedDelete, true);
    });

    test(
      'paused — suma sekund, brak sessionStarted, sessionPausedAt = now',
      () {
        final p = LiveSessionFieldPlan.fromTimer(
          runState: TimerRunState.paused,
          accumulated: const Duration(seconds: 125),
          resumeAt: null,
          now: t0,
        );
        expect(p.accumulatedSecondsBeforePause, 125);
        expect(p.sessionStartedDelete, true);
        expect(p.sessionPausedDelete, false);
        expect(p.sessionPausedAt, t0);
      },
    );

    test('running z resumeAt — akumulator + sessionStarted', () {
      final p = LiveSessionFieldPlan.fromTimer(
        runState: TimerRunState.running,
        accumulated: const Duration(seconds: 10),
        resumeAt: resume,
        now: t0,
      );
      expect(p.accumulatedSecondsBeforePause, 10);
      expect(p.sessionStartedDelete, false);
      expect(p.sessionStartedAt, resume);
      expect(p.sessionPausedDelete, true);
    });

    test('running bez resumeAt — usuwa sessionStarted (edge)', () {
      final p = LiveSessionFieldPlan.fromTimer(
        runState: TimerRunState.running,
        accumulated: Duration.zero,
        resumeAt: null,
        now: t0,
      );
      expect(p.sessionStartedDelete, true);
      expect(p.sessionPausedDelete, true);
    });
  });

  group('LiveBillingFieldPlan.fromWorkspace', () {
    final now = DateTime.utc(2026, 1, 1);

    test('brak stawki lub 0 — hourlyRate null (delete w Firestore)', () {
      final w0 = Workspace(
        id: '1',
        name: 'A',
        createdAt: now,
        updatedAt: now,
        hourlyRate: null,
        currencyCode: BillingCurrency.defaultCode,
      );
      expect(LiveBillingFieldPlan.fromWorkspace(w0).shouldDeleteHourly, true);

      final wZero = Workspace(
        id: '2',
        name: 'B',
        createdAt: now,
        updatedAt: now,
        hourlyRate: 0,
        currencyCode: 'PLN',
      );
      expect(
        LiveBillingFieldPlan.fromWorkspace(wZero).shouldDeleteHourly,
        true,
      );
    });

    test('dodatnia stawka — hourlyRate ustawione', () {
      final w = Workspace(
        id: '3',
        name: 'C',
        createdAt: now,
        updatedAt: now,
        hourlyRate: 100,
        currencyCode: 'PLN',
      );
      final p = LiveBillingFieldPlan.fromWorkspace(w);
      expect(p.shouldDeleteHourly, false);
      expect(p.hourlyRate, 100);
      expect(p.currency, 'PLN');
      expect(p.shouldDeleteCurrency, false);
    });

    test('nieznana waluta — currency null (delete)', () {
      final w = Workspace(
        id: '4',
        name: 'D',
        createdAt: now,
        updatedAt: now,
        hourlyRate: 50,
        currencyCode: 'bogus',
      );
      final p = LiveBillingFieldPlan.fromWorkspace(w);
      expect(p.shouldDeleteCurrency, true);
    });
  });

  group('liveStatusIsOnlineForPanel', () {
    test('running/paused — zawsze online dla panelu', () {
      expect(
        liveStatusIsOnlineForPanel(
          runState: TimerRunState.running,
          appIsForeground: false,
        ),
        true,
      );
      expect(
        liveStatusIsOnlineForPanel(
          runState: TimerRunState.paused,
          appIsForeground: false,
        ),
        true,
      );
    });

    test('idle — online tylko na pierwszym planie (foreground)', () {
      expect(
        liveStatusIsOnlineForPanel(
          runState: TimerRunState.idle,
          appIsForeground: true,
        ),
        true,
      );
      expect(
        liveStatusIsOnlineForPanel(
          runState: TimerRunState.idle,
          appIsForeground: false,
        ),
        false,
      );
    });
  });
}
