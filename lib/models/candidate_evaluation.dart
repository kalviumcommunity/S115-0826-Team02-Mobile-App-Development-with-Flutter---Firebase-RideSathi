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

  const CandidateEvaluation({
    required this.driver,
    required this.isEligible,
    this.exclusionReason,
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
        other.exclusionReason == exclusionReason;
  }

  @override
  int get hashCode => Object.hash(driver, isEligible, exclusionReason);
}
