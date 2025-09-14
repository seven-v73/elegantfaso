import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true, // Active Material 3
      colorScheme: ColorScheme.light(
        primary: ColorConstants.primary,
        secondary: ColorConstants.secondary,
        surface: Colors.white,
        background: ColorConstants.background,
        error: ColorConstants.error,
      ),
      scaffoldBackgroundColor: ColorConstants.background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'Inter',
      applyElevationOverlayColor: true,

      // Text Theme - Plus complet et organisé
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: ColorConstants.text,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ColorConstants.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: ColorConstants.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ColorConstants.text.withOpacity(0.8),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),

      // Boutons - Configurations plus complètes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ColorConstants.primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.primary,
          side: BorderSide(color: ColorConstants.primary),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Champs de formulaire - Plus détaillé
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ColorConstants.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorConstants.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ColorConstants.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
        ),
        errorStyle: TextStyle(
          color: ColorConstants.error,
        ),
      ),

      // Cartes - Plus moderne avec Material 3
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
      ),

      // AppBar - Plus personnalisable
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actionsIconTheme: const IconThemeData(color: Colors.black),
        toolbarTextStyle: const TextStyle(
          color: Colors.black,
          fontFamily: 'Inter',
        ),
      ),

      // Autres composants
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 0,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        disabledColor: Colors.grey.shade300,
        selectedColor: ColorConstants.primary,
        secondarySelectedColor: ColorConstants.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        labelStyle: TextStyle(
          color: Colors.black,
          fontSize: 14,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        brightness: Brightness.light,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: ColorConstants.primary,
        secondary: ColorConstants.secondary,
        surface: Colors.grey.shade900,
        background: Colors.grey.shade900,
        error: ColorConstants.error,
      ),
      scaffoldBackgroundColor: Colors.grey.shade900,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'Inter',
      applyElevationOverlayColor: true,

      // Text Theme pour dark mode
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.white.withOpacity(0.8),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),

      // Cartes pour dark mode
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
        color: Colors.grey.shade800,
        surfaceTintColor: Colors.grey.shade800,
        shadowColor: Colors.black.withOpacity(0.3),
      ),


      // AppBar pour dark mode
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        toolbarTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inter',
        ),
      ),

      // Autres configurations dark mode
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade700,
        thickness: 1,
        space: 0,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ColorConstants.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: TextStyle(
          color: Colors.grey.shade400,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  // Méthode pour créer MaterialColor inchangée
  static MaterialColor _createMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};

    for (var i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (var strength in strengths) {
      final ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        color.red + ((ds < 0 ? color.red : (255 - color.red)) * ds).round(),
        color.green + ((ds < 0 ? color.green : (255 - color.green)) * ds).round(),
        color.blue + ((ds < 0 ? color.blue : (255 - color.blue)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}