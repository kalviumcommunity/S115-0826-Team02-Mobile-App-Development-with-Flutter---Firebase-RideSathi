import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/state/automatic_assignment_controller.dart';
import 'package:ridesathi/core/state/fallback_matching_controller.dart';
import 'package:ridesathi/models/candidate_evaluation.dart';
import 'package:ridesathi/models/driver_operational_data.dart';
import 'package:ridesathi/models/matching_attempt_state.dart';
import 'package:ridesathi/services/ride_service.dart';
import 'package:ridesathi/core/state/view_state.dart';

class _FakeFallbackController extends FallbackMatchingController {
  MatchingAttemptState _fakeState = const MatchingAttemptState();
  String? _fakeActiveRideId;

  @override
  ViewState<MatchingAttemptState> get state => ViewState.success(_fakeState);

  String? get activeRideId => _fakeActiveRideId;

  void emitSuccess(MatchingAttemptState newState, String rideId) {
    _fakeActiveRideId = rideId;
    _fakeState = newState;
    notifyListeners();
  }
}

class _FakeRideService extends RideService {
  final List<String> assignedDrivers = [];
  bool shouldFail = false;

  @override
  Future<void> assignRide(String rideId, String driverId) async {
    if (shouldFail) {
      throw Exception('Assignment failed');
    }
    assignedDrivers.add(driverId);
  }
}

void main() {
  late _FakeFallbackController fallbackController;
  late _FakeRideService rideService;
  late AutomaticAssignmentController controller;

  setUp(() {
    fallbackController = _FakeFallbackController();
    rideService = _FakeRideService();
    controller = AutomaticAssignmentController(
      fallbackController: fallbackController,
      rideService: rideService,
    );
  });

  tearDown(() {
    controller.dispose();
    fallbackController.dispose();
  });

  final dummyDriver = const DriverOperationalData(
    id: 'driver1',
    name: 'Driver One',
    phoneNumber: '1234567890',
    isUnionVerified: true,
    isOnline: true,
  );

  final candidate = CandidateEvaluation(
    driver: dummyDriver,
    isEligible: true,
  );

  test('Initiates assignment when candidate is selected', () async {
    controller.setRideId('ride1');
    
    fallbackController.emitSuccess(
      MatchingAttemptState.selected(candidate, [candidate]),
      'ride1',
    );

    // Give microtask queue time to process the async assignment
    await Future.delayed(Duration.zero);

    expect(rideService.assignedDrivers, contains('driver1'));
  });

  test('Does not attempt assignment twice for the same candidate on the same ride', () async {
    controller.setRideId('ride1');
    
    fallbackController.emitSuccess(
      MatchingAttemptState.selected(candidate, [candidate]),
      'ride1',
    );
    await Future.delayed(Duration.zero);
    
    // Emit again
    fallbackController.emitSuccess(
      MatchingAttemptState.selected(candidate, [candidate]),
      'ride1',
    );
    await Future.delayed(Duration.zero);

    expect(rideService.assignedDrivers.length, 1);
  });

  test('Attempts assignment again if candidate changes', () async {
    controller.setRideId('ride1');
    
    fallbackController.emitSuccess(
      MatchingAttemptState.selected(candidate, [candidate]),
      'ride1',
    );
    await Future.delayed(Duration.zero);

    final candidate2 = CandidateEvaluation(
      driver: dummyDriver.copyWith(id: 'driver2'),
      isEligible: true,
    );

    fallbackController.emitSuccess(
      MatchingAttemptState.selected(candidate2, [candidate, candidate2]),
      'ride1',
    );
    await Future.delayed(Duration.zero);

    expect(rideService.assignedDrivers, containsAll(['driver1', 'driver2']));
  });
}
