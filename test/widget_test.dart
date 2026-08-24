import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/main.dart';

void main() {
  testWidgets('RideSathi foundation app loads splash screen and navigates to home', (WidgetTester tester) async {
    // Build RideSathiApp and trigger a frame.
    await tester.pumpWidget(const RideSathiApp());

    // Verify that RideSathi app title is present on Splash screen.
    expect(find.text('RideSathi'), findsOneWidget);
    expect(find.text('Regional Cab & Auto-Rickshaw Union Network'), findsOneWidget);

    // Advance time to allow splash timer (2200ms) to complete and navigate to home.
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    // Verify home screen is loaded.
    expect(find.text('Welcome to RideSathi'), findsOneWidget);
    expect(find.text('System Foundation Status'), findsOneWidget);
  });
}
