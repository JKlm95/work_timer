import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform-safe bridge: Android → ForegroundService/Kotlin; iOS → App Group + WidgetKit reload.
/// Kanał `work_timer/service_control` obsługiwany w `MainActivity` (Android) i `AppDelegate` (iOS).
class TimerServiceBridge {
  TimerServiceBridge._();

  static const MethodChannel _channel = MethodChannel(
    'work_timer/service_control',
  );

  static Future<void> play({
    required String workspaceId,
    required String workspaceName,
    required String nextSessionMode,
  }) async {
    if (Platform.isAndroid) {
      debugPrint(
        '[TimerServiceBridge] play workspace=$workspaceId mode=$nextSessionMode',
      );
      await _channel.invokeMethod('play', {
        'workspaceId': workspaceId,
        'workspaceName': workspaceName,
        'nextSessionMode': nextSessionMode,
      });
      return;
    }
    if (Platform.isIOS) {
      await _channel.invokeMethod<void>('play', {
        'workspaceId': workspaceId,
        'workspaceName': workspaceName,
        'nextSessionMode': nextSessionMode,
      });
    }
  }

  static Future<void> pause() async {
    if (Platform.isAndroid) {
      debugPrint('[TimerServiceBridge] pause');
      await _channel.invokeMethod('pause');
      return;
    }
    if (Platform.isIOS) {
      await _channel.invokeMethod<void>('pause');
    }
  }

  static Future<void> stop() async {
    if (Platform.isAndroid) {
      debugPrint('[TimerServiceBridge] stop');
      await _channel.invokeMethod('stop');
      return;
    }
    if (Platform.isIOS) {
      await _channel.invokeMethod<void>('stop');
    }
  }

  /// Synchronizacja stanu widgetu / lustra dla hydratacji. Na iOS zapisuje App Group (UserDefaults).
  static Future<void> sync({
    required String runState,
    required int elapsedSeconds,
    required String workspaceId,
    required String workspaceName,
    required String nextSessionMode,
    int? sessionStartMs,
    int? resumeAtMs,
    int? pausedAccumulatedSeconds,
  }) async {
    final payload = <String, dynamic>{
      'runState': runState,
      'elapsedSeconds': elapsedSeconds,
      'workspaceId': workspaceId,
      'workspaceName': workspaceName,
      'nextSessionMode': nextSessionMode,
    };
    if (sessionStartMs != null) {
      payload['sessionStartMs'] = sessionStartMs;
    }
    if (resumeAtMs != null) {
      payload['resumeAtMs'] = resumeAtMs;
    }
    if (pausedAccumulatedSeconds != null) {
      payload['pausedAccumulatedSeconds'] = pausedAccumulatedSeconds;
    }

    if (Platform.isAndroid) {
      debugPrint(
        '[TimerServiceBridge] sync state=$runState elapsed=${elapsedSeconds}s workspace=$workspaceId',
      );
      await _channel.invokeMethod('sync', payload);
      return;
    }
    if (Platform.isIOS) {
      debugPrint(
        '[TimerServiceBridge] iOS sync state=$runState elapsed=${elapsedSeconds}s workspace=$workspaceId',
      );
      await _channel.invokeMethod<void>('sync', payload);
    }
  }

  static Future<void> syncWidgetWorkspaces({
    required String workspacesJson,
    required String selectedWorkspaceId,
  }) async {
    if (Platform.isAndroid) {
      await _channel
          .invokeMethod<void>('syncWidgetWorkspaces', <String, dynamic>{
            'workspacesJson': workspacesJson,
            'selectedWorkspaceId': selectedWorkspaceId,
          });
      return;
    }
    if (Platform.isIOS) {
      await _channel
          .invokeMethod<void>('syncWidgetWorkspaces', <String, dynamic>{
            'workspacesJson': workspacesJson,
            'selectedWorkspaceId': selectedWorkspaceId,
          });
    }
  }

  static Future<Map<String, Object?>?> getWidgetWorkspaceSelection() async {
    if (Platform.isAndroid) {
      try {
        final raw = await _channel.invokeMethod<Object?>(
          'getWidgetWorkspaceSelection',
        );
        if (raw is Map) {
          return Map<String, Object?>.from(
            raw.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      } catch (e) {
        debugPrint(
          '[TimerServiceBridge] getWidgetWorkspaceSelection failed: $e',
        );
      }
      return null;
    }
    if (Platform.isIOS) {
      try {
        final raw = await _channel.invokeMethod<Object?>(
          'getWidgetWorkspaceSelection',
        );
        if (raw is Map) {
          return Map<String, Object?>.from(
            raw.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      } catch (e) {
        debugPrint(
          '[TimerServiceBridge] iOS getWidgetWorkspaceSelection failed: $e',
        );
      }
    }
    return null;
  }

  static Future<Map<String, Object?>?> getNativeTimerSnapshot() async {
    if (Platform.isAndroid) {
      try {
        final raw = await _channel.invokeMethod<Object?>(
          'getNativeTimerSnapshot',
        );
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
    if (Platform.isIOS) {
      try {
        final raw = await _channel.invokeMethod<Object?>(
          'getNativeTimerSnapshot',
        );
        if (raw is Map) {
          return Map<String, Object?>.from(
            raw.map((k, v) => MapEntry(k.toString(), v)),
          );
        }
      } catch (e) {
        debugPrint(
          '[TimerServiceBridge] iOS getNativeTimerSnapshot failed: $e',
        );
      }
    }
    return null;
  }

  /// Po zmianie flagi zalogowania — odświeżenie widgetu iOS (bez Android home_widget name).
  static Future<void> reloadHomeWidgets() async {
    if (Platform.isIOS) {
      try {
        await _channel.invokeMethod<void>('reloadWidgets');
      } catch (e) {
        debugPrint('[TimerServiceBridge] reloadWidgets failed: $e');
      }
    }
  }
}
