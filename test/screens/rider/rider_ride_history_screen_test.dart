import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/rider_ride_history_controller.dart';
import 'package:ridesathi/core/state/view_state.dart';
import 'package:ridesathi/models/location_model.dart';
import 'package:ridesathi/models/ride_model.dart';
import 'package:ridesathi/screens/rider/rider_ride_history_screen.dart';
import 'package:ridesathi/widgets/empty_state_view.dart';
import 'package:ridesathi/widgets/error_view.dart';
import 'package:ridesathi/widgets/ride_history_card.dart';

class MockRiderRideHistoryController extends RiderRideHistoryController {
  ViewState<List<RideModel>> mockState = const ViewState.initial();
  int loadHistoryCallCount = 0;

  @override
  ViewState<List<RideModel>> get state => mockState;

  @override
  Future<void> loadHistory({bool refresh = false, RideStatus? status}) async {
    loadHistoryCallCount++;
  }
}

void main() {
  Widget buildTestWidget(RiderRideHistoryController controller) {
    return MaterialApp(
      home: RiderRideHistoryScreen(controller: controller),
    );
  }

  group('RiderRideHistoryScreen', () {
    late MockRiderRideHistoryController mockController;

    setUp(() {
      mockController = MockRiderRideHistoryController();
    });

    testWidgets('shows loading indicator', (WidgetTester tester) async {
      mockController.mockState = const ViewState.loading();

      await tester.pumpWidget(buildTestWidget(mockController));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error view', (WidgetTester tester) async {
      mockController.mockState = const ViewState.error('Network error');

      await tester.pumpWidget(buildTestWidget(mockController));

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('shows empty state view', (WidgetTester tester) async {
      mockController.mockState = const ViewState.success([]);

      await tester.pumpWidget(buildTestWidget(mockController));

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('No rides yet'), findsOneWidget);
    });

    testWidgets('shows list of ride history cards', (WidgetTester tester) async {
      mockController.mockState = ViewState.success([
        RideModel(
          id: 'ride_1',
          riderId: 'rider_1',
          vehicleType: VehicleType.autoRickshaw,
          pickup: const LocationModel(id: 'p1', latitude: 0, longitude: 0, address: 'A', displayName: 'A'),
          destination: const LocationModel(id: 'd1', latitude: 0, longitude: 0, address: 'B', displayName: 'B'),
          status: RideStatus.completed,
          estimatedFare: 100,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(buildTestWidget(mockController));

      expect(find.byType(RideHistoryCard), findsOneWidget);
      expect(find.text('₹100'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });
}
