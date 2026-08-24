import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

/// Centralized Material 3 Theme system for RideSathi.
class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryAmber,
        primary: AppConstants.primaryAmber,
        secondary: AppConstants.secondaryTeal,
        surface: AppConstants.backgroundLight,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppConstants.backgroundLight,
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppConstants.accentNavy,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppConstants.accentNavy,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: const Color(0xFF334155),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.accentNavy,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppConstants.cardLight,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryAmber,
        primary: AppConstants.primaryAmber,
        secondary: AppConstants.secondaryTeal,
        surface: AppConstants.cardDark,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppConstants.backgroundDark,
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: const Color(0xFF94A3B8),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        color: AppConstants.cardDark,
      ),
    );
  }
}
