import 'package:flutter/material.dart';

/// Application-wide design tokens, strings, and configuration constants for RideSathi.
class AppConstants {
  // Application Information
  static const String appName = 'RideSathi';
  static const String appTagline = 'Regional Cab & Auto-Rickshaw Union Network';
  static const String appVersion = '1.0.0+1';
  static const String unionName = 'Regional Cab & Auto Drivers Union';
  static const String unionCode = 'RCADU-2026';

  // Branding Colors
  static const Color primaryAmber = Color(0xFFFFB300); // Cab/Auto Vibrant Yellow-Gold
  static const Color secondaryTeal = Color(0xFF00897B); // Regional Union Teal
  static const Color accentNavy = Color(0xFF1E293B); // Sleek Dark Slate Navy
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color cardLight = Colors.white;
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color onSurfaceVariantLight = Color(0xFF64748B);
  static const Color onSurfaceVariantDark = Color(0xFF94A3B8);
  static const Color outlineLight = Color(0xFFCBD5E1);
  static const Color outlineDark = Color(0xFF475569);
  static const Color errorColor = Color(0xFFDC2626);

  // Spacing Design Tokens
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 24.0;
  static const double spaceXXL = 32.0;

  // Border Radius Design Tokens
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 14.0;
  static const double radiusXL = 16.0;
  static const double radiusPill = 20.0;
  static const double radiusFull = 100.0;

  // Status Labels
  static const String statusBaselineReady = 'Baseline Ready';
  static const String statusFirebasePending = 'Pending Credentials';
  static const String statusPRScope = 'PR 01 Foundation';

  // Navigation Routes
  static const String routeSplash = '/';
  static const String routeHome = '/home';
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
}

