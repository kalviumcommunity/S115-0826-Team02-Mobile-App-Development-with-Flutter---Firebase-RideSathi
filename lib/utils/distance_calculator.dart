import 'dart:math' as math;

/// A pure utility for geographic distance calculations.
///
/// Contains no dependencies on external APIs, Firebase, or UI state.
class DistanceCalculator {
  /// The approximate radius of the Earth in kilometers.
  static const double earthRadiusKm = 6371.0;

  /// Calculates the straight-line (Haversine) geographic distance between two
  /// coordinate pairs in kilometers.
  ///
  /// Returns 0.0 if the coordinates are identical.
  /// Throws [ArgumentError] if any coordinate is invalid (NaN, Infinity, or out of bounds).
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    _validateCoordinates(lat1, lon1);
    _validateCoordinates(lat2, lon2);

    if (lat1 == lat2 && lon1 == lon2) {
      return 0.0;
    }

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static void _validateCoordinates(double lat, double lon) {
    if (lat.isNaN || lat.isInfinite || lat < -90 || lat > 90) {
      throw ArgumentError.value(lat, 'latitude', 'Invalid latitude.');
    }
    if (lon.isNaN || lon.isInfinite || lon < -180 || lon > 180) {
      throw ArgumentError.value(lon, 'longitude', 'Invalid longitude.');
    }
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
