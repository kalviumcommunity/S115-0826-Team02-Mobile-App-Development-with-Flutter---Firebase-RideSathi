import '../models/ride_model.dart';

/// Service responsible for calculating ride fares based on business rules.
class FareService {
  // Configurable base pricing
  static const double baseFare = 50.0;
  static const double perKmCharge = 12.0;
  static const double perMinuteCharge = 1.5;
  static const double minimumFare = 60.0;

  /// Calculates the estimated fare for a ride based on distance and duration.
  /// 
  /// Uses a standard formula: Base + (Distance * Rate) + (Time * Rate)
  double calculateFare({
    required double distanceMeters,
    required double durationSeconds,
    VehicleType vehicleType = VehicleType.autoRickshaw,
  }) {
    final distanceKm = distanceMeters / 1000.0;
    final durationMinutes = durationSeconds / 60.0;

    double calculatedFare = baseFare + (distanceKm * perKmCharge) + (durationMinutes * perMinuteCharge);

    // Vehicle type multiplier could be added here in the future
    if (vehicleType != VehicleType.autoRickshaw) {
      // Example: if it was a premium car, multiply by 1.5
    }

    if (calculatedFare < minimumFare) {
      return minimumFare;
    }

    return calculatedFare;
  }
}
