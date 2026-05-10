import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'timer_service_bridge.dart';

/// Klucz w SharedPreferences — po stronie Android w pliku Flutter to
/// `flutter.auth_signed_in_for_native_v1`.
const kAuthSignedInForNativeKey = 'auth_signed_in_for_native_v1';

Future<void> syncAuthSignedInToNativePrefs(bool signedIn) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(kAuthSignedInForNativeKey, signedIn ? '1' : '0');
  if (Platform.isAndroid) {
    await HomeWidget.updateWidget(androidName: 'WorkTimerWidgetProvider');
  } else if (Platform.isIOS) {
    await TimerServiceBridge.reloadHomeWidgets();
  }
}
