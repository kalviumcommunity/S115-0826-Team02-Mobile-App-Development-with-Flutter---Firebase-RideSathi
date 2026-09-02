import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Centralized service to handle Firebase initialization and status tracking.
class FirebaseService {
  static bool _isInitialized = false;
  static String? _initializationError;

  static bool get isInitialized => _isInitialized;
  static String? get initializationError => _initializationError;

  /// The primary [FirebaseApp] instance managed by Firebase Core.
  /// Centralizes FirebaseApp access for future Firestore and Storage services.
  static FirebaseApp get app => Firebase.app();

  /// Allows tests to override the initialization state without a real
  /// Firebase project. **Do not use outside of test code.**
  @visibleForTesting
  static set isInitializedOverride(bool value) {
    _isInitialized = value;
    if (value) _initializationError = null;
  }

  /// Resets the initialization state for unit and widget testing.
  @visibleForTesting
  static void resetForTesting() {
    _isInitialized = false;
    _initializationError = null;
  }

  /// Safely attempts to initialize Firebase Core using the generated
  /// [DefaultFirebaseOptions] for the current platform.
  ///
  /// Idempotent: returns immediately if Firebase is already initialized.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        _initializationError = null;
        return;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
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
