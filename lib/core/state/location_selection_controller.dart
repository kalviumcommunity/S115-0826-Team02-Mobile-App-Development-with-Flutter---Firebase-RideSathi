import 'package:flutter/foundation.dart';
import '../../models/location_model.dart';
import '../../models/ride_request_draft.dart';

/// Manages the state for selecting pickup and destination locations.
class LocationSelectionController extends ChangeNotifier {
  RideRequestDraft _draft = const RideRequestDraft();

  RideRequestDraft get draft => _draft;

  LocationModel? get pickup => _draft.pickup;
  LocationModel? get destination => _draft.destination;

  /// Sets the pickup location.
  void setPickup(LocationModel location) {
    _draft = _draft.copyWith(pickup: location);
    notifyListeners();
  }

  /// Sets the destination location.
  void setDestination(LocationModel location) {
    _draft = _draft.copyWith(destination: location);
    notifyListeners();
  }

  /// Sets the calculated route info.
  void setRouteInfo({
    required double fare,
    required double distanceMeters,
    required double durationSeconds,
  }) {
    _draft = _draft.copyWith(
      estimatedFare: fare,
      routeDistanceMeters: distanceMeters,
      routeDurationSeconds: durationSeconds,
    );
    notifyListeners();
  }

  /// Clears the pickup location.
  void clearPickup() {
    _draft = _draft.copyWith(clearPickup: true);
    notifyListeners();
  }

  /// Clears the destination location.
  void clearDestination() {
    _draft = _draft.copyWith(clearDestination: true);
    notifyListeners();
  }

  /// Clears the entire draft (e.g. on logout or aborting the flow).
  void clear() {
    _draft = const RideRequestDraft();
    notifyListeners();
  }

  /// Validates the current draft.
  /// Returns an error message if invalid, or null if valid.
  String? validate() {
    if (_draft.pickup == null) {
      return 'Please select a pickup location.';
    }
    if (_draft.destination == null) {
      return 'Please select a destination.';
    }
    if (_draft.hasIdenticalLocations) {
      return 'Pickup and destination cannot be the same.';
    }
    return null;
  }
}
