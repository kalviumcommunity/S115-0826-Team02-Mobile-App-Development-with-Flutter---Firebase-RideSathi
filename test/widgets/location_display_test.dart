import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/widgets/location_display.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget wrapWithTheme(Widget child, {bool isDark = false}) {
    return MaterialApp(
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );
  }

  group('LocationDisplay', () {
    testWidgets('renders pickup and drop-off addresses and default labels',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const LocationDisplay(
          pickupAddress: 'Central Railway Station, Platform 1',
          dropoffAddress: 'City Airport, Terminal 2 Departure',
        ),
      ));

      expect(find.text('Pickup'), findsOneWidget);
      expect(find.text('Central Railway Station, Platform 1'), findsOneWidget);
      expect(find.text('Drop-off'), findsOneWidget);
      expect(find.text('City Airport, Terminal 2 Departure'), findsOneWidget);
    });

    testWidgets('renders custom labels and secondary subtitles',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const LocationDisplay(
          pickupAddress: 'Sector 17 Bus Stand',
          dropoffAddress: 'Tech Park Tower A',
          pickupLabel: 'Origin',
          dropoffLabel: 'Destination',
          pickupSubtitle: 'Near Gate 3',
          dropoffSubtitle: 'Main Reception',
        ),
      ));

      expect(find.text('Origin'), findsOneWidget);
      expect(find.text('Sector 17 Bus Stand'), findsOneWidget);
      expect(find.text('Near Gate 3'), findsOneWidget);
      expect(find.text('Destination'), findsOneWidget);
      expect(find.text('Tech Park Tower A'), findsOneWidget);
      expect(find.text('Main Reception'), findsOneWidget);
    });

    testWidgets('renders in compact mode without labels and subtitles',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const LocationDisplay(
          pickupAddress: 'Origin Point',
          dropoffAddress: 'Destination Point',
          pickupSubtitle: 'Sub Info 1',
          dropoffSubtitle: 'Sub Info 2',
          isCompact: true,
        ),
      ));

      expect(find.text('Origin Point'), findsOneWidget);
      expect(find.text('Destination Point'), findsOneWidget);
      expect(find.text('Pickup'), findsNothing);
      expect(find.text('Sub Info 1'), findsNothing);
    });
  });
}
