import 'package:flutter/material.dart';

/// Domyślne fonty interfejsu.
///
/// Wartość `null` oznacza czcionkę systemową (np. Roboto na Androidzie / San Francisco na iOS
/// w układzie Material 3). Żeby użyć własnego fontu z assets, ustaw tutaj nazwę rodziny
/// i dodaj [FontManifest] / [pubspec.yaml].
abstract final class AppFonts {
  AppFonts._();

  static const String? familyUi = null;

  /// Opcjonalnie: np. `'monospace'` do metadanych technicznych.
  static const String? familyMonospace = null;
}

/// Wagi używane spójnie w UI (sekcje, splash, podkreślenia).
abstract final class AppFontWeights {
  AppFontWeights._();

  static const FontWeight sectionTitle = FontWeight.w600;
  static const FontWeight splashTitle = FontWeight.w700;
  static const FontWeight splashSubtitle = FontWeight.w500;
}

/// Odstępy poziome (tracking) dla dużych liczb / nagłówków.
abstract final class AppTextLayout {
  AppTextLayout._();

  /// Wyświetlacz timera — cyfry tabular + szeroki tracking.
  static const double timerDigitsLetterSpacing = 2;

  /// Nagłówek na ekranie splash nad gradientem.
  static const double splashTitleLetterSpacing = 0.5;
}

/// Skala tekstów aplikacji (Material 3 + dopasowania Work Timer).
///
/// Przekaż wynik do [ThemeData.textTheme], z tym samym [ColorScheme] co w motywie.
abstract final class AppTypography {
  AppTypography._();

  static TextTheme textTheme(ColorScheme colorScheme) {
    var base = ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
    ).textTheme;

    if (AppFonts.familyUi != null) {
      base = base.apply(fontFamily: AppFonts.familyUi);
    }

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        letterSpacing: AppTextLayout.timerDigitsLetterSpacing,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      displayMedium: base.displayMedium?.copyWith(
        letterSpacing: AppTextLayout.timerDigitsLetterSpacing,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: AppFontWeights.sectionTitle,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: AppFontWeights.splashTitle,
        letterSpacing: AppTextLayout.splashTitleLetterSpacing,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: AppFontWeights.splashSubtitle,
      ),
    );
  }
}
