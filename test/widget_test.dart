import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/main.dart';
import 'package:ridesathi/services/firebase_service.dart';

void main() {
  testWidgets(
      'RideSathi foundation app loads splash screen and shows branding',
      (WidgetTester tester) async {
    // Build RideSathiApp and trigger a frame.
    await tester.pumpWidget(const RideSathiApp());

    // Verify that RideSathi app title is present on Splash screen.
    expect(find.text('RideSathi'), findsOneWidget);
    expect(
      find.text('Regional Cab & Auto-Rickshaw Union Network'),
      findsOneWidget,
    );
  });

  testWidgets(
      'RideSathi splash navigates to login when Firebase is initialized',
      (WidgetTester tester) async {
    // Simulate Firebase being initialized for this test.
    FirebaseService.isInitializedOverride = true;

    await tester.pumpWidget(const RideSathiApp());

    // Verify splash branding is shown initially.
    expect(find.text('RideSathi'), findsOneWidget);

    // Advance time to allow splash timer (2200ms) to complete.
    await tester.pump(const Duration(milliseconds: 2500));
    // Pump additional frames for route transition.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // When Firebase is initialized but no user is logged in (test env),
    // splash navigates to login.
    expect(find.text('Sign in to continue'), findsOneWidget);

    // Clean up test state.
    FirebaseService.isInitializedOverride = false;
  });
}
