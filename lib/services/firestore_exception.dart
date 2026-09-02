import 'package:firebase_core/firebase_core.dart';
import 'service_exception.dart';

/// User-friendly exception surfaced by Firestore service operations in place
/// of raw Firebase exceptions, which must never reach the UI directly.
class FirestoreException extends ServiceException {
  const FirestoreException(super.message, {super.code});

  factory FirestoreException.from(Object error) {
    if (error is FirebaseException) {
      return FirestoreException(
        _messageForCode(error.code),
        code: error.code,
      );
    }
    return const FirestoreException(
      'Something went wrong. Please check your connection and try again.',
    );
  }

  static String _messageForCode(String code) {
    switch (code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again later.';
      case 'not-found':
        return 'The requested data could not be found.';
      case 'already-exists':
        return 'This record already exists.';
      case 'deadline-exceeded':
        return 'The operation timed out. Please try again.';
      case 'cancelled':
        return 'The operation was cancelled.';
      case 'resource-exhausted':
        return 'Service quota exceeded. Please try again later.';
      default:
        return 'A data error occurred. Please try again.';
    }
  }
}
