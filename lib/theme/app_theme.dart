import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

ThemeData buildWorkTimerTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brandPrimary,
    brightness: brightness,
    surface: isLight ? AppColors.surfaceApp : null,
  );

  final cardColor = isLight ? AppColors.surfaceCard : scheme.surfaceContainerHigh;
  final inputFill = isLight ? AppColors.surfaceCard : scheme.surfaceContainerHighest;
  final borderIdle = isLight ? AppColors.borderInputIdle : scheme.outlineVariant;

  return ThemeData(
    colorScheme: scheme,
    textTheme: AppTypography.textTheme(scheme),
    scaffoldBackgroundColor: isLight ? AppColors.surfaceApp : scheme.surface,
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderIdle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.brandPrimary,
          width: 1.4,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isLight ? AppColors.surfaceCard : scheme.surfaceContainer,
      indicatorColor: isLight
          ? AppColors.brandNavIndicator
          : AppColors.brandPrimary.withValues(alpha: 0.28),
    ),
    useMaterial3: true,
  );
}
