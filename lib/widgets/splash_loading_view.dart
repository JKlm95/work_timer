import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../theme/app_colors.dart';

/// Pełnoekranowy ekran startowy pokazywany podczas rozstrzygania auth
/// i pierwszego [TimerCubit.init].
class SplashLoadingView extends StatefulWidget {
  const SplashLoadingView({super.key});

  @override
  State<SplashLoadingView> createState() => _SplashLoadingViewState();
}

class _SplashLoadingViewState extends State<SplashLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.splashGradientColors,
            stops: AppColors.splashGradientStops,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: 80,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.splashHaloStrong,
                  ),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: 120,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.splashHaloSoft,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _pulse,
                          curve: Curves.easeInOutCubic,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.splashGlassCircle,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.splashShadowSoft,
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.timer_outlined,
                          size: 56,
                          color: AppColors.splashIconOnGradient,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      AppLocalizations.of(context)!.appTitle,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.splashLoading,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.splashSubtitleOnGradient,
                      ),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: 160,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: AppColors.splashProgressTrack,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
