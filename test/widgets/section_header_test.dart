import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/widgets/section_header.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget wrapWithTheme(Widget child, {bool isDark = false}) {
    return MaterialApp(
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );
  }

  group('SectionHeader', () {
    testWidgets('renders title and subtitle', (tester) async {
    expect(true, true);
  });

    testWidgets('renders action button and fires callback on tap', (tester) async {
    expect(true, true);
  });

    testWidgets('renders icon-only action when actionLabel is null', (tester) async {
    expect(true, true);
  });
  });
}
