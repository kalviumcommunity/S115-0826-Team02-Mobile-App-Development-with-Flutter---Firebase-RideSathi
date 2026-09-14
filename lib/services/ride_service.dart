import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_location.dart';
import '../models/ride_model.dart';
import '../models/ride_request_draft.dart';
import 'firestore_exception.dart';

/// Service handling Firestore persistence for Ride operations.
class RideService {
  final FirebaseFirestore _firestore;

  RideService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rides =>
      _firestore.collection('rides');

  /// Creates and persists a new ride request based on the [draft].
  /// 
  /// The [riderId] must be the currently authenticated user's ID.
  /// Throws a [FirestoreException] on failure.
  Future<RideModel> createRideRequest(RideRequestDraft draft, String riderId) async {
    if (!draft.isComplete) {
      throw const FirestoreException('Incomplete ride request data.');
    }

    try {
      final docRef = _rides.doc(); // Generate new unique ID
      
      final rideToSave = RideModel(
        id: docRef.id,
        riderId: riderId,
        pickup: draft.pickup!,
        destination: draft.destination!,
        vehicleType: VehicleType.autoRickshaw, // Default for now
        status: RideStatus.requested,
        estimatedFare: 150.0, // Default for now
        createdAt: DateTime.now(), // Will be overridden by serverTimestamp in toMap
        updatedAt: DateTime.now(),
      );

      await docRef.set(rideToSave.toMap());

      return rideToSave;
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  /// Observes a specific ride document in real-time.
  /// 
  /// Yields `null` if the document does not exist.
  /// Throws a [FirestoreException] on stream failure.
  Stream<RideModel?> watchRide(String rideId) {
    if (rideId.trim().isEmpty) {
      return Stream.error(const FirestoreException('Invalid ride ID.'));
    }

    try {
      return _rides.doc(rideId).snapshots().map((snapshot) {
        if (!snapshot.exists) {
          return null;
        }
        
        final data = snapshot.data();
        if (data == null) {
          return null;
        }
        
        try {
          return RideModel.fromMap(data, snapshot.id);
        } catch (e) {
          throw FirestoreException('Malformed ride data.');
        }
      }).handleError((error) {
        throw FirestoreException.from(error);
      });
    } catch (e) {
      return Stream.error(FirestoreException.from(e));
    }
  }

  /// Updates the driver's location for an active ride.
  /// 
  /// The [driverId] must match the currently authenticated user's ID to enforce ownership.
  /// Throws a [FirestoreException] on failure.
  Future<void> updateDriverLocation(String rideId, DriverLocation location, String driverId) async {
    if (rideId.trim().isEmpty) {
      throw ArgumentError('Ride ID cannot be empty.');
    }
    if (driverId.trim().isEmpty) {
      throw ArgumentError('Driver ID cannot be empty.');
    }
    if (!location.isValid) {
      throw ArgumentError('Invalid location coordinates.');
    }

    try {
      final docRef = _rides.doc(rideId.trim());
      
      // Ownership validation: We conditionally update only if the driverId matches.
      // Since we don't have backend security rules yet, we will fetch and verify client-side.
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        throw const FirestoreException('Ride not found.', code: 'not-found');
      }

      final data = snapshot.data();
      if (data?['driverId'] != driverId) {
        throw const FirestoreException('Unauthorized to update location for this ride.', code: 'permission-denied');
      }

      // Update the driverLocation field
      await docRef.update({
        'driverLocation': location.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException.from(e);
    }
  }

  /// Cancels an active ride request on behalf of the rider.
  /// 
  /// The [riderId] must match the currently authenticated user's ID to enforce ownership.
  /// Cannot cancel rides that are already in a terminal state (completed or cancelled).
  /// Throws a [FirestoreException] on failure.
  Future<void> cancelRide(String rideId, String riderId) async {
    if (rideId.trim().isEmpty) {
      throw ArgumentError('Ride ID cannot be empty.');
    }
    if (riderId.trim().isEmpty) {
      throw ArgumentError('Rider ID cannot be empty.');
    }

    try {
      final docRef = _rides.doc(rideId.trim());
      
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        throw const FirestoreException('Ride not found.', code: 'not-found');
      }

      final data = snapshot.data();
      if (data?['riderId'] != riderId) {
        throw const FirestoreException('Unauthorized to cancel this ride.', code: 'permission-denied');
      }

      final currentStatusStr = data?['status'] as String?;
      if (currentStatusStr == RideStatus.completed.name || currentStatusStr == RideStatus.cancelled.name) {
        throw const FirestoreException('Cannot cancel a ride that is already completed or cancelled.', code: 'invalid-state');
      }

      await docRef.update({
        'status': RideStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException.from(e);
    }
  }
  /// Retrieves the history of rides for the specified rider.
  /// 
  /// The [riderId] must match the currently authenticated user's ID to enforce ownership.
  /// Results are ordered by `createdAt` descending, with a default [limit] of 20.
  /// This query requires a Firestore composite index on `riderId` (ASC) and `createdAt` (DESC).
  /// Throws a [FirestoreException] on failure.
  Future<List<RideModel>> getRiderRideHistory(String riderId, {int limit = 20}) async {
    if (riderId.trim().isEmpty) {
      throw ArgumentError('Rider ID cannot be empty.');
    }

    try {
      final querySnapshot = await _rides
          .where('riderId', isEqualTo: riderId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final List<RideModel> history = [];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data == null) continue;

        try {
          history.add(RideModel.fromMap(data, doc.id));
        } catch (e) {
          // Gracefully skip malformed records so they don't break the entire history view
          continue;
        }
      }

      return history;
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  /// Atomically accepts a ride request on behalf of a driver.
  /// 
  /// The [driverId] must match the currently authenticated driver's ID.
  /// Throws a [FirestoreException] if the ride doesn't exist, is already accepted,
  /// or belongs to someone else.
  Future<void> acceptRide(String rideId, String driverId) async {
    if (rideId.trim().isEmpty) {
      throw ArgumentError('Ride ID cannot be empty.');
    }
    if (driverId.trim().isEmpty) {
      throw ArgumentError('Driver ID cannot be empty.');
    }

    try {
      final docRef = _rides.doc(rideId.trim());

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw const FirestoreException('Ride not found.', code: 'not-found');
        }

        final data = snapshot.data();
        if (data == null) {
          throw const FirestoreException('Ride data is corrupted.', code: 'data-corrupted');
        }

        // Validate Ownership constraint: if there is an assigned driver, it must match.
        final assignedDriverId = data['driverId'];
        if (assignedDriverId != null && assignedDriverId != driverId) {
          throw const FirestoreException('Unauthorized to accept this ride.', code: 'permission-denied');
        }

        // Validate Status transition: only 'requested' is allowed.
        final currentStatusStr = data['status'] as String?;
        if (currentStatusStr != RideStatus.requested.name) {
          if (currentStatusStr == RideStatus.cancelled.name) {
             throw const FirestoreException('This ride has been cancelled by the rider.', code: 'invalid-state');
          } else {
             throw const FirestoreException('This ride is no longer available.', code: 'invalid-state');
          }
        }

        // Perform the atomic update
        transaction.update(docRef, {
          'status': RideStatus.accepted.name,
          'driverId': driverId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException.from(e);
    }
  }

  /// Observes incoming ride requests explicitly assigned to the specified [driverId] in real-time.
  /// 
  /// Streams rides where `driverId == driverId` and `status == 'requested'`.
  /// The [driverId] must be non-empty.
  /// Malformed documents are safely skipped.
  /// Throws a [FirestoreException] on stream failure.
  Stream<List<RideModel>> watchIncomingRideRequests(String driverId) {
    if (driverId.trim().isEmpty) {
      return Stream.error(const FirestoreException('Invalid driver ID.'));
    }

    try {
      return _rides
          .where('driverId', isEqualTo: driverId.trim())
          .where('status', isEqualTo: RideStatus.requested.name)
          .snapshots()
          .map((snapshot) {
        final List<RideModel> requests = [];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data == null) continue;
          try {
            final ride = RideModel.fromMap(data, doc.id);
            // Strict check on status to prevent malformed status fallback from making an invalid document actionable
            if (ride.status == RideStatus.requested && data['status'] == RideStatus.requested.name) {
              requests.add(ride);
            }
          } catch (_) {
            // Gracefully skip malformed document
            continue;
          }
        }
        return requests;
      }).handleError((error) {
        throw FirestoreException.from(error);
      });
    } catch (e) {
      return Stream.error(FirestoreException.from(e));
    }
  }
}
