/// Platform-wide operational settings stored in Firestore under systemSettings/config.
class SystemSettings {
  final int rideRequestTimeoutSeconds;
  final double matchingRadiusKm;
  final int maxCandidateCount;
  final int cancellationWindowSeconds;

  const SystemSettings({
    this.rideRequestTimeoutSeconds = 120,
    this.matchingRadiusKm = 5.0,
    this.maxCandidateCount = 5,
    this.cancellationWindowSeconds = 300,
  });

  static const SystemSettings defaults = SystemSettings();

  Map<String, dynamic> toMap() => {
    'rideRequestTimeoutSeconds': rideRequestTimeoutSeconds,
    'matchingRadiusKm': matchingRadiusKm,
    'maxCandidateCount': maxCandidateCount,
    'cancellationWindowSeconds': cancellationWindowSeconds,
  };

  factory SystemSettings.fromMap(Map<String, dynamic> map) => SystemSettings(
    rideRequestTimeoutSeconds: (map['rideRequestTimeoutSeconds'] as num?)?.toInt() ?? 120,
    matchingRadiusKm: (map['matchingRadiusKm'] as num?)?.toDouble() ?? 5.0,
    maxCandidateCount: (map['maxCandidateCount'] as num?)?.toInt() ?? 5,
    cancellationWindowSeconds: (map['cancellationWindowSeconds'] as num?)?.toInt() ?? 300,
  );

  SystemSettings copyWith({
    int? rideRequestTimeoutSeconds,
    double? matchingRadiusKm,
    int? maxCandidateCount,
    int? cancellationWindowSeconds,
  }) => SystemSettings(
    rideRequestTimeoutSeconds: rideRequestTimeoutSeconds ?? this.rideRequestTimeoutSeconds,
    matchingRadiusKm: matchingRadiusKm ?? this.matchingRadiusKm,
    maxCandidateCount: maxCandidateCount ?? this.maxCandidateCount,
    cancellationWindowSeconds: cancellationWindowSeconds ?? this.cancellationWindowSeconds,
  );
}
