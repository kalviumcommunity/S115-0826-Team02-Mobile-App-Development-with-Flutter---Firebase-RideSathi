import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_exception.dart';
import 'user_profile_service.dart';

/// Service abstraction for persisting and retrieving driver availability in Firestore.
class DriverAvailabilityService {
  final FirebaseFirestore? _firestore;
  final UserProfileService _userProfileService;

  const DriverAvailabilityService({
    FirebaseFirestore? firestore,
    UserProfileService? userProfileService,
  })  : _firestore = firestore,
        _userProfileService = userProfileService ?? const UserProfileService();

  FirebaseFirestore get _instance => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _instance.collection('users');

  /// Sets the driver's online status in Firestore.
  ///
  /// This updates the `isOnline` boolean and sets `availabilityUpdatedAt`
  /// to the current Firestore server timestamp.
  /// Throws [FirestoreException] if the update fails.
  Future<void> setDriverOnlineStatus(String driverId, bool isOnline) async {
    final trimmedId = driverId.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('Driver ID cannot be empty.');
    }

    try {
      await _usersCollection.doc(trimmedId).update({
        'isOnline': isOnline,
        'availabilityUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }
}
