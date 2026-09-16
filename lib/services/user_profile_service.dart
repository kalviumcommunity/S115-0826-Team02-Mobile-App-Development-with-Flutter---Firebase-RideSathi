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

  /// Allowed mutable field keys for user profile updates.
  static const Set<String> allowedUpdateKeys = {
    'name',
    'phoneNumber',
    'vehicleInfo',
    'profileImageUrl',
    'driverDocumentUrl',
  };

  /// Disallowed immutable and domain-protected field keys.
  static const Set<String> protectedKeys = {
    'id',
    'email',
    'role',
    'isUnionVerified',
    'isOnline',
    'createdAt',
  };

  /// Updates permitted fields of an existing user profile document in Firestore at `users/{uid}`.
  ///
  /// Only [allowedUpdateKeys] are accepted. Attempting to modify [protectedKeys]
  /// or unwhitelisted keys throws an [ArgumentError].
  ///
  /// Automatically injects [FieldValue.serverTimestamp()] for `updatedAt`.
  ///
  /// Returns the freshly fetched [UserModel] representing the updated state.
  /// Throws [ArgumentError] for invalid parameters.
  /// Throws [FirestoreException] if the write fails or the user document is not found.
  Future<UserModel> updateProfile({
    required String uid,
    required Map<String, dynamic> updates,
  }) async {
    final trimmedUid = uid.trim();
    if (trimmedUid.isEmpty) {
      throw ArgumentError('UID cannot be empty.');
    }
    if (updates.isEmpty) {
      throw ArgumentError('Updates map cannot be empty.');
    }

    for (final key in updates.keys) {
      if (protectedKeys.contains(key)) {
        throw ArgumentError('Cannot update immutable or protected field "$key".');
      }
      if (!allowedUpdateKeys.contains(key)) {
        throw ArgumentError('Field "$key" is not permitted for profile update.');
      }
    }

    try {
      final payload = Map<String, dynamic>.from(updates);
      payload['updatedAt'] = FieldValue.serverTimestamp();

      await _usersCollection.doc(trimmedUid).update(payload);

      final updatedProfile = await getUserProfile(trimmedUid);
      if (updatedProfile == null) {
        throw const FirestoreException(
          'User profile not found after update.',
          code: 'not-found',
        );
      }
      return updatedProfile;
    } catch (e) {
      if (e is ArgumentError || e is FirestoreException) rethrow;
      throw FirestoreException.from(e);
    }
  }

  /// Convenience wrapper to update individual permitted profile fields.
  Future<UserModel> updateProfileFields({
    required String uid,
    String? name,
    String? phoneNumber,
    String? vehicleInfo,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (vehicleInfo != null) updates['vehicleInfo'] = vehicleInfo;

    return updateProfile(uid: uid, updates: updates);
  }
}

