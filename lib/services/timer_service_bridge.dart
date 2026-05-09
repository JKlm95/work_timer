import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TimerServiceBridge {
  static const MethodChannel _channel = MethodChannel(
    'work_timer/service_control',
  );

  static Future<void> play({
    required String workspaceId,
    required String workspaceName,
    required String nextSessionMode,
  }) async {
    if (!Platform.isAndroid) return;
    debugPrint(
      '[TimerServiceBridge] play workspace=$workspaceId mode=$nextSessionMode',
    );
    await _channel.invokeMethod('play', {
      'workspaceId': workspaceId,
      'workspaceName': workspaceName,
      'nextSessionMode': nextSessionMode,
    });
  }

  static Future<void> pause() async {
    if (!Platform.isAndroid) return;
    debugPrint('[TimerServiceBridge] pause');
    await _channel.invokeMethod('pause');
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    debugPrint('[TimerServiceBridge] stop');
    await _channel.invokeMethod('stop');
  }

  static Future<void> sync({
    required String runState,
    required int elapsedSeconds,
    required String workspaceId,
    required String workspaceName,
    required String nextSessionMode,
  }) async {
    if (!Platform.isAndroid) return;
    debugPrint(
      '[TimerServiceBridge] sync state=$runState elapsed=${elapsedSeconds}s workspace=$workspaceId',
    );
    await _channel.invokeMethod('sync', {
      'runState': runState,
      'elapsedSeconds': elapsedSeconds,
      'workspaceId': workspaceId,
      'workspaceName': workspaceName,
      'nextSessionMode': nextSessionMode,
    });
  }

  /// Ostatni stan z JVM (persistAndRender) — pewniejsze niż sam reload SharedPreferences.
  static Future<Map<String, Object?>?> getNativeTimerSnapshot() async {
    if (!Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMethod<Object?>('getNativeTimerSnapshot');
      if (raw is Map) {
        return Map<String, Object?>.from(
          raw.map((k, v) => MapEntry(k.toString(), v)),
        );
      }
    } catch (e) {
      debugPrint('[TimerServiceBridge] getNativeTimerSnapshot failed: $e');
    }
    return null;
  }
}
