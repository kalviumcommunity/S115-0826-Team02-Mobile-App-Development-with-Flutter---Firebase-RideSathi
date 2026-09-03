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

/// Baseline User data model for RideSathi.
class UserModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final UserRole role;
  final bool isUnionVerified;
  final String? vehicleInfo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.role,
    this.isUnionVerified = false,
    this.vehicleInfo,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role.name,
      'isUnionVerified': isUnionVerified,
      'vehicleInfo': vehicleInfo,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final roleString = map['role'] as String?;
    final parsedRole = UserRole.tryParse(roleString);

    if (parsedRole == null) {
      throw FormatException('Invalid or unrecognized user role: "$roleString"');
    }

    return UserModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      email: map['email'] as String?,
      role: parsedRole,
      isUnionVerified: map['isUnionVerified'] as bool? ?? false,
      vehicleInfo: map['vehicleInfo'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }
}
