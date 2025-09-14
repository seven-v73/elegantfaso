import 'package:flutter/material.dart';

class BoutiqueColors {
  static const Color primary = Color(0xFF6A1B9A);
  static const Color primaryLight = Color(0xFF9C4DFF);
  static const Color primaryDark = Color(0xFF38006B);
  static const Color primaryText = Colors.white;
  static const Color secondary = Color(0xFFF9A825);
  static const Color background = Color(0xFFF5F5F5);
}

class BoutiqueTextStyles {
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: BoutiqueColors.primaryText,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );
}

class BoutiqueDimens {
  static const double appBarHeight = 56.0;
  static const double defaultPadding = 16.0;
  static const double cardRadius = 12.0;
}