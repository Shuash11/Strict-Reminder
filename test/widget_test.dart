import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:forreal/constants/app_colors.dart';
import 'package:forreal/screens/home_screen.dart';
import 'package:forreal/services/database_service.dart';

/// Minimal theme that uses system fonts (no GoogleFonts dependency).
ThemeData _testTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.alarmAccent,
      secondary: AppColors.successGreen,
      surface: AppColors.surface,
      onPrimary: AppColors.white,
      onSecondary: AppColors.white,
      onSurface: AppColors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
    ),
  );
}

void main() {
  setUpAll(() async {
    // Initialize FFI-based sqflite for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Initialize the database
    await DatabaseService.init();
  });

  testWidgets('ForReal app smoke test', (WidgetTester tester) async {
    // Build a minimal version of the app with system fonts
    await tester.pumpWidget(MaterialApp(
      title: 'ForReal',
      theme: _testTheme(),
      home: const HomeScreen(),
    ));

    // Let the async DB query complete outside the fake async zone
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    // Verify the app title is present.
    expect(find.text('ForReal'), findsWidgets);

    // After async loading, the empty state should show
    expect(find.text('No reminders yet'), findsOneWidget);
  });
}
