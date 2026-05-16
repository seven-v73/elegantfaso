import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernColors {
  static const Color ink = Color(0xFF111827);
  static const Color inkSoft = Color(0xFF4B5563);
  static const Color muted = Color(0xFF9CA3AF);
  static const Color line = Color(0xFFE5E7EB);
  static const Color canvas = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceRaised = Color(0xFFFBFCFD);

  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color accent = Color(0xFFF59E0B);
  static const Color rose = Color(0xFFE11D48);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFEAB308);
  static const Color danger = Color(0xFFDC2626);

  static const Color client = Color(0xFF2563EB);
  static const Color creator = Color(0xFF7C3AED);
  static const Color shop = Color(0xFFEA580C);
  static const Color admin = Color(0xFF0F172A);
}

class ModernSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class ModernRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double button = 14;
  static const double pill = 999;
  static const double lg = 16;
  static const double xl = 20;
}

class ModernShadows {
  static const BoxShadow soft = BoxShadow(
    color: Color(0x140F172A),
    offset: Offset(0, 10),
    blurRadius: 24,
    spreadRadius: -12,
  );

  static const BoxShadow hover = BoxShadow(
    color: Color(0x1F0F172A),
    offset: Offset(0, 18),
    blurRadius: 32,
    spreadRadius: -16,
  );

  static const List<BoxShadow> card = [soft];
  static const List<BoxShadow> elevated = [hover];
}

class ModernGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ModernColors.primary, ModernColors.primaryDark],
  );

  static const LinearGradient warm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ModernColors.accent, ModernColors.shop],
  );
}

class ModernDecorations {
  static BoxDecoration card({Color color = ModernColors.surface}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(ModernRadius.md),
      border: Border.all(color: ModernColors.line),
      boxShadow: ModernShadows.card,
    );
  }

  static BoxDecoration softPanel() {
    return BoxDecoration(
      color: ModernColors.surfaceRaised,
      borderRadius: BorderRadius.circular(ModernRadius.lg),
      border: Border.all(color: ModernColors.line),
    );
  }

  static BoxDecoration neumorphicInset() {
    return BoxDecoration(
      color: ModernColors.canvas,
      borderRadius: BorderRadius.circular(ModernRadius.md),
      boxShadow: const [
        BoxShadow(
          color: Color(0xFFFFFFFF),
          offset: Offset(-4, -4),
          blurRadius: 10,
        ),
        BoxShadow(
          color: Color(0x1A0F172A),
          offset: Offset(4, 4),
          blurRadius: 12,
        ),
      ],
    );
  }
}

class ModernTheme {
  static TextStyle get editorialTitle => GoogleFonts.cormorantGaramond(
    fontSize: 30,
    height: 1.08,
    fontWeight: FontWeight.w600,
    color: ModernColors.ink,
    letterSpacing: 0,
  );

  static TextStyle get editorialSubtitle => GoogleFonts.cormorantGaramond(
    fontSize: 24,
    height: 1.12,
    fontWeight: FontWeight.w600,
    color: ModernColors.ink,
    letterSpacing: 0,
  );

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: ModernColors.primary,
      secondary: ModernColors.accent,
      surface: ModernColors.surface,
      error: ModernColors.danger,
      onPrimary: Colors.white,
      onSecondary: ModernColors.ink,
      onSurface: ModernColors.ink,
    );

    final baseTextTheme = GoogleFonts.dmSansTextTheme().copyWith(
      headlineLarge: GoogleFonts.cormorantGaramond(
        fontSize: 30,
        height: 1.08,
        fontWeight: FontWeight.w600,
        color: ModernColors.ink,
        letterSpacing: 0,
      ),
      headlineMedium: GoogleFonts.cormorantGaramond(
        fontSize: 24,
        height: 1.12,
        fontWeight: FontWeight.w600,
        color: ModernColors.ink,
        letterSpacing: 0,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 18,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: ModernColors.ink,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: ModernColors.ink,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: ModernColors.ink,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: ModernColors.inkSoft,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: ModernColors.ink,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ModernColors.canvas,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashColor: ModernColors.primary.withValues(alpha: 0.08),
      highlightColor: ModernColors.primary.withValues(alpha: 0.04),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: ModernColors.canvas,
        foregroundColor: ModernColors.ink,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          color: ModernColors.ink,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      textTheme: baseTextTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: ModernColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernRadius.md),
          side: const BorderSide(color: ModernColors.line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: ModernColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernRadius.button),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernRadius.button),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ModernColors.ink,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: ModernColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernRadius.button),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ModernColors.inkSoft,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernRadius.button),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernRadius.button),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 1,
        backgroundColor: ModernColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernRadius.button),
        ),
        extendedTextStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ModernColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: ModernColors.muted),
        labelStyle: const TextStyle(color: ModernColors.inkSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ModernRadius.sm),
          borderSide: const BorderSide(color: ModernColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ModernRadius.sm),
          borderSide: const BorderSide(color: ModernColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ModernRadius.sm),
          borderSide: const BorderSide(color: ModernColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ModernRadius.sm),
          borderSide: const BorderSide(color: ModernColors.danger),
        ),
      ),
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 0,
        backgroundColor: ModernColors.surfaceRaised,
        selectedColor: ModernColors.primary.withValues(alpha: 0.12),
        labelStyle: const TextStyle(
          color: ModernColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        side: const BorderSide(color: ModernColors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernRadius.pill),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected)
                    ? ModernColors.primary.withValues(alpha: 0.12)
                    : ModernColors.surfaceRaised,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected)
                    ? ModernColors.primary
                    : ModernColors.inkSoft,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color:
                  states.contains(WidgetState.selected)
                      ? ModernColors.primary.withValues(alpha: 0.28)
                      : ModernColors.line,
            ),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ModernRadius.button),
            ),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 66,
        backgroundColor: ModernColors.surface,
        indicatorColor: ModernColors.primary.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color:
                states.contains(WidgetState.selected)
                    ? ModernColors.ink
                    : ModernColors.inkSoft,
            fontSize: 11,
            fontWeight:
                states.contains(WidgetState.selected)
                    ? FontWeight.w900
                    : FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color:
                states.contains(WidgetState.selected)
                    ? ModernColors.primary
                    : ModernColors.inkSoft,
            size: 22,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ModernColors.line,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ModernColors.surface,
        selectedItemColor: ModernColors.primary,
        unselectedItemColor: ModernColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
