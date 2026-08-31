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
    testWidgets('renders circular progress indicator without message',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const LoadingView(),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders message in full-page mode', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const LoadingView(message: 'Finding nearby drivers...'),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Finding nearby drivers...'), findsOneWidget);
    });

    testWidgets('renders compact inline loading row', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const LoadingView(
          message: 'Updating status...',
          isCompact: true,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Updating status...'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('applies custom size and color', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const LoadingView(
          size: 48,
          color: Colors.teal,
        ),
      ));

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.valueColor, isA<AlwaysStoppedAnimation<Color>>());
    });
  });
}
