import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/widgets/empty_state_view.dart';

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
      await tester.pumpWidget(wrapWithTheme(
        const EmptyStateView(
          title: 'No Active Rides',
          description: 'You do not have any rides in progress at this moment.',
        ),
      ));

      expect(find.text('No Active Rides'), findsOneWidget);
      expect(
        find.text('You do not have any rides in progress at this moment.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
    });

    testWidgets('renders custom icon', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const EmptyStateView(
          title: 'No Drivers Available',
          icon: Icons.local_taxi_rounded,
        ),
      ));

      expect(find.text('No Drivers Available'), findsOneWidget);
      expect(find.byIcon(Icons.local_taxi_rounded), findsOneWidget);
    });

    testWidgets('renders action button and triggers callback when tapped',
        (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(wrapWithTheme(
        EmptyStateView(
          title: 'No Ride History',
          actionLabel: 'Book a Ride',
          actionIcon: Icons.add_rounded,
          onAction: () => actionTriggered = true,
        ),
      ));

      expect(find.text('Book a Ride'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      await tester.tap(find.text('Book a Ride'));
      await tester.pump();

      expect(actionTriggered, isTrue);
    });

    testWidgets('omits action button when onAction is null', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const EmptyStateView(
          title: 'No Results Found',
          description: 'Try adjusting your search filters.',
        ),
      ));

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });
}
