import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controllers/work_timer_controller.dart';
import 'screens/home_shell.dart';
import 'services/work_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = WorkStorage();
  final controller = WorkTimerController(storage);
  await controller.init();
  runApp(WorkTimerApp(controller: controller));
}

class WorkTimerApp extends StatelessWidget {
  const WorkTimerApp({super.key, required this.controller});

  final WorkTimerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
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
          home: HomeShell(controller: controller),
        );
      },
    );
  }
}
