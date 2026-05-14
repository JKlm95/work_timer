import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';

import 'bloc/auth_cubit.dart';
import 'bloc/settings_cubit.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/employee_work_email_index_service.dart';
import 'services/firebase_work_store.dart';
import 'services/live_status_service.dart';
import 'services/local_cache_store.dart';
import 'services/user_email_index_service.dart';
import 'services/user_profile_repository.dart';
import 'services/work_repository.dart';
import 'theme/app_theme.dart';

final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Future.wait([
    initializeDateFormatting('en_US'),
    initializeDateFormatting('pl_PL'),
  ]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics: iOS / Android (web nie jest wspierany przez plugin).
  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  final prefs = await SharedPreferences.getInstance();
  final authService = AuthService();
  final workEmailIndex = EmployeeWorkEmailIndexService();
  final repository = WorkRepository(
    localCache: LocalCacheStore(),
    remoteStore: FirebaseWorkStore(),
    workEmailIndex: workEmailIndex,
  );
  final userProfileRepository = UserProfileRepository();
  final userEmailIndex = UserEmailIndexService();
  final liveStatusService = LiveStatusService();
  runApp(
    BlocProvider(
      create: (_) => SettingsCubit(prefs),
      child: WorkTimerApp(
        authService: authService,
        repository: repository,
        userProfileRepository: userProfileRepository,
        userEmailIndex: userEmailIndex,
        liveStatus: liveStatusService,
      ),
    ),
  );
}

class WorkTimerApp extends StatelessWidget {
  const WorkTimerApp({
    super.key,
    required this.authService,
    required this.repository,
    required this.userProfileRepository,
    required this.userEmailIndex,
    required this.liveStatus,
  });

  final AuthService authService;
  final WorkRepository repository;
  final UserProfileRepository userProfileRepository;
  final UserEmailIndexService userEmailIndex;
  final LiveStatusService liveStatus;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(
        authService,
        userEmailIndex: userEmailIndex,
        userProfileRepository: userProfileRepository,
        liveStatus: liveStatus,
      ),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorObservers: [
              FirebaseAnalyticsObserver(analytics: _analytics),
            ],
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
                return resolveMaterialLocale(settings.localePreference)!;
              }
              for (final l in supportedLocales) {
                if (l.languageCode == deviceLocale?.languageCode) {
                  return l;
                }
              }
              return supportedLocales.first;
            },
            home: AuthGate(
              repository: repository,
              userProfileRepository: userProfileRepository,
              userEmailIndex: userEmailIndex,
              liveStatus: liveStatus,
            ),
          );
        },
      ),
    );
  }
}
