import 'package:flutter/material.dart';

/// Centralized state controller for managing RideSathi light and dark theme modes.
class ThemeController {
  /// Reactive notifier storing current ThemeMode selection.
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Returns active ThemeMode value.
  static ThemeMode get themeMode => themeModeNotifier.value;

  /// Toggles theme between Light and Dark mode.
  static void toggleTheme() {
    if (themeModeNotifier.value == ThemeMode.dark) {
      themeModeNotifier.value = ThemeMode.light;
    } else {
      themeModeNotifier.value = ThemeMode.dark;
    }
  }

  /// Sets specific ThemeMode (light, dark, or system).
  static void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }
}
