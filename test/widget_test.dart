// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:warp_mobile_ai_ide/main.dart';

void main() {
  testWidgets('Warp Mobile AI IDE app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WarpMobileAIIDE());

    // Verify that the app loads and has the basic terminal structure
    // We expect the app to have some basic text elements
    await tester.pumpAndSettle(const Duration(seconds: 2));
    
    // The app should load without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
