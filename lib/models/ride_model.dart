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
  timedOut,
}

/// Represents the vehicle type in regional cab/auto union.
enum VehicleType {
  autoRickshaw,
  cabSedan,
  cabHatchback,
  cabSUV,
}

/// Represents feedback left by a rider.
class RideFeedback {
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  const RideFeedback({
    required this.rating,
    this.comment,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'rating': rating,
      if (comment != null) 'comment': comment,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      // note: typically the service layer injects FieldValue.serverTimestamp() during writes.
    };
  }

  factory RideFeedback.fromMap(Map<String, dynamic> map) {
    final createVal = map['createdAt'];
    return RideFeedback(
      rating: map['rating'] as int? ?? 5,
      comment: map['comment'] as String?,
      createdAt: createVal is Timestamp ? createVal.toDate() : null,
    );
  }
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
  final RideFeedback? feedback;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RideModel({
    required this.id,
    required this.riderId,
    this.driverId,
    this.driverLocation,
    required this.pickup,
    required this.destination,
    required this.vehicleType,
    this.status = RideStatus.requested,
    required this.estimatedFare,
    this.feedback,
    this.createdAt,
    this.updatedAt,
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
      if (feedback != null) 'feedback': feedback!.toMap(),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
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
      feedback: map['feedback'] != null
          ? RideFeedback.fromMap(map['feedback'] as Map<String, dynamic>)
          : null,
      createdAt: createVal is Timestamp ? createVal.toDate() : null,
      updatedAt: updateVal is Timestamp ? updateVal.toDate() : null,
    );
  }
}
