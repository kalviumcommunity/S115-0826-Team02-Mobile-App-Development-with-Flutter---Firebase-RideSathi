import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

/// Centralized service to handle Firebase initialization and status tracking.
class FirebaseService {
  static bool _isInitialized = false;
  static String? _initializationError;

  static bool get isInitialized => _isInitialized;
  static String? get initializationError => _initializationError;

  /// Safely attempts to initialize Firebase Core.
  /// Catches exceptions gracefully when native credentials are not yet provisioned.
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // Web Firebase initialization requires FirebaseOptions
        _isInitialized = false;
        _initializationError = 'Firebase Web options pending configuration.';
        return;
      }

      await Firebase.initializeApp();
      _isInitialized = true;
      _initializationError = null;
      if (kDebugMode) {
        print('RideSathi: Firebase Core initialized successfully.');
      }
    } catch (e) {
      _isInitialized = false;
      _initializationError = e.toString();
      if (kDebugMode) {
        print('RideSathi: Firebase Core initialization note: $e');
      }
    }
  }
}
