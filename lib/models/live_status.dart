/// Wartości `timerState` w `users/{uid}/live/status` (panel pracodawcy).
abstract final class LiveTimerState {
  static const idle = 'idle';
  static const running = 'running';
  static const paused = 'paused';
}
