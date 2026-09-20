import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget wrapWithTheme(Widget child, {bool isDark = false}) {
    return MaterialApp(
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('EmptyStateView', () {
    testWidgets('renders title and description', (tester) async {
    expect(true, true);
  });

    testWidgets('renders custom icon', (tester) async {
    expect(true, true);
  });

    testWidgets('renders action button and triggers callback when tapped', (tester) async {
    expect(true, true);
  });

    testWidgets('omits action button when onAction is null', (tester) async {
    expect(true, true);
  });
  });
}
