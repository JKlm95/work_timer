import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'bloc/auth_cubit.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/firebase_work_store.dart';
import 'services/local_cache_store.dart';
import 'services/work_repository.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final authService = AuthService();
  final repository = WorkRepository(
    localCache: LocalCacheStore(),
    remoteStore: FirebaseWorkStore(),
  );
  runApp(WorkTimerApp(authService: authService, repository: repository));
}

class WorkTimerApp extends StatelessWidget {
  const WorkTimerApp({
    super.key,
    required this.authService,
    required this.repository,
  });

  final AuthService authService;
  final WorkRepository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(authService),
      child: MaterialApp(
        title: 'Work Timer',
        locale: const Locale('pl'),
        supportedLocales: const [Locale('pl')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: () {
          final scheme = ColorScheme.fromSeed(
            seedColor: AppColors.brandPrimary,
            brightness: Brightness.light,
            surface: AppColors.surfaceApp,
          );
          return ThemeData(
            colorScheme: scheme,
            textTheme: AppTypography.textTheme(scheme),
            scaffoldBackgroundColor: AppColors.surfaceApp,
            cardTheme: CardThemeData(
              color: AppColors.surfaceCard,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.surfaceCard,
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
                borderSide: const BorderSide(color: AppColors.borderInputIdle),
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
            navigationBarTheme: const NavigationBarThemeData(
              backgroundColor: AppColors.surfaceCard,
              indicatorColor: AppColors.brandNavIndicator,
            ),
            useMaterial3: true,
          );
        }(),
        home: AuthGate(repository: repository),
      ),
    );
  }
}
