import 'package:firebase_core/firebase_core.dart';

/// Base exception class for generic Firebase or service-level failures.
/// Protects the application UI from raw Firebase exceptions.
class ServiceException implements Exception {
  final String message;
  final String? code;

  const ServiceException(this.message, {this.code});

  factory ServiceException.from(Object error) {
    if (error is FirebaseException) {
      return ServiceException(
        error.message ?? 'A service error occurred. Please try again.',
        code: error.code,
      );
    }
    return const ServiceException(
      'An unexpected error occurred. Please check your connection and try again.',
    );
  }

  @override
  String toString() => message;
}
