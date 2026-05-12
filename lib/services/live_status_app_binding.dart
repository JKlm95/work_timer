import 'package:flutter/widgets.dart';

/// Ostatni znany stan lifecycle — używany przy wyliczaniu `isOnline` w [LiveStatusService].
class LiveStatusAppBinding {
  LiveStatusAppBinding._();

  static AppLifecycleState lifecycle = AppLifecycleState.resumed;
}
