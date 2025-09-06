// This is a basic Flutter widget test for the Quizora app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gdg_app_dev_recruitment/main.dart';

void main() {
  setUpAll(() {
    // Initialize the ffi database factory for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App starts and loads home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FlashcardApp());

    // Wait for the app to load
    await tester.pump();

    // Verify that the app starts with basic navigation
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify we have some basic UI elements
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Study'), findsOneWidget);
    expect(find.text('Add Card'), findsOneWidget);
  });
}
