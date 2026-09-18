import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:ridesathi/services/ride_service.dart';
import 'package:ridesathi/services/driver_availability_service.dart';
import 'package:ridesathi/services/driver_data_service.dart';
import 'package:ridesathi/services/user_profile_service.dart';
import 'package:ridesathi/core/theme/theme_controller.dart';

void main() {
  setUp(() {
    final globalFakeFirestore = FakeFirebaseFirestore();
    RideService.firestoreOverride = globalFakeFirestore;
    DriverAvailabilityService.firestoreOverride = globalFakeFirestore;
    DriverDataService.firestoreOverride = globalFakeFirestore;
    UserProfileService.firestoreOverride = globalFakeFirestore;
    ThemeController.setThemeMode(ThemeMode.system);
  });

  group('ThemeController', () {
    test('initializes with ThemeMode.system', () {
      expect(ThemeController.themeMode, ThemeMode.system);
    });

    test('toggles theme mode between light and dark', () {
      ThemeController.toggleTheme();
      expect(ThemeController.themeMode, ThemeMode.dark);

      ThemeController.toggleTheme();
      expect(ThemeController.themeMode, ThemeMode.light);
    });

    test('sets specific theme mode', () {
      ThemeController.setThemeMode(ThemeMode.dark);
      expect(ThemeController.themeMode, ThemeMode.dark);

      ThemeController.setThemeMode(ThemeMode.light);
      expect(ThemeController.themeMode, ThemeMode.light);
    });
  });
}
