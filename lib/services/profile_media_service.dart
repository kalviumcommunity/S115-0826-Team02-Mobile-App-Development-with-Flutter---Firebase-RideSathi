import 'dart:io';
import '../core/utils/future_timeout_extension.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'storage_exception.dart';

class ProfileMediaService {
  final FirebaseStorage? _storage;

  const ProfileMediaService([FirebaseStorage? storage]) : _storage = storage;

  FirebaseStorage get _instance => _storage ?? FirebaseStorage.instance;

  /// Uploads a profile image and returns the download URL.
  Future<String> uploadProfileImage(String uid, File imageFile) async {
    if (uid.trim().isEmpty) throw ArgumentError('UID cannot be empty.');
    
    try {
      final ref = _instance.ref().child('users/$uid/profile/image');
      
      // Basic client validation
      if (!await imageFile.exists()) {
        throw const StorageException('File does not exist on device.', code: 'invalid-argument');
      }
      
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) { // 5MB limit
        throw const StorageException('Image exceeds 5MB limit.', code: 'quota-exceeded');
      }

      final uploadTask = await ref.putFile(
        imageFile, 
        SettableMetadata(contentType: 'image/jpeg')
      );
      
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw StorageException.from(e);
    }
  }

  /// Uploads a driver document and returns the download URL.
  Future<String> uploadDriverDocument(String uid, String documentId, File documentFile) async {
    if (uid.trim().isEmpty) throw ArgumentError('UID cannot be empty.');
    if (documentId.trim().isEmpty) throw ArgumentError('Document ID cannot be empty.');

    try {
      final ref = _instance.ref().child('users/$uid/documents/$documentId');
      
      if (!await documentFile.exists()) {
        throw const StorageException('File does not exist on device.', code: 'invalid-argument');
      }

      final fileSize = await documentFile.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        throw const StorageException('Document exceeds 10MB limit.', code: 'quota-exceeded');
      }

      final uploadTask = await ref.putFile(documentFile).withNetworkTimeout();
      
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw StorageException.from(e);
    }
  }

  /// Safely deletes a file at the specified URL if it belongs to the user.
  Future<void> deleteMedia(String uid, String mediaUrl) async {
    if (uid.trim().isEmpty) throw ArgumentError('UID cannot be empty.');
    if (mediaUrl.trim().isEmpty) return;

    try {
      final ref = _instance.refFromURL(mediaUrl);
      
      // Ensure the path contains the UID to prevent unauthorized deletions
      if (!ref.fullPath.contains('users/$uid/')) {
        throw const StorageException('Unauthorized deletion attempt.', code: 'unauthorized');
      }

      await ref.delete().withNetworkTimeout();
    } catch (e) {
      if (e is FirebaseException && e.code == 'object-not-found') {
        return; // File already deleted or doesn't exist
      }
      throw StorageException.from(e);
    }
  }
}
