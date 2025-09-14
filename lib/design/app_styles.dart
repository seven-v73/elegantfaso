import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class AppStyles {
  static const Color primary = Color(0xFF8B4513);
  static const Color secondary = Color(0xFFD4AF37);
  static const Color accent = Color(0xFFA0522D);
  static const Color background = Color(0xFFF8F5F0);
  static const Color surface = Color(0xFFFFFCF7);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF2E2A24);
  static const Color textLight = Color(0xFF7A756D);
  static const Color error = Color(0xFFC14533);

  static const double spacing_xs = 4.0;
  static const double spacing_sm = 8.0;
  static const double spacing_md = 16.0;
  static const double spacing_lg = 24.0;
  static const double spacing_xl = 32.0;
  static const double spacing_xxl = 48.0;

  static const double radius_sm = 8.0;
  static const double radius_md = 12.0;
  static const double radius_lg = 16.0;
  static const double radius_xl = 24.0;
  static const double radius_xxl = 32.0;

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B4513), Color(0xFFD4AF37)],
  );

  static const LinearGradient darkOverlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Colors.black87],
  );

  static final headingStyle = GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textDark,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static final titleStyle = GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textDark,
    height: 1.3,
  );

  static final subtitleStyle = GoogleFonts.montserrat(
    fontSize: 18,
    color: textDark,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static final bodyStyle = GoogleFonts.montserrat(
    fontSize: 15,
    color: textDark,
    height: 1.6,
    letterSpacing: 0.1,
  );

  static final captionStyle = GoogleFonts.montserrat(
    fontSize: 13,
    color: textLight,
    height: 1.5,
  );

  static final cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(radius_md),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        offset: const Offset(0, 6),
        blurRadius: 16,
        spreadRadius: -2,
      ),
    ],
  );

  static final surfaceDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(radius_md),
    border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
  );

  static final buttonDecoration = BoxDecoration(
    gradient: premiumGradient,
    borderRadius: BorderRadius.circular(radius_md),
    boxShadow: [
      BoxShadow(
        color: primary.withOpacity(0.25),
        offset: const Offset(0, 6),
        blurRadius: 12,
      ),
    ],
  );

  static ThemeData get theme => ThemeData(
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    textTheme: GoogleFonts.montserratTextTheme(),
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surface,
      background: background,
      error: error,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textDark,
      ),
      backgroundColor: Colors.transparent,
      iconTheme: const IconThemeData(color: textDark),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
  );
}
