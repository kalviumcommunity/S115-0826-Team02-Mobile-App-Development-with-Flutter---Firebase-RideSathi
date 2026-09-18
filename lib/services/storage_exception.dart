import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';

class StorageException implements Exception {
  final String message;
  final String code;

  const StorageException(this.message, {this.code = 'unknown'});

  factory StorageException.from(dynamic exception) {
    if (exception is FirebaseException) {
      switch (exception.code) {
        case 'object-not-found':
          return const StorageException('File does not exist.', code: 'object-not-found');
        case 'unauthorized':
          return const StorageException('User is not authorized to perform the desired action.', code: 'unauthorized');
        case 'canceled':
          return const StorageException('User canceled the operation.', code: 'canceled');
        case 'invalid-argument':
          return const StorageException('File is invalid or not found.', code: 'invalid-argument');
        case 'quota-exceeded':
          return const StorageException('Storage quota exceeded.', code: 'quota-exceeded');
        case 'unauthenticated':
          return const StorageException('User is unauthenticated.', code: 'unauthenticated');
        default:
          return StorageException(exception.message ?? 'An unknown storage error occurred.', code: exception.code);
      }
    }
    
    if (exception is StorageException) {
      return exception;
    }

    if (exception is TimeoutException || exception.toString().contains('TimeoutException')) {
      return const StorageException('The operation timed out. Please check your internet connection.', code: 'deadline-exceeded');
    }

    return StorageException(exception.toString());
  }

  @override
  String toString() => 'StorageException($code): $message';
}
