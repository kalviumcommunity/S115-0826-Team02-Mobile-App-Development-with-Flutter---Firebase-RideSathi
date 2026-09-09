import 'package:flutter/foundation.dart';

/// Represents a location selected by the user for pickup or destination.
/// 
/// Since no external Maps SDK is integrated in PR 20, coordinates (latitude, longitude)
/// are optional and only populated if reliably obtained.
@immutable
class LocationModel {
  final String id;
  final String displayName;
  final String address;
  final double? latitude;
  final double? longitude;

  const LocationModel({
    required this.id,
    required this.displayName,
    required this.address,
    this.latitude,
    this.longitude,
  });

  /// Creates a new LocationModel with modified fields.
  LocationModel copyWith({
    String? id,
    String? displayName,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return LocationModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.id == id &&
        other.displayName == displayName &&
        other.address == address &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode {
    return Object.hash(id, displayName, address, latitude, longitude);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      id: map['id'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      address: map['address'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
