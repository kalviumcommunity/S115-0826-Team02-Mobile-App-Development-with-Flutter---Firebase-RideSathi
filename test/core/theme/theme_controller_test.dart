import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridesathi/core/theme/theme_controller.dart';

void main() {
  setUp(() {
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
