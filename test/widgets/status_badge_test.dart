import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/widgets/status_badge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget wrapWithTheme(Widget child, {bool isDark = false}) {
    return MaterialApp(
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('StatusBadge', () {
    testWidgets('renders Requested status correctly', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const StatusBadge(status: 'Requested'),
      ));

      expect(find.text('Requested'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    });

    testWidgets('renders Assigned status correctly', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const StatusBadge(status: 'Assigned'),
      ));

      expect(find.text('Assigned'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_ind_rounded), findsOneWidget);
    });

    testWidgets('renders Driver En Route status correctly', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const StatusBadge(status: 'Driver En Route'),
      ));

      expect(find.text('Driver En Route'), findsOneWidget);
      expect(find.byIcon(Icons.directions_car_filled_rounded), findsOneWidget);
    });

    testWidgets('renders In Progress status correctly', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const StatusBadge(status: 'In Progress'),
      ));

      expect(find.text('In Progress'), findsOneWidget);
      expect(find.byIcon(Icons.navigation_rounded), findsOneWidget);
    });

    testWidgets('renders Completed status correctly', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const StatusBadge(status: 'Completed'),
      ));

      expect(find.text('Completed'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders Cancelled status correctly', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const StatusBadge(status: 'Cancelled'),
      ));

      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    });

    testWidgets('renders No Show status correctly', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const StatusBadge(status: 'No Show'),
      ));

      expect(find.text('No Show'), findsOneWidget);
      expect(find.byIcon(Icons.person_off_rounded), findsOneWidget);
    });

    testWidgets('renders Needs Dispatch status correctly', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const StatusBadge(status: 'Needs Dispatch'),
      ));

      expect(find.text('Needs Dispatch'), findsOneWidget);
      expect(find.byIcon(Icons.support_agent_rounded), findsOneWidget);
    });

    testWidgets('handles unknown / fallback status gracefully', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const StatusBadge(status: 'Custom Operational State'),
      ));

      expect(find.text('Custom Operational State'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('supports custom icon and color override', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const StatusBadge(
          status: 'Custom',
          customIcon: Icons.star_rounded,
          customColor: Colors.purple,
        ),
      ));

      expect(find.text('Custom'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('renders compact mode without error', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const StatusBadge(status: 'Completed', isCompact: true),
      ));

      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('renders cleanly in dark theme', (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const StatusBadge(status: 'Completed'),
        isDark: true,
      ));

      expect(find.text('Completed'), findsOneWidget);
    });
  });
}
