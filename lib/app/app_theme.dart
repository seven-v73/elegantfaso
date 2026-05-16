import 'package:flutter/material.dart';

import '../design/modern_design_system.dart';

class AppTheme {
  static ThemeData get lightTheme => ModernTheme.light;

  static ThemeData get darkTheme {
    final light = ModernTheme.light;
    const darkScheme = ColorScheme.dark(
      primary: ModernColors.primary,
      secondary: ModernColors.accent,
      surface: Color(0xFF111827),
      error: ModernColors.danger,
      onPrimary: Colors.white,
      onSecondary: ModernColors.ink,
      onSurface: Colors.white,
    );

    return light.copyWith(
      brightness: Brightness.dark,
      colorScheme: darkScheme,
      scaffoldBackgroundColor: const Color(0xFF0B1120),
      appBarTheme: light.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF0B1120),
        foregroundColor: Colors.white,
        titleTextStyle: light.appBarTheme.titleTextStyle?.copyWith(
          color: Colors.white,
        ),
      ),
      cardTheme: light.cardTheme.copyWith(
        color: const Color(0xFF111827),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
