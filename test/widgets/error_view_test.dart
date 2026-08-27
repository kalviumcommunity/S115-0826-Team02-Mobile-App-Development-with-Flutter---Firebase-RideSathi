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
      await tester.pumpWidget(wrapWithTheme(
        const ErrorView(
          message: 'Unable to connect to the RideSathi dispatch server.',
        ),
      ));

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(
        find.text('Unable to connect to the RideSathi dispatch server.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('renders custom title and icon', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ErrorView(
          title: 'Network Timeout',
          message: 'Please check your internet connection.',
          icon: Icons.wifi_off_rounded,
        ),
      ));

      expect(find.text('Network Timeout'), findsOneWidget);
      expect(
        find.text('Please check your internet connection.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('renders retry button and fires callback on tap',
        (tester) async {
      var retried = false;

      await tester.pumpWidget(wrapWithTheme(
        ErrorView(
          message: 'Failed to load rides.',
          retryLabel: 'Reload Rides',
          onRetry: () => retried = true,
        ),
      ));

      expect(find.text('Reload Rides'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      await tester.tap(find.text('Reload Rides'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('does not show retry button when onRetry is null',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const ErrorView(
          message: 'Fatal error occurred.',
        ),
      ));

      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
      expect(find.text('Try Again'), findsNothing);
    });
  });
}
