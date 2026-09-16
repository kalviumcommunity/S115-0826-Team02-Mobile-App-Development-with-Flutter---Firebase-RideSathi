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

  /// Atomically rejects an incoming ride request on behalf of a driver.
  /// 
  /// The [driverId] must match the currently authenticated driver's ID.
  /// Throws a [FirestoreException] if the ride doesn't exist, is no longer requested,
  /// or is not assigned to this driver.
  Future<void> rejectRide(String rideId, String driverId) async {
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
        // For rejection, we only allow drivers explicitly assigned to reject it.
        final assignedDriverId = data['driverId'];
        if (assignedDriverId != driverId) {
          throw const FirestoreException('Unauthorized to reject this ride. Not assigned to you.', code: 'permission-denied');
        }

        // Validate Status transition: only 'requested' is allowed.
        final currentStatusStr = data['status'] as String?;
        if (currentStatusStr != RideStatus.requested.name) {
          if (currentStatusStr == RideStatus.cancelled.name) {
             throw const FirestoreException('This ride has been cancelled by the rider.', code: 'invalid-state');
          } else {
             throw const FirestoreException('This ride is no longer in a requested state.', code: 'invalid-state');
          }
        }

        // Perform the atomic update
        transaction.update(docRef, {
          'status': RideStatus.rejected.name,
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

  /// Observes the driver's current active ride in real-time.
  ///
  /// An "active" ride is one where:
  ///   - `driverId == authenticatedDriverId`
  ///   - `status` is one of: `accepted`, `arrived`, `inProgress`
  ///
  /// Yields `null` when no active ride exists.
  ///
  /// If multiple active rides are found for the same driver (data-integrity
  /// violation), emits a [FirestoreException] with code `integrity-violation`.
  Stream<RideModel?> watchDriverActiveRide(String driverId) {
    if (driverId.trim().isEmpty) {
      return Stream.error(const FirestoreException('Invalid driver ID.'));
    }

    // The active statuses for a driver's operational ride
    const activeStatuses = {
      'accepted',
      'arrived',
      'inProgress',
    };

    try {
      // Query by driverId only; filter active statuses client-side
      // (Firestore 'whereIn' on status would work too, but this keeps
      //  the query simple and avoids composite-index requirements)
      return _rides
          .where('driverId', isEqualTo: driverId.trim())
          .snapshots()
          .map((snapshot) {
        final validDocs = <RideModel>[];

        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data == null) continue;
          try {
            final statusStr = data['status'] as String?;
            if (statusStr == null || !activeStatuses.contains(statusStr)) {
              continue;
            }
            final ride = RideModel.fromMap(data, doc.id);
            // Strict double-check after deserialization
            if (ride.status == RideStatus.accepted ||
                ride.status == RideStatus.arrived ||
                ride.status == RideStatus.inProgress) {
              validDocs.add(ride);
            }
          } catch (_) {
            continue; // Skip malformed documents
          }
        }

        if (validDocs.length > 1) {
          throw const FirestoreException(
            'Multiple active rides found. Please contact support.',
            code: 'integrity-violation',
          );
        }

        return validDocs.isEmpty ? null : validDocs.first;
      }).handleError((error) {
        throw FirestoreException.from(error);
      });
    } catch (e) {
      return Stream.error(FirestoreException.from(e));
    }
  }

  /// Atomically transitions ride status from [accepted] to [arrived].
  ///
  /// Validates ownership and current status before committing.
  Future<void> markRideArrived(String rideId, String driverId) async {
    await _transitionRideStatus(
      rideId: rideId,
      driverId: driverId,
      expectedStatus: RideStatus.accepted,
      nextStatus: RideStatus.arrived,
    );
  }

  /// Atomically transitions ride status from [arrived] to [inProgress].
  Future<void> startRide(String rideId, String driverId) async {
    await _transitionRideStatus(
      rideId: rideId,
      driverId: driverId,
      expectedStatus: RideStatus.arrived,
      nextStatus: RideStatus.inProgress,
    );
  }

  /// Atomically transitions ride status from [inProgress] to [completed].
  Future<void> completeRide(String rideId, String driverId) async {
    await _transitionRideStatus(
      rideId: rideId,
      driverId: driverId,
      expectedStatus: RideStatus.inProgress,
      nextStatus: RideStatus.completed,
    );
  }

  /// Internal: Performs a validated, atomic status transition via Firestore transaction.
  ///
  /// Checks:
  ///   1. Document exists.
  ///   2. `driverId` matches the authenticated driver.
  ///   3. Current status equals [expectedStatus].
  ///   4. Writes [nextStatus] + `updatedAt` only.
  Future<void> _transitionRideStatus({
    required String rideId,
    required String driverId,
    required RideStatus expectedStatus,
    required RideStatus nextStatus,
  }) async {
    if (rideId.trim().isEmpty) throw ArgumentError('Ride ID cannot be empty.');
    if (driverId.trim().isEmpty) throw ArgumentError('Driver ID cannot be empty.');

    try {
      final docRef = _rides.doc(rideId.trim());

      await _firestore.runTransaction((tx) async {
        final snapshot = await tx.get(docRef);

        if (!snapshot.exists) {
          throw const FirestoreException('Ride not found.', code: 'not-found');
        }

        final data = snapshot.data();
        if (data == null) {
          throw const FirestoreException('Ride data is corrupted.', code: 'data-corrupted');
        }

        // Ownership
        if (data['driverId'] != driverId) {
          throw const FirestoreException(
            'Unauthorized: you are not the assigned driver for this ride.',
            code: 'permission-denied',
          );
        }

        // Status pre-condition
        final currentStr = data['status'] as String?;
        if (currentStr != expectedStatus.name) {
          if (currentStr == RideStatus.cancelled.name) {
            throw const FirestoreException(
              'This ride was cancelled by the rider.',
              code: 'invalid-state',
            );
          }
          throw FirestoreException(
            'Cannot update ride: expected status "${expectedStatus.name}" but found "${currentStr ?? 'unknown'}".',
            code: 'invalid-state',
          );
        }

        tx.update(docRef, {
          'status': nextStatus.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException.from(e);
    }
  }

  /// Submits feedback for a completed ride.
  /// 
  /// The [riderId] must match the currently authenticated user's ID to enforce ownership.
  /// Throws [ArgumentError] if [rating] is out of bounds or [comment] is too long.
  /// Throws [FirestoreException] on failure (e.g. duplicate feedback, not completed).
  Future<void> submitRideFeedback(String rideId, String riderId, int rating, {String? comment}) async {
    if (rideId.trim().isEmpty) throw ArgumentError('Ride ID cannot be empty.');
    if (riderId.trim().isEmpty) throw ArgumentError('Rider ID cannot be empty.');
    if (rating < 1 || rating > 5) throw ArgumentError('Rating must be between 1 and 5.');
    if (comment != null && comment.length > 500) {
      throw ArgumentError('Comment must not exceed 500 characters.');
    }

    try {
      final docRef = _rides.doc(rideId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw FirestoreException('Ride not found.', code: 'not-found');
        }

        final data = snapshot.data();
        if (data == null) {
          throw FirestoreException('Ride data is empty.', code: 'not-found');
        }

        if (data['riderId'] != riderId) {
          throw FirestoreException('Only the original rider can submit feedback for this ride.', code: 'permission-denied');
        }

        if (data['status'] != RideStatus.completed.name) {
          throw FirestoreException('Feedback can only be submitted for completed rides.', code: 'invalid-state');
        }

        if (data['feedback'] != null) {
          throw FirestoreException('Feedback has already been submitted for this ride.', code: 'already-exists');
        }

        transaction.update(docRef, {
          'feedback': {
            'rating': rating,
            if (comment != null) 'comment': comment,
            'createdAt': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException.from(e);
    }
  }
}
