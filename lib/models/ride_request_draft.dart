import 'package:flutter/foundation.dart';
import 'location_model.dart';

/// Represents a draft state for a ride request.
/// 
/// Holds the selected pickup and destination locations during the 
/// ride request workflow. It is kept local to the flow and not 
/// persisted globally or to Firestore in PR 20.
@immutable
class RideRequestDraft {
  final LocationModel? pickup;
  final LocationModel? destination;
  final double? estimatedFare;
  final double? routeDistanceMeters;
  final double? routeDurationSeconds;

  const RideRequestDraft({
    this.pickup,
    this.destination,
    this.estimatedFare,
    this.routeDistanceMeters,
    this.routeDurationSeconds,
  });

  /// True if both pickup and destination are selected.
  bool get isComplete => pickup != null && destination != null;

  /// True if pickup and destination are the same location.
  bool get hasIdenticalLocations {
    if (!isComplete) return false;
    return pickup!.id == destination!.id;
  }

  /// Creates a new draft with updated fields.
  RideRequestDraft copyWith({
    LocationModel? pickup,
    LocationModel? destination,
    double? estimatedFare,
    double? routeDistanceMeters,
    double? routeDurationSeconds,
    bool clearPickup = false,
    bool clearDestination = false,
  }) {
    return RideRequestDraft(
      pickup: clearPickup ? null : (pickup ?? this.pickup),
      destination: clearDestination ? null : (destination ?? this.destination),
      estimatedFare: estimatedFare ?? this.estimatedFare,
      routeDistanceMeters: routeDistanceMeters ?? this.routeDistanceMeters,
      routeDurationSeconds: routeDurationSeconds ?? this.routeDurationSeconds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RideRequestDraft &&
        other.pickup == pickup &&
        other.destination == destination &&
        other.estimatedFare == estimatedFare &&
        other.routeDistanceMeters == routeDistanceMeters &&
        other.routeDurationSeconds == routeDurationSeconds;
  }

  @override
  int get hashCode => Object.hash(pickup, destination, estimatedFare, routeDistanceMeters, routeDurationSeconds);
}
