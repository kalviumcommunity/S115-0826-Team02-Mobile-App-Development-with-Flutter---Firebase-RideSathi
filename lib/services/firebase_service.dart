import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Centralized service to handle Firebase initialization and status tracking.
class FirebaseService {
  static bool _isInitialized = false;
  static String? _initializationError;

  static bool get isInitialized => _isInitialized;
  static String? get initializationError => _initializationError;

  /// Safely attempts to initialize Firebase Core using the generated
  /// [DefaultFirebaseOptions] for the current platform.
  static Future<void> initialize() async {
    try {
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
