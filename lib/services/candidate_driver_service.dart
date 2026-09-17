
import '../models/candidate_evaluation.dart';
import '../models/driver_operational_data.dart';
import '../models/ride_model.dart';
import 'driver_data_service.dart';

/// Pure service responsible for deterministic candidate driver eligibility.
///
/// Filters the real-time stream of online drivers from [DriverDataService]
/// against strict business rules for a specific ride request.
class CandidateDriverService {
  final DriverDataService _driverDataService;

  CandidateDriverService({
    DriverDataService? driverDataService,
  }) : _driverDataService = driverDataService ?? DriverDataService();

  /// Streams a list of [CandidateEvaluation] for the given [ride].
  ///
  /// This reuses the underlying real-time [DriverDataService] stream.
  /// Does NOT introduce any new N+1 Firestore queries.
  Stream<List<CandidateEvaluation>> watchCandidatesForRide(RideModel ride) {
    // If the ride is no longer in a requested state, it shouldn't produce candidates.
    // However, to allow the UI to drain gracefully, if a ride is passed that is
    // completed/cancelled, we yield an empty list.
    if (ride.status == RideStatus.completed || ride.status == RideStatus.cancelled || ride.status == RideStatus.rejected) {
      return Stream.value([]);
    }

    return _driverDataService.watchOnlineDriversData().map((drivers) {
      return drivers.map((driver) => evaluateCandidate(driver, ride)).toList();
    });
  }

  /// Evaluates a single [DriverOperationalData] against the given [ride].
  ///
  /// The resulting [CandidateEvaluation] includes the explicit exclusion reason
  /// if the driver is ineligible.
  CandidateEvaluation evaluateCandidate(DriverOperationalData driver, RideModel ride) {
    // Rule 1: Driver must be online.
    if (!driver.isOnline) {
      return CandidateEvaluation(
        driver: driver,
        isEligible: false,
        exclusionReason: 'OFFLINE',
      );
    }

    // Rule 2: Driver must NOT have an active operational ride.
    if (driver.activeRideId != null) {
      return CandidateEvaluation(
        driver: driver,
        isEligible: false,
        exclusionReason: 'ACTIVE_RIDE',
      );
    }

    // Rule 3: Driver MUST have a valid location.
    // Since PR 41 calculates distance, drivers without locations are unmatchable.
    if (!driver.hasLocation) {
      return CandidateEvaluation(
        driver: driver,
        isEligible: false,
        exclusionReason: 'NO_LOCATION',
      );
    }

    // Rule 4: Verification Check.
    // Per the PR 40 requirements, verification is preserved as metadata.
    // We DO NOT exclude unverified drivers at this step.
    
    // Rule 5: Vehicle Type Compatibility.
    // Per PR 40 requirements, brittle substring vehicle matching is avoided.
    // We preserve the vehicle information as metadata.

    // If all hard constraints pass, the driver is eligible.
    return CandidateEvaluation(
      driver: driver,
      isEligible: true,
    );
  }
}
