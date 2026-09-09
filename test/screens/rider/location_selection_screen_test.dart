import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/routes/app_routes.dart';
import 'package:ridesathi/core/theme/app_theme.dart';
import 'package:ridesathi/screens/rider/location_selection_screen.dart';

void main() {
  Widget buildTestApp() {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRoutes.generateRoute,
      home: const LocationSelectionScreen(),
    );
  }

  group('LocationSelectionScreen Widget Tests', () {
    testWidgets('renders initial state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('Request a Ride'), findsOneWidget);
      expect(find.text('Where would you like to go?'), findsOneWidget);
      expect(find.text('Pickup location'), findsOneWidget);
      expect(find.text('Where are you going?'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('shows validation error when continue pressed without locations', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Please select a pickup location.'), findsOneWidget);
    });
  });
}
