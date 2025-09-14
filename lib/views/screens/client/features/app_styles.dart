import 'package:flutter/material.dart';

class AppStyles {
  static const Color primaryColor = Color(0xFF0A0E21);
  static const Color accentColor = Color(0xFFFF2D55);
  static const Color primaryBackgroundColor = Color(0xFFF8F9FA);
  static const Color primaryTextColor = Color(0xFF1A1A1A);
  static const Color secondaryTextColor = Color(0xFF6C757D);

  static TextStyle headlineStyle = const TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: primaryTextColor,
  );

  static TextStyle titleStyle = const TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
  );

  static TextStyle subtitleStyle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: secondaryTextColor,
  );

  static TextStyle bodyStyle = const TextStyle(
    fontFamily: 'OpenSans',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: primaryTextColor,
  );
}