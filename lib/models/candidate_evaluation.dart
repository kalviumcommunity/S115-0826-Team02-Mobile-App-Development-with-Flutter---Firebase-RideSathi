import 'package:flutter/foundation.dart';
import 'driver_operational_data.dart';

/// Wraps a [DriverOperationalData] model with candidate evaluation results.
///
/// This provides transparency into why a driver was included or excluded
/// from the eligible candidate pool for a specific ride request.
@immutable
class CandidateEvaluation {
  /// The operational driver being evaluated.
  final DriverOperationalData driver;

  /// True if the driver meets all strict eligibility requirements.
  final bool isEligible;

  /// If [isEligible] is false, this provides a deterministic reason for exclusion.
  /// Common reasons: 'OFFLINE', 'ACTIVE_RIDE', 'NO_LOCATION', 'INVALID_DATA'
  final String? exclusionReason;

  /// The straight-line distance to the pickup location in kilometers.
  /// Only available if evaluated for proximity.
  final double? distanceKm;

  const CandidateEvaluation({
    required this.driver,
    required this.isEligible,
    this.exclusionReason,
    this.distanceKm,
  }) : assert(
          isEligible || exclusionReason != null,
          'Excluded candidates must have an exclusion reason.',
        );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CandidateEvaluation &&
        other.driver == driver &&
        other.isEligible == isEligible &&
        other.exclusionReason == exclusionReason &&
        other.distanceKm == distanceKm;
  }

  @override
  int get hashCode => Object.hash(driver, isEligible, exclusionReason, distanceKm);

  CandidateEvaluation copyWith({
    DriverOperationalData? driver,
    bool? isEligible,
    String? exclusionReason,
    double? distanceKm,
  }) {
    return CandidateEvaluation(
      driver: driver ?? this.driver,
      isEligible: isEligible ?? this.isEligible,
      exclusionReason: exclusionReason ?? this.exclusionReason,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
