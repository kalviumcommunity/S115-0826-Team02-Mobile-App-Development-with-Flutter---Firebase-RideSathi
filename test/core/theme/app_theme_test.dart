import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/constants/app_constants.dart';
import 'package:ridesathi/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppTheme Light Theme', () {
    testWidgets('instantiates with Material 3 enabled and Brightness.light',
        (WidgetTester tester) async {
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.useMaterial3, isTrue);
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, AppConstants.backgroundLight);
    });

    testWidgets('provides semantic light color scheme',
        (WidgetTester tester) async {
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.colorScheme.primary, AppConstants.primaryAmber);
      expect(lightTheme.colorScheme.secondary, AppConstants.secondaryTeal);
      expect(lightTheme.colorScheme.surface, AppConstants.backgroundLight);
      expect(lightTheme.colorScheme.onPrimary, Colors.black);
      expect(lightTheme.colorScheme.onSurface, AppConstants.accentNavy);
    });

    testWidgets('configures inputDecorationTheme for forms',
        (WidgetTester tester) async {
      final lightTheme = AppTheme.lightTheme;
      final inputTheme = lightTheme.inputDecorationTheme;
      expect(inputTheme.filled, isTrue);
      expect(inputTheme.fillColor, AppConstants.surfaceVariantLight);
      expect(inputTheme.border, isA<OutlineInputBorder>());
    });

    testWidgets('configures elevatedButtonTheme & outlinedButtonTheme',
        (WidgetTester tester) async {
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.elevatedButtonTheme.style, isNotNull);
      expect(lightTheme.outlinedButtonTheme.style, isNotNull);
    });
  });

  group('AppTheme Dark Theme', () {
    testWidgets('instantiates with Material 3 enabled and Brightness.dark',
        (WidgetTester tester) async {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.useMaterial3, isTrue);
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, AppConstants.backgroundDark);
    });

    testWidgets('provides semantic dark color scheme',
        (WidgetTester tester) async {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.colorScheme.primary, AppConstants.primaryAmber);
      expect(darkTheme.colorScheme.secondary, AppConstants.secondaryTeal);
      expect(darkTheme.colorScheme.surface, AppConstants.cardDark);
      expect(darkTheme.colorScheme.onPrimary, Colors.black);
      expect(darkTheme.colorScheme.onSurface, Colors.white);
    });

    testWidgets('configures inputDecorationTheme for dark mode',
        (WidgetTester tester) async {
      final darkTheme = AppTheme.darkTheme;
      final inputTheme = darkTheme.inputDecorationTheme;
      expect(inputTheme.filled, isTrue);
      expect(inputTheme.border, isA<OutlineInputBorder>());
    });
  });
}
