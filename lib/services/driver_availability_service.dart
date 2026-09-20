import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_exception.dart';

/// Service abstraction for managing driver online/offline availability in Firestore.
///
/// Encapsulates all Firestore SDK usage for availability updates — screens and controllers
/// must never import `cloud_firestore` directly.
class DriverAvailabilityService {
  final FirebaseFirestore? _firestore;

  /// Creates a [DriverAvailabilityService]. If [firestore] is omitted,
  /// [FirebaseFirestore.instance] is used.
  const DriverAvailabilityService([FirebaseFirestore? firestore])
      : _firestore = firestore;

  static FirebaseFirestore? firestoreOverride;
  FirebaseFirestore get _instance => _firestore ?? firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _instance.collection('users');

  /// Retrieves the current online availability for [driverId].
  ///
  /// Safe default is `false` (Offline).
  /// Throws [ArgumentError] if [driverId] is empty.
  /// Throws [FirestoreException] on read failure.
  Future<bool> getAvailability(String driverId) async {
    final trimmedId = driverId.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('Driver ID cannot be empty.');
    }

    try {
      final doc = await _usersCollection.doc(trimmedId).get();
      if (!doc.exists || doc.data() == null) return false;

      final rawOnline = doc.data()!['isOnline'];
      return rawOnline is bool ? rawOnline : false;
    } catch (e) {
      if (e is ArgumentError || e is FirestoreException) rethrow;
      throw FirestoreException.from(e);
    }
  }

  /// Updates the online availability state for [driverId] in Firestore at `users/{driverId}`.
  ///
  /// Automatically injects [FieldValue.serverTimestamp()] for `availabilityUpdatedAt`.
  /// Returns the updated [isOnline] state.
  /// Throws [ArgumentError] if [driverId] is empty.
  /// Throws [FirestoreException] if the write fails.
  Future<bool> setAvailability({
    required String driverId,
    required bool isOnline,
  }) async {
    final trimmedId = driverId.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('Driver ID cannot be empty.');
    }

    try {
      await _usersCollection.doc(trimmedId).update({
        'isOnline': isOnline,
        'availabilityUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return isOnline;
    } catch (e) {
      if (e is ArgumentError || e is FirestoreException) rethrow;
      throw FirestoreException.from(e);
    }
  }

  /// Stream of availability state changes for [driverId].
  ///
  /// Emits `false` if the document does not exist or availability field is malformed.
  Stream<bool> watchAvailability(String driverId) {
    final trimmedId = driverId.trim();
    if (trimmedId.isEmpty) {
      return Stream.error(ArgumentError('Driver ID cannot be empty.'));
    }

    return _usersCollection.doc(trimmedId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return false;
      final rawOnline = doc.data()!['isOnline'];
      return rawOnline is bool ? rawOnline : false;
    }).handleError((error) {
      throw FirestoreException.from(error);
    });
  }
}
