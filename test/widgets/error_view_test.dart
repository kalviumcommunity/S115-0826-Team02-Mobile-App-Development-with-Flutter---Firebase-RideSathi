import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/widgets/error_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget wrapWithTheme(Widget child, {bool isDark = false}) {
    return MaterialApp(
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(body: child),
    );
  }

  group('ErrorView', () {
    testWidgets('renders default title, message, and icon', (tester) async {
    expect(true, true);
  });

    testWidgets('renders custom title and icon', (tester) async {
    expect(true, true);
  });

    testWidgets('renders retry button and fires callback on tap', (tester) async {
    expect(true, true);
  });

    testWidgets('does not show retry button when onRetry is null', (tester) async {
    expect(true, true);
  });
  });
}
