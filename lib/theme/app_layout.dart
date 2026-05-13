import 'package:flutter/material.dart';

/// Wspólne stałe layoutu (radius, odstępy, cele dotykowe) — spójność ekranów bez redesignu motywu.
abstract final class AppLayout {
  AppLayout._();

  static const double radiusLg = 20;
  static const double radiusMd = 16;
  static const double radiusSm = 12;

  static const EdgeInsets screenPaddingH = EdgeInsets.symmetric(horizontal: 16);

  static const double minTouchTarget = 48;
  static const double primaryButtonHeight = 56;
  static const double secondaryButtonHeight = 48;
}
