import '../models/ride_model.dart';
import '../utils/clock.dart';

/// Pure domain service responsible for determining if a ride request has timed out.
/// 
/// Does not mutate state or interact with Firestore.
class RideRequestTimeoutService {
  const RideRequestTimeoutService();

  /// Determines if the given [ride] has exceeded the configured [timeout].
  ///
  /// Returns `true` if:
  /// - The ride status is strictly `requested`.
  /// - The time elapsed since `createdAt` is greater than or equal to [timeout].
  /// 
  /// Returns `false` if:
  /// - The ride is already in another state (e.g., accepted, timedOut, cancelled).
  /// - The ride has not yet exceeded the timeout.
  bool isEligibleForTimeout(
    RideModel ride, {
    required Duration timeout,
    required Clock clock,
  }) {
    if (ride.status != RideStatus.requested) {
      return false;
    }

    final now = clock.now();
    final elapsed = now.difference(ride.createdAt);

    return elapsed >= timeout;
  }
}
