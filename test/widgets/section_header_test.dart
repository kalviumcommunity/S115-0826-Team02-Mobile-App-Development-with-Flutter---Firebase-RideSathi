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
      await tester.pumpWidget(wrapWithTheme(
        const SectionHeader(
          title: 'Recent Trips',
          subtitle: 'Completed in the last 30 days',
        ),
      ));

      expect(find.text('Recent Trips'), findsOneWidget);
      expect(find.text('Completed in the last 30 days'), findsOneWidget);
    });

    testWidgets('renders action button and fires callback on tap',
        (tester) async {
      var actionFired = false;

      await tester.pumpWidget(wrapWithTheme(
        SectionHeader(
          title: 'Active Drivers',
          actionLabel: 'View All',
          actionIcon: Icons.arrow_forward_rounded,
          onAction: () => actionFired = true,
        ),
      ));

      expect(find.text('Active Drivers'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      await tester.tap(find.text('View All'));
      await tester.pump();

      expect(actionFired, isTrue);
    });

    testWidgets('renders icon-only action when actionLabel is null',
        (tester) async {
      var iconActionFired = false;

      await tester.pumpWidget(wrapWithTheme(
        SectionHeader(
          title: 'Quick Filter',
          actionIcon: Icons.filter_list_rounded,
          onAction: () => iconActionFired = true,
        ),
      ));

      expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.filter_list_rounded));
      await tester.pump();

      expect(iconActionFired, isTrue);
    });
  });
}
