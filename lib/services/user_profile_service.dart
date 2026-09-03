import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'firestore_exception.dart';

/// Service abstraction for persisting and retrieving user profiles in Firestore.
///
/// Encapsulates all `cloud_firestore` SDK usage — screens and controllers
/// must never import `cloud_firestore` directly.
///
/// Uses the authenticated Firebase UID as the Firestore document ID
/// under the `users` collection.
class UserProfileService {
  final FirebaseFirestore? _firestore;

  /// Creates a [UserProfileService]. If [firestore] is omitted,
  /// [FirebaseFirestore.instance] is used.
  const UserProfileService([FirebaseFirestore? firestore])
      : _firestore = firestore;

  FirebaseFirestore get _instance =>
      _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _instance.collection('users');

  /// Creates a rider profile document in Firestore at `users/{uid}`.
  ///
  /// Uses server timestamps for `createdAt` and `updatedAt` to ensure
  /// consistent time tracking regardless of client clock.
  ///
  /// Throws [FirestoreException] if the write fails.
  Future<void> createRiderProfile(UserModel user) async {
    try {
      final data = user.toMap();
      // Replace client-side timestamps with Firestore server timestamps.
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _usersCollection.doc(user.id).set(data);
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  /// Creates a driver profile document in Firestore at `users/{uid}`.
  ///
  /// Uses server timestamps for `createdAt` and `updatedAt` to ensure
  /// consistent time tracking regardless of client clock.
  ///
  /// Throws [FirestoreException] if the write fails.
  Future<void> createDriverProfile(UserModel user) async {
    try {
      final data = user.toMap();
      // Replace client-side timestamps with Firestore server timestamps.
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _usersCollection.doc(user.id).set(data);
    } catch (e) {
      throw FirestoreException.from(e);
    }
  }

  /// Retrieves a user profile from Firestore by UID.
  ///
  /// Returns `null` if the document does not exist.
  /// Throws [FirestoreException] on read failure or if the document contains an invalid/corrupted role.
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = Map<String, dynamic>.from(doc.data()!);

      // Convert Firestore Timestamps to ISO 8601 strings for UserModel.fromMap.
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] =
            (data['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      if (data['updatedAt'] is Timestamp) {
        data['updatedAt'] =
            (data['updatedAt'] as Timestamp).toDate().toIso8601String();
      }

      return UserModel.fromMap(data);
    } on FormatException catch (_) {
      throw const FirestoreException(
        'User profile data is corrupted or contains an invalid role.',
        code: 'invalid-profile',
      );
    } catch (e) {
      if (e is FirestoreException) rethrow;
      throw FirestoreException.from(e);
    }
  }
}
