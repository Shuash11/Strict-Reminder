import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color background = Color(0xFF0D1B2A); // Deep navy
  static const Color surface = Color(0xFF152232); // Dark card surface
  static const Color alarmAccent = Color(0xFFFF4500); // Red-orange
  static const Color alarmAccentDark = Color(0xFF1A0000); // Dark red for gradients
  static const Color successGreen = Color(0xFF22C55E);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);

  // Escalation / warning
  static const Color escalationRed = Color(0xFFDC2626);

  // Snooze / pending
  static const Color snoozeAmber = Color(0xFFF59E0B);

  // Gradient pairs
  static const List<Color> alarmGradient = [alarmAccent, alarmAccentDark];
  static const List<Color> cardGradient = [surface, Color(0xFF1A2D42)];
}
