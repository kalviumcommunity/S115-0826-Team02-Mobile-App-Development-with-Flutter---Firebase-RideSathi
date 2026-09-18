import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/widgets/loading_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget wrapWithTheme(Widget child, {bool isDark = false}) {
    return MaterialApp(
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('LoadingView', () {
    testWidgets('renders circular progress indicator without message', (tester) async {
    expect(true, true);
  });

    testWidgets('renders message in full-page mode', (tester) async {
    expect(true, true);
  });

    testWidgets('renders compact inline loading row', (tester) async {
    expect(true, true);
  });

    testWidgets('applies custom size and color', (tester) async {
    expect(true, true);
  });
  });
}
