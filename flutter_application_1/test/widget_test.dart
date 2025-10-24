// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/screens/login_screen.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('App navigates from splash to login', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Verify that the splash screen text is shown initially
    expect(find.text('Bienvenido a las Pinequitas'), findsOneWidget);

    // Let the timer complete and navigation occur
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Verify we've navigated to the LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
