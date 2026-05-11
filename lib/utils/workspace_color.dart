import 'package:flutter/material.dart';

/// Kolor akcentu projektu z pola [Workspace.colorHex]; niepoprawny lub pusty → [fallback].
Color workspaceAccentColor(String? colorHex, Color fallback) {
  if (colorHex == null) return fallback;
  var s = colorHex.trim();
  if (s.isEmpty) return fallback;
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 6) {
    final v = int.tryParse(s, radix: 16);
    if (v != null) return Color(0xFF000000 | v);
  }
  if (s.length == 8) {
    final v = int.tryParse(s, radix: 16);
    if (v != null) return Color(v);
  }
  return fallback;
}
