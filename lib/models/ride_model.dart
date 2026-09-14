import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_location.dart';
import 'location_model.dart';

/// Represents the status of a ride request.
enum RideStatus {
  requested,
  accepted,
  rejected,
  arrived,
  inProgress,
  completed,
  cancelled,
}

/// Represents the vehicle type in regional cab/auto union.
enum VehicleType {
  autoRickshaw,
  cabSedan,
  cabHatchback,
  cabSUV,
}

/// Baseline Ride request data model for RideSathi.
class RideModel {
  final String id;
  final String riderId;
  final String? driverId;
  final DriverLocation? driverLocation;
  final LocationModel pickup;
  final LocationModel destination;
  final VehicleType vehicleType;
  final RideStatus status;
  final double estimatedFare;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RideModel({
    required this.id,
    required this.riderId,
    this.driverId,
    this.driverLocation,
    required this.pickup,
    required this.destination,
    required this.vehicleType,
    required this.status,
    required this.estimatedFare,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'riderId': riderId,
      'driverId': driverId,
      if (driverLocation != null) 'driverLocation': driverLocation!.toMap(),
      'pickup': pickup.toMap(),
      'destination': destination.toMap(),
      'vehicleType': vehicleType.name,
      'status': status.name,
      'estimatedFare': estimatedFare,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory RideModel.fromMap(Map<String, dynamic> map, [String? idOverride]) {
    final createVal = map['createdAt'];
    final updateVal = map['updatedAt'];

    return RideModel(
      id: idOverride ?? map['id'] as String? ?? '',
      riderId: map['riderId'] as String? ?? '',
      driverId: map['driverId'] as String?,
      driverLocation: map['driverLocation'] != null
          ? DriverLocation.fromMap(map['driverLocation'] as Map<String, dynamic>)
          : null,
      pickup: LocationModel.fromMap(map['pickup'] as Map<String, dynamic>? ?? {}),
      destination: LocationModel.fromMap(map['destination'] as Map<String, dynamic>? ?? {}),
      vehicleType: VehicleType.values.firstWhere(
        (v) => v.name == map['vehicleType'],
        orElse: () => VehicleType.autoRickshaw,
      ),
      status: RideStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => RideStatus.requested,
      ),
      estimatedFare: (map['estimatedFare'] as num? ?? 0.0).toDouble(),
      createdAt: createVal is Timestamp ? createVal.toDate() : DateTime.now(),
      updatedAt: updateVal is Timestamp ? updateVal.toDate() : DateTime.now(),
    );
  }
}
