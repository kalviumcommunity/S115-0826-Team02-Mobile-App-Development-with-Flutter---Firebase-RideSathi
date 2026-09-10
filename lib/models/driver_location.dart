import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Represents a driver's geographical location during an active ride.
@immutable
class DriverLocation {
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  const DriverLocation({
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  })  : assert(latitude >= -90 && latitude <= 90, 'Latitude must be between -90 and 90'),
        assert(longitude >= -180 && longitude <= 180, 'Longitude must be between -180 and 180');

  /// Validates the location fields gracefully returning true if valid.
  bool get isValid {
    if (latitude.isNaN || latitude.isInfinite) return false;
    if (longitude.isNaN || longitude.isInfinite) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverLocation &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.updatedAt.isAtSameMomentAs(updatedAt);
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, updatedAt);

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      // Uses server timestamp to ensure the timestamp reflects the moment it reached the server
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory DriverLocation.fromMap(Map<String, dynamic> map) {
    final lat = (map['latitude'] as num?)?.toDouble() ?? 0.0;
    final lon = (map['longitude'] as num?)?.toDouble() ?? 0.0;
    
    final updateVal = map['updatedAt'];
    final time = updateVal is Timestamp ? updateVal.toDate() : DateTime.now();

    return DriverLocation(
      latitude: lat,
      longitude: lon,
      updatedAt: time,
    );
  }
}
