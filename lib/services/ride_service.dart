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
}
