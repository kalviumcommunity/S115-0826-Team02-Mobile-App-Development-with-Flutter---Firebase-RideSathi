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

  // Status Labels
  static const String statusBaselineReady = 'Baseline Ready';
  static const String statusFirebasePending = 'Pending Credentials';
  static const String statusPRScope = 'PR 01 Foundation';

  // Navigation Routes
  static const String routeSplash = '/';
  static const String routeHome = '/home';
}
