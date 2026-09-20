import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_audit_log.dart';
import '../models/ride_model.dart';
import '../models/system_settings.dart';
import '../models/user_model.dart';
import 'firestore_exception.dart';

/// Central service for all admin Firestore operations.
///
/// Every mutating method:
/// 1. Validates the current state
/// 2. Performs the operation (using transactions where concurrency matters)
/// 3. Writes an audit log entry atomically
///
/// Security is enforced server-side via Firestore rules (isAdmin() function).
/// The client checks role, but the backend is the authoritative gate.
class AdminService {
  final FirebaseFirestore _db;

  AdminService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ─── Collections ──────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _rides => _db.collection('rides');
  CollectionReference<Map<String, dynamic>> get _auditLogs => _db.collection('adminAuditLogs');
  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      _db.collection('systemSettings').doc('config');

  // ─── Real-time Streams ─────────────────────────────────────────────────────

  /// Stream of all drivers (real-time).
  Stream<List<UserModel>> watchAllDrivers() {
    return _users
        .where('role', isEqualTo: 'driver')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => _parseUser(d.data(), d.id))
            .whereType<UserModel>()
            .toList());
  }

  /// Stream of all riders (real-time).
  Stream<List<UserModel>> watchAllRiders() {
    return _users
        .where('role', isEqualTo: 'rider')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => _parseUser(d.data(), d.id))
            .whereType<UserModel>()
            .toList());
  }

  /// Stream of all rides (real-time), optionally filtered by status.
  Stream<List<RideModel>> watchAllRides({RideStatus? filterStatus}) {
    Query<Map<String, dynamic>> q = _rides;
    if (filterStatus != null) {
      q = q.where('status', isEqualTo: filterStatus.name);
    }
    return q.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => _parseRide(d.data(), d.id))
          .whereType<RideModel>()
          .toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  /// Stream of actively running rides (accepted, arrived, inProgress).
  Stream<List<RideModel>> watchActiveRides() {
    return _rides
        .where('status', whereIn: [
          RideStatus.accepted.name,
          RideStatus.arrived.name,
          RideStatus.inProgress.name,
        ])
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => _parseRide(d.data(), d.id))
              .whereType<RideModel>()
              .toList();
          list.sort((a, b) => (a.updatedAt ?? DateTime.now()).compareTo(b.updatedAt ?? DateTime.now()));
          return list;
        });
  }

  /// Stream of pending (requested) rides.
  Stream<List<RideModel>> watchPendingRides() {
    return _rides
        .where('status', isEqualTo: RideStatus.requested.name)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => _parseRide(d.data(), d.id))
              .whereType<RideModel>()
              .toList();
          list.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
          return list;
        });
  }

  // ─── Dashboard Metrics ─────────────────────────────────────────────────────

  /// Returns a snapshot of platform-wide counts for the dashboard.
  Future<Map<String, int>> getDashboardCounts() async {
    try {
      final results = await Future.wait([
        _users.where('role', isEqualTo: 'rider').count().get(),
        _users.where('role', isEqualTo: 'driver').count().get(),
        _users.where('role', isEqualTo: 'driver').where('isOnline', isEqualTo: true).count().get(),
        _users.where('role', isEqualTo: 'driver').where('isOnline', isEqualTo: false).count().get(),
        _rides.where('status', isEqualTo: RideStatus.requested.name).count().get(),
        _rides.where('status', whereIn: [
          RideStatus.accepted.name,
          RideStatus.arrived.name,
          RideStatus.inProgress.name,
        ]).count().get(),
        _rides.where('status', isEqualTo: RideStatus.completed.name).count().get(),
        _rides.where('status', isEqualTo: RideStatus.cancelled.name).count().get(),
      ]);

      return {
        'totalRiders': results[0].count ?? 0,
        'totalDrivers': results[1].count ?? 0,
        'onlineDrivers': results[2].count ?? 0,
        'offlineDrivers': results[3].count ?? 0,
        'pendingRides': results[4].count ?? 0,
        'activeRides': results[5].count ?? 0,
        'completedRides': results[6].count ?? 0,
        'cancelledRides': results[7].count ?? 0,
      };
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  // ─── Driver Management ─────────────────────────────────────────────────────

  /// Verifies a driver (sets isUnionVerified=true, verificationStatus=verified).
  Future<void> verifyDriver({
    required String driverId,
    required String adminId,
  }) async {
    try {
      final driverRef = _users.doc(driverId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(driverRef);
        if (!snap.exists) throw const FirestoreException('Driver not found.');
        final prev = Map<String, dynamic>.from(snap.data()!);
        tx.update(driverRef, {
          'isUnionVerified': true,
          'verificationStatus': VerificationStatus.verified.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final logRef = _auditLogs.doc();
        tx.set(logRef, _buildAuditMap(
          id: logRef.id,
          adminId: adminId,
          action: AdminAction.driverVerified,
          targetType: AuditTargetType.driver,
          targetId: driverId,
          previousState: {'isUnionVerified': prev['isUnionVerified'], 'verificationStatus': prev['verificationStatus']},
          newState: {'isUnionVerified': true, 'verificationStatus': VerificationStatus.verified.name},
        ));
      });
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  /// Rejects a driver's verification.
  Future<void> rejectDriverVerification({
    required String driverId,
    required String adminId,
    String? reason,
  }) async {
    try {
      final driverRef = _users.doc(driverId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(driverRef);
        if (!snap.exists) throw const FirestoreException('Driver not found.');
        tx.update(driverRef, {
          'isUnionVerified': false,
          'verificationStatus': VerificationStatus.rejected.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final logRef = _auditLogs.doc();
        tx.set(logRef, _buildAuditMap(
          id: logRef.id,
          adminId: adminId,
          action: AdminAction.driverRejected,
          targetType: AuditTargetType.driver,
          targetId: driverId,
          reason: reason,
          newState: {'verificationStatus': VerificationStatus.rejected.name},
        ));
      });
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  /// Suspends a user account (driver or rider).
  Future<void> suspendUser({
    required String userId,
    required String adminId,
    required String reason,
    required bool isDriver,
  }) async {
    try {
      final userRef = _users.doc(userId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        if (!snap.exists) throw const FirestoreException('User not found.');
        tx.update(userRef, {
          'isSuspended': true,
          'suspendedReason': reason,
          'isOnline': false, // Force offline on suspension
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final logRef = _auditLogs.doc();
        tx.set(logRef, _buildAuditMap(
          id: logRef.id,
          adminId: adminId,
          action: isDriver ? AdminAction.driverSuspended : AdminAction.riderSuspended,
          targetType: isDriver ? AuditTargetType.driver : AuditTargetType.rider,
          targetId: userId,
          reason: reason,
          newState: {'isSuspended': true},
        ));
      });
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  /// Reactivates a previously suspended user account.
  Future<void> reactivateUser({
    required String userId,
    required String adminId,
    required bool isDriver,
  }) async {
    try {
      final userRef = _users.doc(userId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        if (!snap.exists) throw const FirestoreException('User not found.');
        tx.update(userRef, {
          'isSuspended': false,
          'suspendedReason': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final logRef = _auditLogs.doc();
        tx.set(logRef, _buildAuditMap(
          id: logRef.id,
          adminId: adminId,
          action: isDriver ? AdminAction.driverReactivated : AdminAction.riderReactivated,
          targetType: isDriver ? AuditTargetType.driver : AuditTargetType.rider,
          targetId: userId,
          newState: {'isSuspended': false},
        ));
      });
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  // ─── Ride Management ───────────────────────────────────────────────────────

  /// Admin cancels a ride with a reason. Prevents cancelling terminal states.
  Future<void> adminCancelRide({
    required String rideId,
    required String adminId,
    required String reason,
  }) async {
    final terminalStatuses = {
      RideStatus.completed.name,
      RideStatus.cancelled.name,
      RideStatus.timedOut.name,
    };
    try {
      final rideRef = _rides.doc(rideId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(rideRef);
        if (!snap.exists) throw const FirestoreException('Ride not found.');
        final data = snap.data()!;
        final currentStatus = data['status'] as String?;
        if (terminalStatuses.contains(currentStatus)) {
          throw FirestoreException('Cannot cancel a ride with status: $currentStatus');
        }
        tx.update(rideRef, {
          'status': RideStatus.cancelled.name,
          'cancellationReason': reason,
          'cancelledByAdmin': true,
          'cancelledByAdminId': adminId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final logRef = _auditLogs.doc();
        tx.set(logRef, _buildAuditMap(
          id: logRef.id,
          adminId: adminId,
          action: AdminAction.rideCancelled,
          targetType: AuditTargetType.ride,
          targetId: rideId,
          reason: reason,
          previousState: {'status': currentStatus},
          newState: {'status': RideStatus.cancelled.name},
        ));
      });
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  /// Admin manually assigns an eligible driver to a ride.
  /// Uses a transaction to prevent race conditions.
  Future<void> adminAssignDriver({
    required String rideId,
    required String driverId,
    required String adminId,
  }) async {
    try {
      final rideRef = _rides.doc(rideId);
      final driverRef = _users.doc(driverId);
      await _db.runTransaction((tx) async {
        final rideSnap = await tx.get(rideRef);
        final driverSnap = await tx.get(driverRef);
        if (!rideSnap.exists) throw const FirestoreException('Ride not found.');
        if (!driverSnap.exists) throw const FirestoreException('Driver not found.');
        final rideData = rideSnap.data()!;
        final driverData = driverSnap.data()!;
        // Guard: only assign to eligible rides
        final allowedStatuses = {RideStatus.requested.name, RideStatus.timedOut.name};
        if (!allowedStatuses.contains(rideData['status'])) {
          throw FirestoreException('Cannot assign driver to ride with status: ${rideData['status']}');
        }
        // Guard: driver must be online and not suspended
        if (driverData['isSuspended'] == true) {
          throw const FirestoreException('Cannot assign a suspended driver.');
        }
        if (driverData['isOnline'] != true) {
          throw const FirestoreException('Cannot assign an offline driver.');
        }
        tx.update(rideRef, {
          'driverId': driverId,
          'status': RideStatus.accepted.name,
          'adminAssigned': true,
          'adminAssignedById': adminId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final logRef = _auditLogs.doc();
        tx.set(logRef, _buildAuditMap(
          id: logRef.id,
          adminId: adminId,
          action: AdminAction.rideAssigned,
          targetType: AuditTargetType.ride,
          targetId: rideId,
          previousState: {'status': rideData['status'], 'driverId': rideData['driverId']},
          newState: {'status': RideStatus.accepted.name, 'driverId': driverId},
        ));
      });
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  /// Admin reassigns a ride from current driver to a new driver.
  Future<void> adminReassignDriver({
    required String rideId,
    required String newDriverId,
    required String adminId,
    String? reason,
  }) async {
    try {
      final rideRef = _rides.doc(rideId);
      final newDriverRef = _users.doc(newDriverId);
      await _db.runTransaction((tx) async {
        final rideSnap = await tx.get(rideRef);
        final driverSnap = await tx.get(newDriverRef);
        if (!rideSnap.exists) throw const FirestoreException('Ride not found.');
        if (!driverSnap.exists) throw const FirestoreException('Driver not found.');
        final rideData = rideSnap.data()!;
        final driverData = driverSnap.data()!;
        final assignableStatuses = {
          RideStatus.requested.name,
          RideStatus.accepted.name,
          RideStatus.arrived.name,
        };
        if (!assignableStatuses.contains(rideData['status'])) {
          throw FirestoreException('Cannot reassign ride with status: ${rideData['status']}');
        }
        if (driverData['isSuspended'] == true) {
          throw const FirestoreException('Cannot assign a suspended driver.');
        }
        if (driverData['isOnline'] != true) {
          throw const FirestoreException('Cannot assign an offline driver.');
        }
        final prevDriverId = rideData['driverId'];
        tx.update(rideRef, {
          'driverId': newDriverId,
          'status': RideStatus.accepted.name,
          'adminReassigned': true,
          'adminReassignedById': adminId,
          'previousDriverId': prevDriverId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final logRef = _auditLogs.doc();
        tx.set(logRef, _buildAuditMap(
          id: logRef.id,
          adminId: adminId,
          action: AdminAction.rideReassigned,
          targetType: AuditTargetType.ride,
          targetId: rideId,
          reason: reason,
          previousState: {'driverId': prevDriverId},
          newState: {'driverId': newDriverId},
        ));
      });
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  // ─── Search ────────────────────────────────────────────────────────────────

  /// Searches users by name prefix (case-sensitive Firestore startsWith trick).
  Future<List<UserModel>> searchUsersByName(String query, {String? role}) async {
    try {
      var q = _users.orderBy('name')
          .startAt([query]).endAt(['$query\uf8ff']);
      if (role != null) q = q.where('role', isEqualTo: role);
      final snap = await q.limit(20).get();
      return snap.docs
          .map((d) => _parseUser(d.data(), d.id))
          .whereType<UserModel>()
          .toList();
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  /// Fetches a paginated list of rides.
  Future<List<RideModel>> getRidesPaginated({
    RideStatus? status,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> q =
          _rides.orderBy('createdAt', descending: true);
      if (status != null) q = q.where('status', isEqualTo: status.name);
      if (startAfter != null) q = q.startAfterDocument(startAfter);
      final snap = await q.limit(limit).get();
      return snap.docs
          .map((d) => _parseRide(d.data(), d.id))
          .whereType<RideModel>()
          .toList();
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  // ─── Audit Logs ────────────────────────────────────────────────────────────

  Future<List<AdminAuditLog>> getAuditLogs({
    int limit = 30,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> q =
          _auditLogs.orderBy('timestamp', descending: true).limit(limit);
      if (startAfter != null) q = q.startAfterDocument(startAfter);
      final snap = await q.get();
      return snap.docs
          .map((d) => AdminAuditLog.fromMap(d.data(), d.id))
          .toList();
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  Stream<List<AdminAuditLog>> watchRecentAuditLogs({int limit = 20}) {
    return _auditLogs
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AdminAuditLog.fromMap(d.data(), d.id)).toList());
  }

  // ─── System Settings ───────────────────────────────────────────────────────

  Future<SystemSettings> getSystemSettings() async {
    try {
      final snap = await _settingsDoc.get();
      if (!snap.exists || snap.data() == null) return SystemSettings.defaults;
      return SystemSettings.fromMap(snap.data()!);
    } catch (e) {
      return SystemSettings.defaults;
    }
  }

  Future<void> updateSystemSettings({
    required SystemSettings settings,
    required String adminId,
    required String changedKey,
    required dynamic previousValue,
    required dynamic newValue,
  }) async {
    try {
      await _settingsDoc.set(settings.toMap(), SetOptions(merge: true));
      await _auditLogs.add(_buildAuditMap(
        id: '',
        adminId: adminId,
        action: AdminAction.settingChanged,
        targetType: AuditTargetType.setting,
        targetId: changedKey,
        previousState: {changedKey: previousValue},
        newState: {changedKey: newValue},
      ));
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  UserModel? _parseUser(Map<String, dynamic> data, String docId) {
    try {
      final map = Map<String, dynamic>.from(data);
      if (!map.containsKey('id') || (map['id'] as String?)?.isEmpty == true) {
        map['id'] = docId;
      }
      return UserModel.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  RideModel? _parseRide(Map<String, dynamic> data, String docId) {
    try {
      return RideModel.fromMap(data, docId);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _buildAuditMap({
    required String id,
    required String adminId,
    required AdminAction action,
    required AuditTargetType targetType,
    required String targetId,
    String? reason,
    Map<String, dynamic>? previousState,
    Map<String, dynamic>? newState,
  }) {
    final map = <String, dynamic>{
      'adminId': adminId,
      'action': action.name,
      'targetType': targetType.name,
      'targetId': targetId,
      'timestamp': FieldValue.serverTimestamp(),
    };
    if (id.isNotEmpty) map['id'] = id;
    if (reason != null) map['reason'] = reason;
    if (previousState != null) map['previousState'] = previousState;
    if (newState != null) map['newState'] = newState;
    return map;
  }
}
