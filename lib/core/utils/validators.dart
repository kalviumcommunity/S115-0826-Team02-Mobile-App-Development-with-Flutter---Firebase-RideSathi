/// Pure, framework-independent form validators for authentication screens.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phonePattern = RegExp(r'^\+?\d{7,15}$');

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

  /// Validates a full name: required, not whitespace-only, min 2 characters.
  static String? name(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Full name is required.';
    if (trimmed.length < 2) return 'Name must be at least 2 characters.';
    return null;
  }

  /// Validates a phone number: required, optional + prefix, 7–15 digits.
  static String? phone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Phone number is required.';
    if (!_phonePattern.hasMatch(trimmed)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }
}
