/// Pure, framework-independent form validators for authentication screens.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Email is required.';
    if (!_emailPattern.hasMatch(trimmed)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    final entered = value ?? '';
    if (entered.isEmpty) return 'Password is required.';
    if (entered.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  static String? confirmPassword(String? password, String? confirmValue) {
    final entered = confirmValue ?? '';
    if (entered.isEmpty) return 'Please confirm your password.';
    if (entered != password) return 'Passwords do not match.';
    return null;
  }
}
