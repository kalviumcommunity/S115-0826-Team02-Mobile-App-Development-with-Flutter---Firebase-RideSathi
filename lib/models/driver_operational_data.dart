import 'package:flutter/foundation.dart';
import 'driver_location.dart';

/// Represents the real-time operational data of a driver for dispatch purposes.
/// 
/// This model aggregates profile/availability data (from the `users` collection)
/// with real-time location data (from the driver's active operational ride in the `rides` collection).
@immutable
class DriverOperationalData {
  final String id;
  final String name;
  final String phoneNumber;
  final String? vehicleInfo;
  final bool isUnionVerified;
  final bool isOnline;
  final DateTime? availabilityUpdatedAt;
  final DriverLocation? location;
  final String? activeRideId;

  const DriverOperationalData({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.vehicleInfo,
    required this.isUnionVerified,
    required this.isOnline,
    this.availabilityUpdatedAt,
    this.location,
    this.activeRideId,
  });

  /// True if the driver has a valid active location.
  bool get hasLocation => location != null && location!.isValid;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is DriverOperationalData &&
      other.id == id &&
      other.name == name &&
      other.phoneNumber == phoneNumber &&
      other.vehicleInfo == vehicleInfo &&
      other.isUnionVerified == isUnionVerified &&
      other.isOnline == isOnline &&
      other.availabilityUpdatedAt == availabilityUpdatedAt &&
      other.location == location &&
      other.activeRideId == activeRideId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      phoneNumber,
      vehicleInfo,
      isUnionVerified,
      isOnline,
      availabilityUpdatedAt,
      location,
      activeRideId,
    );
  }

  DriverOperationalData copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? vehicleInfo,
    bool? isUnionVerified,
    bool? isOnline,
    DateTime? availabilityUpdatedAt,
    DriverLocation? location,
    String? activeRideId,
  }) {
    return DriverOperationalData(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      isUnionVerified: isUnionVerified ?? this.isUnionVerified,
      isOnline: isOnline ?? this.isOnline,
      availabilityUpdatedAt: availabilityUpdatedAt ?? this.availabilityUpdatedAt,
      location: location ?? this.location,
      activeRideId: activeRideId ?? this.activeRideId,
    );
  }
}
