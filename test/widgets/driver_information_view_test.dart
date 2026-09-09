import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/driver_information_controller.dart';
import 'package:ridesathi/models/user_model.dart';
import 'package:ridesathi/services/user_profile_service.dart';
import 'package:ridesathi/widgets/driver_information_view.dart';

class MockUserProfileService implements UserProfileService {
  final Map<String, UserModel> mockDatabase = {};
  bool throwError = false;

  @override
  Future<UserModel?> getUserProfile(String uid) async {
    if (throwError) throw Exception('Simulated error');
    await Future.delayed(const Duration(milliseconds: 50)); // simulate network delay
    return mockDatabase[uid];
  }

  @override
  Future<void> createDriverProfile(UserModel user) async {}

  @override
  Future<void> createRiderProfile(UserModel user) async {}

  @override
  Future<UserModel> updateProfile({required String uid, required Map<String, dynamic> updates}) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> updateProfileFields({required String uid, String? name, String? phoneNumber, String? vehicleInfo}) async {
    throw UnimplementedError();
  }
}

void main() {
  group('DriverInformationView', () {
    late MockUserProfileService mockService;
    late DriverInformationController controller;

    final testDriver = UserModel(
      id: 'driver_1',
      name: 'Ramesh Singh',
      phoneNumber: '1234567890',
      role: UserRole.driver,
      vehicleInfo: 'Auto Rickshaw',
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockService = MockUserProfileService();
      controller = DriverInformationController(profileService: mockService);
    });

    Widget createWidgetUnderTest(String? driverId) {
      return MaterialApp(
        home: Scaffold(
          body: DriverInformationView(
            driverId: driverId,
            controller: controller,
          ),
        ),
      );
    }

    testWidgets('renders waiting state when driverId is null', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(null));
      
      expect(find.text('Waiting for driver assignment'), findsOneWidget);
    });

    testWidgets('renders loading state then success state with driver info', (WidgetTester tester) async {
      mockService.mockDatabase[testDriver.id] = testDriver;

      await tester.pumpWidget(createWidgetUnderTest(testDriver.id));
      
      // Initially it should show loading (since we simulated delay)
      expect(find.text('Loading driver details...'), findsOneWidget);

      // Wait for the async load to complete
      await tester.pumpAndSettle();

      // Should now show driver info
      expect(find.text('Driver'), findsOneWidget);
      expect(find.text('Ramesh Singh'), findsOneWidget);
      expect(find.text('Auto Rickshaw'), findsOneWidget);
    });

    testWidgets('renders error state when driver profile is missing', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest('non_existent_driver'));
      
      await tester.pumpAndSettle();

      expect(find.text('Driver unavailable'), findsOneWidget);
      expect(find.text('Driver information is currently unavailable.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget); // Retry button
    });
  });
}
