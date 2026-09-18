import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ridesathi/services/ride_service.dart';
import 'package:ridesathi/services/driver_availability_service.dart';
import 'package:ridesathi/services/driver_data_service.dart';
import 'package:ridesathi/services/user_profile_service.dart';
import 'package:ridesathi/widgets/custom_button.dart';
import 'package:ridesathi/main.dart';
import 'package:ridesathi/services/firebase_service.dart';

void main() {
  setUp(() {
    final globalFakeFirestore = FakeFirebaseFirestore();
    RideService.firestoreOverride = globalFakeFirestore;
    DriverAvailabilityService.firestoreOverride = globalFakeFirestore;
    DriverDataService.firestoreOverride = globalFakeFirestore;
    UserProfileService.firestoreOverride = globalFakeFirestore;
  });

  tearDown(() {
    RideService.firestoreOverride = null;
    DriverAvailabilityService.firestoreOverride = null;
    DriverDataService.firestoreOverride = null;
    UserProfileService.firestoreOverride = null;
  });
  testWidgets(
      'RideSathi foundation app loads splash screen and shows branding',
      (WidgetTester tester) async {
    // Build RideSathiApp and trigger a frame.
    await tester.pumpWidget(const RideSathiApp());

    // Verify that CircularProgressIndicator is present on Splash screen.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
      'RideSathi splash navigates to login when Firebase is initialized',
      (WidgetTester tester) async {
    // Simulate Firebase being initialized for this test.
    FirebaseService.isInitializedOverride = true;

    await tester.pumpWidget(const RideSathiApp());

    // Verify splash loading is shown initially.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Advance time to allow splash timer (2200ms) to complete.
    await tester.pump(const Duration(milliseconds: 2500));
    // Pump additional frames for route transition.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // When Firebase is initialized but no user is logged in (test env),
    // splash navigates to login.
    // Login screen has AuthTextFields and CustomButton.
    expect(find.byType(CustomButton), findsOneWidget);

    // Clean up test state.
    FirebaseService.isInitializedOverride = false;
  });
}
