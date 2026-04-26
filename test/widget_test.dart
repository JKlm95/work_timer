import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test renderuje bazowy scaffold', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Work Timer'))),
    );
    expect(find.text('Work Timer'), findsOneWidget);
  });
}
