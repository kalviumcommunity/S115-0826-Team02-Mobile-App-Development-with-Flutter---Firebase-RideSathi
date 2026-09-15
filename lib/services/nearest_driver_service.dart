import 'dart:async';
import '../models/candidate_evaluation.dart';
import '../models/ride_model.dart';
import '../utils/distance_calculator.dart';
import 'candidate_driver_service.dart';
import 'service_exception.dart';

/// Pure service responsible for calculating distances and ranking candidate drivers.
///
/// Subscribes to the [CandidateDriverService] and computes deterministic distances
/// to the ride's pickup location without performing any Firestore queries.
class NearestDriverService {
  final CandidateDriverService _candidateDriverService;

  const NearestDriverService({
    CandidateDriverService? candidateDriverService,
  }) : _candidateDriverService = candidateDriverService ?? const CandidateDriverService();

  /// Streams ranked [CandidateEvaluation] results for the given [ride].
  ///
  /// Evaluates only eligible candidates. Computes their geographic distance
  /// from the pickup location and sorts them deterministically.
  /// Throws [ServiceException] if the pickup location is invalid or missing.
  Stream<List<CandidateEvaluation>> watchRankedCandidates(RideModel ride) {
    if (ride.status == RideStatus.completed || ride.status == RideStatus.cancelled || ride.status == RideStatus.rejected) {
      return Stream.value([]);
    }

    // Guard: pickup coordinates are nullable in LocationModel.
    // If either is missing or invalid, we cannot calculate distance.
    final pickupLat = ride.pickup.latitude;
    final pickupLon = ride.pickup.longitude;
    if (pickupLat == null || pickupLon == null) {
      return Stream.error(const ServiceException('Pickup location does not have valid coordinates.'));
    }

    return _candidateDriverService.watchCandidatesForRide(ride).map((evaluations) {
      final ranked = <CandidateEvaluation>[];

      for (final eval in evaluations) {
        if (!eval.isEligible) {
          // Pass through ineligible candidates untouched so the UI can still show them.
          ranked.add(eval);
          continue;
        }

        try {
          final distanceKm = DistanceCalculator.calculateDistanceKm(
            pickupLat,
            pickupLon,
            eval.driver.location!.latitude,
            eval.driver.location!.longitude,
          );
          
          ranked.add(eval.copyWith(distanceKm: distanceKm));
        } catch (e) {
          // If a candidate's coordinates are corrupted in real-time, exclude them defensively.
          ranked.add(
            eval.copyWith(
              isEligible: false,
              exclusionReason: 'INVALID_LOCATION_DATA',
            ),
          );
        }
      }

      // Sort deterministically:
      // 1. Eligible first
      // 2. Nearest first (distanceKm ascending)
      // 3. Tie-breaker: UID ascending
      ranked.sort((a, b) {
        if (a.isEligible && !b.isEligible) return -1;
        if (!a.isEligible && b.isEligible) return 1;

        if (a.isEligible && b.isEligible) {
          // Both are eligible, meaning both have distanceKm
          final distCompare = a.distanceKm!.compareTo(b.distanceKm!);
          if (distCompare != 0) return distCompare;

          // Stable tie-breaker based on driver ID
          return a.driver.id.compareTo(b.driver.id);
        }

        // If neither are eligible, retain default sorting logic (by name or verification)
        // Note: For pure exclusion lists, sorting by name is fine.
        return a.driver.name.toLowerCase().compareTo(b.driver.name.toLowerCase());
      });

      return ranked;
    }).handleError((error) {
      if (error is ArgumentError) {
        throw ServiceException(error.message?.toString() ?? 'Invalid pickup coordinates.');
      }
      throw error;
    });
  }
}
