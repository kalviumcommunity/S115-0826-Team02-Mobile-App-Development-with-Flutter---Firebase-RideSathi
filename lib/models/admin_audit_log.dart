import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of admin actions recorded in the audit log.
enum AdminAction {
  adminLogin,
  driverVerified,
  driverRejected,
  driverSuspended,
  driverReactivated,
  rideAssigned,
  rideReassigned,
  rideCancelled,
  settingChanged,
  riderSuspended,
  riderReactivated;

  String get displayName {
    switch (this) {
      case adminLogin: return 'Admin Login';
      case driverVerified: return 'Driver Verified';
      case driverRejected: return 'Driver Rejected';
      case driverSuspended: return 'Driver Suspended';
      case driverReactivated: return 'Driver Reactivated';
      case rideAssigned: return 'Ride Assigned';
      case rideReassigned: return 'Ride Reassigned';
      case rideCancelled: return 'Ride Cancelled';
      case settingChanged: return 'Setting Changed';
      case riderSuspended: return 'Rider Suspended';
      case riderReactivated: return 'Rider Reactivated';
    }
  }
}

/// Target entity type for audit log entries.
enum AuditTargetType { driver, rider, ride, setting, system }

/// Immutable audit log record for high-impact admin actions.
class AdminAuditLog {
  final String id;
  final String adminId;
  final AdminAction action;
  final AuditTargetType targetType;
  final String targetId;
  final DateTime timestamp;
  final String? reason;
  final Map<String, dynamic>? previousState;
  final Map<String, dynamic>? newState;

  const AdminAuditLog({
    required this.id,
    required this.adminId,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.timestamp,
    this.reason,
    this.previousState,
    this.newState,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'adminId': adminId,
    'action': action.name,
    'targetType': targetType.name,
    'targetId': targetId,
    'timestamp': Timestamp.fromDate(timestamp),
    if (reason != null) 'reason': reason,
    if (previousState != null) 'previousState': previousState,
    if (newState != null) 'newState': newState,
  };

  factory AdminAuditLog.fromMap(Map<String, dynamic> map, String id) {
    final ts = map['timestamp'];
    return AdminAuditLog(
      id: id,
      adminId: map['adminId'] as String? ?? '',
      action: AdminAction.values.firstWhere(
        (a) => a.name == map['action'],
        orElse: () => AdminAction.adminLogin,
      ),
      targetType: AuditTargetType.values.firstWhere(
        (t) => t.name == map['targetType'],
        orElse: () => AuditTargetType.system,
      ),
      targetId: map['targetId'] as String? ?? '',
      timestamp: ts is Timestamp ? ts.toDate() : DateTime.now(),
      reason: map['reason'] as String?,
      previousState: map['previousState'] as Map<String, dynamic>?,
      newState: map['newState'] as Map<String, dynamic>?,
    );
  }
}
