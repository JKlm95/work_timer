import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Obsługa `worktimer://...` z iOS (widget / AppDelegate). Zmienia zakładkę w [HomeShell].
class IosDeepLinkNav {
  IosDeepLinkNav._();
  static final IosDeepLinkNav instance = IosDeepLinkNav._();

  final ValueNotifier<int?> pendingTabIndex = ValueNotifier<int?>(null);

  static const MethodChannel _channel = MethodChannel('work_timer/deeplink');

  bool _inited = false;

  void init() {
    if (!Platform.isIOS || _inited) return;
    _inited = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onOpenUrl') {
        _handleUrl(call.arguments as String?);
      }
    });
  }

  void _handleUrl(String? raw) {
    if (raw == null || raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    if (uri.scheme != 'worktimer') return;

    final host = uri.host;
    final path = uri.pathSegments;

    if (host == 'workspaces' || path.contains('workspaces')) {
      pendingTabIndex.value = 3;
      return;
    }
    if (host == 'open' || host.isEmpty) {
      pendingTabIndex.value = 0;
    }
  }
}
