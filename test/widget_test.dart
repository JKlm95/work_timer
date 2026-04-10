import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:work_timer/controllers/work_timer_controller.dart';
import 'package:work_timer/main.dart';
import 'package:work_timer/services/work_storage.dart';

void main() {
  testWidgets('Work Timer — podstawowy smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = WorkStorage();
    final controller = WorkTimerController(storage);
    await controller.init();

    await tester.pumpWidget(WorkTimerApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Work Timer'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Historia'), findsOneWidget);
  });
}
