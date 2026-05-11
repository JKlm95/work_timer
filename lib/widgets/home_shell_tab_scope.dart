import 'package:flutter/material.dart';

/// Przekazuje przełączenie zakładki z głównej powłoki (Timer, Historia, …).
class HomeShellTabScope extends InheritedWidget {
  const HomeShellTabScope({
    super.key,
    required this.goToTab,
    required super.child,
  });

  final ValueChanged<int> goToTab;

  /// Nawigacja pod przyciski nad/pod scaffold — znalezisko przodka bez zmiany scope subtree buildów childów.
  static HomeShellTabScope? maybeOf(BuildContext context) {
    return context.findAncestorWidgetOfExactType<HomeShellTabScope>();
  }

  @override
  bool updateShouldNotify(HomeShellTabScope oldWidget) =>
      goToTab != oldWidget.goToTab;
}
