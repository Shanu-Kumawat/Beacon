import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primary = Colors.blue;
  static const Color secondary = Colors.blueAccent;

  // Background Colors
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color cardBackground = Color(0xFF252525);

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textHint = Color(0xFF666666);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Component Colors
  static const Color divider = Color(0xFF2D2D2D);
  static const Color disabled = Color(0xFF404040);
  static final Color overlay = Colors.black.withOpacity(0.5);

  // Button Colors
  static const Color buttonBackground = primary;
  static const Color buttonText = Colors.white;

  // Custom Styles
  static const double borderRadius = 12.0;
  static const double spacing = 16.0;

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    cardColor: cardBackground,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      onSurface: textPrimary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonBackground,
        foregroundColor: buttonText,
        padding: const EdgeInsets.symmetric(
            horizontal: spacing * 1.5, vertical: spacing),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    ),
  );
}
