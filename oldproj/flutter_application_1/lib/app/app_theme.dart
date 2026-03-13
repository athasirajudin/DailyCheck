import 'package:flutter/material.dart';

class AppTheme {
  static const Color lemhannasNavy = Color(0xFF0A1E3A);
  static const Color lemhannasGold = Color(0xFFC9A227);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: lemhannasNavy,
      brightness: Brightness.light,
    ).copyWith(
      primary: lemhannasNavy,
      secondary: lemhannasGold,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}

