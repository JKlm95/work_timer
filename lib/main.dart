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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: AuthGate(repository: repository),
      ),
    );
  }
}
