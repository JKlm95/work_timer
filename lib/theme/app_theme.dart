import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_layout.dart';
import 'app_typography.dart';

ThemeData buildWorkTimerTheme(Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final scheme = AppColors.colorSchemeFor(brightness);
  final textTheme = AppTypography.textTheme(scheme);

  final cardColor = isLight
      ? AppColors.surfaceCard
      : scheme.surfaceContainerHigh;
  final inputFill = isLight
      ? AppColors.surfaceCard
      : scheme.surfaceContainerHighest;
  final borderIdle = isLight ? AppColors.borderInputIdle : scheme.outline;
  final chipOutline = scheme.outlineVariant.withValues(
    alpha: isLight ? 0.45 : 0.62,
  );
  final chipBg = scheme.surfaceContainerHighest.withValues(
    alpha: isLight ? 0.35 : 0.4,
  );

  return ThemeData(
    colorScheme: scheme,
    brightness: brightness,
    textTheme: textTheme,
    scaffoldBackgroundColor: isLight
        ? AppColors.surfaceApp
        : AppColors.surfaceAppDark,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusMd + 4),
      ),
      backgroundColor: cardColor,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusSm),
      ),
      side: BorderSide(color: chipOutline),
      backgroundColor: chipBg,
      deleteIconColor: scheme.onSurfaceVariant,
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      showCheckmark: false,
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusLg),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(0, AppLayout.minTouchTarget),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusSm + 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppLayout.secondaryButtonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.radiusSm + 2),
        ),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.75)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(
          AppLayout.minTouchTarget,
          AppLayout.minTouchTarget,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusMd),
      ),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isLight
          ? AppColors.surfaceCard
          : AppColors.surfaceNavDark,
      indicatorColor: isLight
          ? AppColors.brandNavIndicator
          : AppColors.brandNavIndicatorDark,
      surfaceTintColor: AppColors.transparent,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: AppColors.transparent,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: isLight ? 0.5 : 0.55),
      thickness: 1,
      space: 1,
    ),
    useMaterial3: true,
  );
}
