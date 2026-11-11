// Basic smoke test: the app boots to the login screen when logged out.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pfms_mobile/main.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const PfmsApp());
    // Startup gate shows a spinner while checking for a saved session.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
