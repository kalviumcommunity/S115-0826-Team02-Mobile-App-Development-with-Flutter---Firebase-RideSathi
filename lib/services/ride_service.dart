import 'package:cloud_firestore/cloud_firestore.dart';
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
}
