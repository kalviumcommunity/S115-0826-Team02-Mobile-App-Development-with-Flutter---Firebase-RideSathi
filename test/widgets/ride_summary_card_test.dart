import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/widgets/ride_summary_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget wrapWithTheme(Widget child, {bool isDark = false}) {
    return MaterialApp(
      theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(body: ListView(children: [child])),
    );
  }

  group('RideSummaryCard', () {
    testWidgets('renders basic ride information and status badge',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const RideSummaryCard(
          pickupAddress: 'Metro Station Gate 2',
          dropoffAddress: 'City Hospital Emergency',
          status: 'In Progress',
          dateTime: '27 Aug 2026, 02:45 PM',
        ),
      ));

      expect(find.text('Metro Station Gate 2'), findsOneWidget);
      expect(find.text('City Hospital Emergency'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('27 Aug 2026, 02:45 PM'), findsOneWidget);
    });

    testWidgets('renders driver, vehicle, and fare details when provided',
        (tester) async {
      await tester.pumpWidget(wrapWithTheme(
        const RideSummaryCard(
          pickupAddress: 'Union Auto Stand',
          dropoffAddress: 'University Campus',
          status: 'Completed',
          dateTime: '27 Aug 2026, 11:15 AM',
          driverName: 'Ramesh Kumar',
          vehicleInfo: 'Auto Rickshaw • DL-04-E-5678',
          fare: '₹120',
        ),
      ));

      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Auto Rickshaw • DL-04-E-5678'), findsOneWidget);
      expect(find.text('₹120'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('fires onTap callback when card is clicked', (tester) async {
      var cardTapped = false;

      await tester.pumpWidget(wrapWithTheme(
        RideSummaryCard(
          pickupAddress: 'Point A',
          dropoffAddress: 'Point B',
          status: 'Requested',
          dateTime: 'Today, 10:00 AM',
          onTap: () => cardTapped = true,
        ),
      ));

      await tester.tap(find.byType(RideSummaryCard));
      await tester.pump();

      expect(cardTapped, isTrue);
    });
  });
}
