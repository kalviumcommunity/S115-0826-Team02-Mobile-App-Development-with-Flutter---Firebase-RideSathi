/// Represents the status of a ride request.
enum RideStatus {
  requested,
  accepted,
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
  final String pickupAddress;
  final String dropoffAddress;
  final VehicleType vehicleType;
  final RideStatus status;
  final double estimatedFare;
  final DateTime createdAt;

  const RideModel({
    required this.id,
    required this.riderId,
    this.driverId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.vehicleType,
    required this.status,
    required this.estimatedFare,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'riderId': riderId,
      'driverId': driverId,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'vehicleType': vehicleType.name,
      'status': status.name,
      'estimatedFare': estimatedFare,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RideModel.fromMap(Map<String, dynamic> map) {
    return RideModel(
      id: map['id'] as String? ?? '',
      riderId: map['riderId'] as String? ?? '',
      driverId: map['driverId'] as String?,
      pickupAddress: map['pickupAddress'] as String? ?? '',
      dropoffAddress: map['dropoffAddress'] as String? ?? '',
      vehicleType: VehicleType.values.firstWhere(
        (v) => v.name == map['vehicleType'],
        orElse: () => VehicleType.autoRickshaw,
      ),
      status: RideStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => RideStatus.requested,
      ),
      estimatedFare: (map['estimatedFare'] as num? ?? 0.0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
