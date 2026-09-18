import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the user role within the RideSathi ecosystem.
enum UserRole {
  rider,
  driver,
  dispatcher,
  admin;

  /// Safely parses a [String] value into a [UserRole].
  /// Returns `null` if the value does not match any recognized role.
  static UserRole? tryParse(String? value) {
    if (value == null) return null;
    for (final role in UserRole.values) {
      if (role.name == value) return role;
    }
    return null;
  }

  /// Whether the given [value] is a valid recognized role name.
  static bool isValid(String? value) => tryParse(value) != null;
}

/// Verification status for drivers set by admin.
enum VerificationStatus {
  pending,
  verified,
  rejected;

  static VerificationStatus fromString(String? v) =>
      VerificationStatus.values.firstWhere((e) => e.name == v,
          orElse: () => VerificationStatus.pending);
}

/// Baseline User data model for RideSathi.
class UserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final UserRole role;
  final bool isUnionVerified;
  final bool isOnline;
  final String? vehicleInfo;
  final String? profileImageUrl;
  final String? driverDocumentUrl;
  final DateTime? availabilityUpdatedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Admin-managed fields
  final bool isSuspended;
  final String? suspendedReason;
  final VerificationStatus verificationStatus;

  const UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.role,
    this.isUnionVerified = false,
    this.isOnline = false,
    this.vehicleInfo,
    this.profileImageUrl,
    this.driverDocumentUrl,
    this.availabilityUpdatedAt,
    this.createdAt,
    this.updatedAt,
    this.isSuspended = false,
    this.suspendedReason,
    this.verificationStatus = VerificationStatus.pending,
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role.name,
      'isUnionVerified': isUnionVerified,
      'isOnline': isOnline,
      'vehicleInfo': vehicleInfo,
      'profileImageUrl': profileImageUrl,
      'driverDocumentUrl': driverDocumentUrl,
      'isSuspended': isSuspended,
      if (suspendedReason != null) 'suspendedReason': suspendedReason,
      'verificationStatus': verificationStatus.name,
      if (availabilityUpdatedAt != null) 'availabilityUpdatedAt': availabilityUpdatedAt!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final roleString = map['role'] as String?;
    final parsedRole = UserRole.tryParse(roleString);

    if (parsedRole == null) {
      throw FormatException('Invalid or unrecognized user role: "$roleString"');
    }

    final rawVerified = map['isUnionVerified'];
    final bool parsedVerified = rawVerified is bool ? rawVerified : false;

    final rawOnline = map['isOnline'];
    final bool parsedOnline = rawOnline is bool ? rawOnline : false;

    final availVal = map['availabilityUpdatedAt'];
    final createVal = map['createdAt'];
    final updateVal = map['updatedAt'];

    return UserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      email: map['email'] as String?,
      role: parsedRole,
      isUnionVerified: parsedVerified,
      isOnline: parsedOnline,
      vehicleInfo: map['vehicleInfo'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      driverDocumentUrl: map['driverDocumentUrl'] as String?,
      isSuspended: map['isSuspended'] as bool? ?? false,
      suspendedReason: map['suspendedReason'] as String?,
      verificationStatus: VerificationStatus.fromString(map['verificationStatus'] as String?),
      availabilityUpdatedAt: availVal is Timestamp ? availVal.toDate() : (availVal is String ? DateTime.tryParse(availVal) : null),
      createdAt: createVal is Timestamp ? createVal.toDate() : (createVal is String ? DateTime.tryParse(createVal) : null),
      updatedAt: updateVal is Timestamp ? updateVal.toDate() : (updateVal is String ? DateTime.tryParse(updateVal) : null),
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    UserRole? role,
    bool? isUnionVerified,
    bool? isOnline,
    String? vehicleInfo,
    String? profileImageUrl,
    String? driverDocumentUrl,
    DateTime? availabilityUpdatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSuspended,
    String? suspendedReason,
    VerificationStatus? verificationStatus,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      role: role ?? this.role,
      isUnionVerified: isUnionVerified ?? this.isUnionVerified,
      isOnline: isOnline ?? this.isOnline,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      driverDocumentUrl: driverDocumentUrl ?? this.driverDocumentUrl,
      availabilityUpdatedAt: availabilityUpdatedAt ?? this.availabilityUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSuspended: isSuspended ?? this.isSuspended,
      suspendedReason: suspendedReason ?? this.suspendedReason,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }
}
