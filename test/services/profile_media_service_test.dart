import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ridesathi/services/storage_exception.dart';
import 'package:ridesathi/services/profile_media_service.dart';

void main() {
  group('StorageException Mapping', () {
    test('maps object-not-found to correct StorageException', () {
      final firebaseException = FirebaseException(
        plugin: 'firebase_storage',
        code: 'object-not-found',
        message: 'No object exists at the desired reference.',
      );

      final storageException = StorageException.from(firebaseException);

      expect(storageException.code, 'object-not-found');
      expect(storageException.message, 'File does not exist.');
    });

    test('maps unauthorized to correct StorageException', () {
      final firebaseException = FirebaseException(
        plugin: 'firebase_storage',
        code: 'unauthorized',
      );

      final storageException = StorageException.from(firebaseException);

      expect(storageException.code, 'unauthorized');
      expect(storageException.message, 'User is not authorized to perform the desired action.');
    });
    
    test('handles generic exceptions', () {
      final exception = Exception('Something went wrong');
      final storageException = StorageException.from(exception);
      expect(storageException.message, 'Exception: Something went wrong');
    });
  });

  group('ProfileMediaService validation checks', () {
    final service = ProfileMediaService();

    test('uploadProfileImage throws ArgumentError on empty uid', () async {
      expect(
        () => service.uploadProfileImage('   ', null as dynamic), // bypassing for validation check
        throwsA(isA<ArgumentError>()),
      );
    });

    test('uploadDriverDocument throws ArgumentError on empty uid or docId', () async {
      expect(
        () => service.uploadDriverDocument('', 'doc_id', null as dynamic),
        throwsA(isA<ArgumentError>()),
      );
      
      expect(
        () => service.uploadDriverDocument('uid123', '  ', null as dynamic),
        throwsA(isA<ArgumentError>()),
      );
    });
    
    test('deleteMedia throws ArgumentError on empty uid', () async {
      expect(
        () => service.deleteMedia('', 'http://example.com/media'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
