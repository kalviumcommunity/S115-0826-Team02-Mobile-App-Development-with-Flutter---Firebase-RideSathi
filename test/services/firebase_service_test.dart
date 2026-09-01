import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/firebase_options.dart';
import 'package:ridesathi/services/firebase_service.dart';

void main() {
  setUp(() {
    FirebaseService.resetForTesting();
  });

  tearDown(() {
    FirebaseService.resetForTesting();
  });

  group('FirebaseService — State Management & Overrides', () {
    test('defaults to uninitialized state', () {
      expect(FirebaseService.isInitialized, isFalse);
      expect(FirebaseService.initializationError, isNull);
    });

    test('isInitializedOverride updates initialization flag and clears error', () {
      FirebaseService.isInitializedOverride = true;

      expect(FirebaseService.isInitialized, isTrue);
      expect(FirebaseService.initializationError, isNull);

      FirebaseService.isInitializedOverride = false;
      expect(FirebaseService.isInitialized, isFalse);
    });

    test('resetForTesting restores clean uninitialized state', () {
      FirebaseService.isInitializedOverride = true;
      expect(FirebaseService.isInitialized, isTrue);

      FirebaseService.resetForTesting();
      expect(FirebaseService.isInitialized, isFalse);
      expect(FirebaseService.initializationError, isNull);
    });
  });

  group('DefaultFirebaseOptions — Configuration Verification', () {
    test('Android options match RideSathi project parameters', () {
      final androidOptions = DefaultFirebaseOptions.android;

      expect(androidOptions.projectId, equals('ridesathi-f7ca3'));
      expect(androidOptions.appId, contains('android'));
      expect(androidOptions.messagingSenderId, equals('984078491668'));
      expect(androidOptions.storageBucket, equals('ridesathi-f7ca3.firebasestorage.app'));
      expect(androidOptions.apiKey, isNotEmpty);
    });

    test('Web options match RideSathi project parameters', () {
      final webOptions = DefaultFirebaseOptions.web;

      expect(webOptions.projectId, equals('ridesathi-f7ca3'));
      expect(webOptions.appId, contains('web'));
      expect(webOptions.messagingSenderId, equals('984078491668'));
      expect(webOptions.authDomain, equals('ridesathi-f7ca3.firebaseapp.com'));
      expect(webOptions.storageBucket, equals('ridesathi-f7ca3.firebasestorage.app'));
      expect(webOptions.measurementId, equals('G-ZNDBSNT05Z'));
      expect(webOptions.apiKey, isNotEmpty);
    });

    test('currentPlatform returns valid options for current test platform', () {
      final options = DefaultFirebaseOptions.currentPlatform;

      expect(options.projectId, equals('ridesathi-f7ca3'));
      expect(options.apiKey, isNotEmpty);
      expect(options.appId, isNotEmpty);
    });
  });
}
