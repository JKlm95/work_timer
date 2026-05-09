import 'package:flutter/material.dart';

/// Paleta kolorów aplikacji Work Timer.
///
/// Źródło prawdy dla odcieni marki, powierzchni i splashu.
/// Kolory semantyczne Material 3 (np. [ColorScheme.error]) nadal pochodzą z [ThemeData.colorScheme]
/// generowanego z [brandPrimary], chyba że jawnie użyjesz stałej z tego pliku.
abstract final class AppColors {
  AppColors._();

  // --- Marka ---
  /// Główny niebieski (seed motywu, przyciski, akcent focusu).
  static const Color brandPrimary = Color(0xFF0D47A1);

  /// Wskaźnik zaznaczenia w [NavigationBar] (~10% brandPrimary).
  static const Color brandNavIndicator = Color(0x1A0D47A1);

  // --- Powierzchnie i obramowania ---
  static const Color surfaceApp = Color(0xFFF5F6F8);

  /// Karty, pola formularzy (tło wypełnienia).
  static const Color surfaceCard = Color(0xFFFFFFFF);

  /// Delikatna ramka inputów w stanie spoczynku.
  static const Color borderInputIdle = Color(0xFFE3E7EE);

  // --- Splash (gradient + warstwy na ciemnym tle) ---
  /// Narożnik gradientu splash — najciemniejszy.
  static const Color splashDeepNavy = Color(0xFF062454);

  /// Ten sam odcień co [brandPrimary] w środku gradientu.
  static const Color splashCore = brandPrimary;

  static const Color splashBrightBlue = Color(0xFF1976D2);

  static const Color splashPaleEnd = Color(0xFFE8ECF2);

  // --- Monochromatyczne pomocnicze ---
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  /// Półprzezroczyste biel na gradientcie splash (dekoracje).
  static Color get splashHaloStrong => white.withValues(alpha: 0.06);

  static Color get splashHaloSoft => white.withValues(alpha: 0.05);

  static Color get splashGlassCircle => white.withValues(alpha: 0.14);

  static Color get splashShadowSoft => black.withValues(alpha: 0.15);

  static Color get splashIconOnGradient => white.withValues(alpha: 0.95);

  static Color get splashSubtitleOnGradient => white.withValues(alpha: 0.82);

  static Color get splashProgressTrack => white.withValues(alpha: 0.2);

  /// Lista kolorów gradientu splash (kolejność = lewy górny → prawy dolny).
  static const List<Color> splashGradientColors = [
    splashDeepNavy,
    splashCore,
    splashBrightBlue,
    splashPaleEnd,
  ];

  static const List<double> splashGradientStops = [0.0, 0.35, 0.72, 1.0];
}
