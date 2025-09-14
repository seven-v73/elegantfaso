import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color secondary = Color(0xFF00CEFF);
  static const Color accent = Color(0xFFFD79A8);
  static const Color dark = Color(0xFF2D3436);
  static const Color light = Color(0xFFDFE6E9);
}

class AppTextStyles {
  static TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.dark,
  );

  static TextStyle subtitle1 = TextStyle(
    fontSize: 14,
    color: AppColors.dark.withOpacity(0.6),
  );
}