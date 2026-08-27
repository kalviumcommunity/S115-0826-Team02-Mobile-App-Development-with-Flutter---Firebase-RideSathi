import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

/// Centralized Material 3 Theme system for RideSathi.
class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();
    const colorScheme = ColorScheme.light(
      primary: AppConstants.primaryAmber,
      onPrimary: Colors.black,
      primaryContainer: Color(0xFFFFF3C4),
      onPrimaryContainer: Colors.black,
      secondary: AppConstants.secondaryTeal,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE0F2F1),
      onSecondaryContainer: AppConstants.secondaryTeal,
      surface: AppConstants.backgroundLight,
      onSurface: AppConstants.accentNavy,
      surfaceContainerHighest: AppConstants.surfaceVariantLight,
      onSurfaceVariant: AppConstants.onSurfaceVariantLight,
      outline: AppConstants.outlineLight,
      error: AppConstants.errorColor,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppConstants.backgroundLight,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppConstants.accentNavy,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppConstants.accentNavy,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppConstants.accentNavy,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppConstants.accentNavy,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppConstants.accentNavy,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppConstants.onSurfaceVariantLight,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.accentNavy,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        color: AppConstants.cardLight,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.surfaceVariantLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceL,
          vertical: AppConstants.spaceM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          borderSide: const BorderSide(
            color: AppConstants.secondaryTeal,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          borderSide: const BorderSide(
            color: AppConstants.errorColor,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          borderSide: const BorderSide(
            color: AppConstants.errorColor,
            width: 2.0,
          ),
        ),
        labelStyle: const TextStyle(color: AppConstants.onSurfaceVariantLight),
        hintStyle: const TextStyle(color: AppConstants.onSurfaceVariantLight),
        prefixIconColor: AppConstants.onSurfaceVariantLight,
        suffixIconColor: AppConstants.onSurfaceVariantLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryAmber,
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.accentNavy,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          side: BorderSide(
            color: AppConstants.outlineLight.withValues(alpha: 0.5),
            width: 1.5,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.secondaryTeal,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppConstants.cardLight,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppConstants.accentNavy,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: AppConstants.accentNavy,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppConstants.accentNavy,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppConstants.outlineLight,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    const colorScheme = ColorScheme.dark(
      primary: AppConstants.primaryAmber,
      onPrimary: Colors.black,
      primaryContainer: Color(0xFF4A3800),
      onPrimaryContainer: AppConstants.primaryAmber,
      secondary: AppConstants.secondaryTeal,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF004D40),
      onSecondaryContainer: Color(0xFF80CBC4),
      surface: AppConstants.cardDark,
      onSurface: Colors.white,
      surfaceContainerHighest: AppConstants.surfaceVariantDark,
      onSurfaceVariant: AppConstants.onSurfaceVariantDark,
      outline: AppConstants.outlineDark,
      error: Color(0xFFEF4444),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppConstants.backgroundDark,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: const Color(0xFFCBD5E1),
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppConstants.onSurfaceVariantDark,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        color: AppConstants.cardDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.surfaceVariantDark.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceL,
          vertical: AppConstants.spaceM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          borderSide: const BorderSide(
            color: AppConstants.primaryAmber,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 2.0,
          ),
        ),
        labelStyle: const TextStyle(color: AppConstants.onSurfaceVariantDark),
        hintStyle: const TextStyle(color: AppConstants.onSurfaceVariantDark),
        prefixIconColor: AppConstants.onSurfaceVariantDark,
        suffixIconColor: AppConstants.onSurfaceVariantDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryAmber,
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          side: BorderSide(
            color: AppConstants.outlineDark.withValues(alpha: 0.5),
            width: 1.5,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.primaryAmber,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppConstants.cardDark,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFFCBD5E1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppConstants.surfaceVariantDark,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppConstants.outlineDark,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

