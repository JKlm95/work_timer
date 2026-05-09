import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';

import 'bloc/auth_cubit.dart';
import 'bloc/settings_cubit.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/firebase_work_store.dart';
import 'services/local_cache_store.dart';
import 'services/work_repository.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  final authService = AuthService();
  final repository = WorkRepository(
    localCache: LocalCacheStore(),
    remoteStore: FirebaseWorkStore(),
  );
  runApp(
    BlocProvider(
      create: (_) => SettingsCubit(prefs),
      child: WorkTimerApp(authService: authService, repository: repository),
    ),
  );
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
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return MaterialApp(
            onGenerateTitle: (context) =>
                AppLocalizations.of(context)!.appTitle,
            theme: buildWorkTimerTheme(Brightness.light),
            darkTheme: buildWorkTimerTheme(Brightness.dark),
            themeMode: settings.themeMode,
            locale: resolveMaterialLocale(settings.localePreference),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              if (settings.localePreference != AppLocalePreference.system) {
                return resolveMaterialLocale(
                  settings.localePreference,
                )!;
              }
              for (final l in supportedLocales) {
                if (l.languageCode == deviceLocale?.languageCode) {
                  return l;
                }
              }
              return supportedLocales.first;
            },
            home: AuthGate(repository: repository),
          );
        },
      ),
    );
  }
}
