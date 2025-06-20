// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:ai_wrozka/main.dart';

void main() {
  testWidgets('Welcome screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AIWrozkaApp());

    // Verify that the welcome text is displayed
    expect(find.text('Dotyk gwiazd,'), findsOneWidget);
    expect(find.text('by odkryć swoją przyszłość'), findsOneWidget);

    // Verify that the main button is displayed
    expect(find.text('✨ Zajrzyj w swoje przeznaczenie'), findsOneWidget);
  });
}
