import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import 'modern_design_system.dart';

class AppStyles {
  static const Color primary = ModernColors.primary;
  static const Color secondary = ModernColors.accent;
  static const Color accent = ModernColors.shop;
  static const Color background = ModernColors.canvas;
  static const Color surface = ModernColors.surfaceRaised;
  static const Color cardColor = ModernColors.surface;
  static const Color textDark = ModernColors.ink;
  static const Color textLight = ModernColors.inkSoft;
  static const Color error = ModernColors.danger;

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ModernColors.primary, ModernColors.primaryDark],
  );

  static const LinearGradient darkOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Colors.black87],
  );

  static final headingStyle = GoogleFonts.cormorantGaramond(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: textDark,
    height: 1.1,
    letterSpacing: 0,
  );

  static final titleStyle = GoogleFonts.cormorantGaramond(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textDark,
    height: 1.15,
  );

  static final subtitleStyle = GoogleFonts.dmSans(
    fontSize: 18,
    color: textDark,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static final bodyStyle = GoogleFonts.dmSans(
    fontSize: 15,
    color: textDark,
    height: 1.6,
    letterSpacing: 0,
  );

  static final captionStyle = GoogleFonts.dmSans(
    fontSize: 13,
    color: textLight,
    height: 1.5,
  );

  static final cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radiusMd),
    boxShadow: [
      BoxShadow(
        color: Color(0x140F172A),
        offset: const Offset(0, 10),
        blurRadius: 24,
        spreadRadius: -12,
      ),
    ],
  );

  static final surfaceDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1),
  );

  static final buttonDecoration = BoxDecoration(
    gradient: premiumGradient,
    borderRadius: BorderRadius.circular(radiusMd),
    boxShadow: [
      BoxShadow(
        color: primary.withValues(alpha: 0.25),
        offset: const Offset(0, 6),
        blurRadius: 12,
      ),
    ],
  );

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    textTheme: GoogleFonts.dmSansTextTheme(),
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: error,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.cormorantGaramond(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textDark,
        letterSpacing: 0,
      ),
      backgroundColor: Colors.transparent,
      iconTheme: const IconThemeData(color: textDark),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
  );
}
