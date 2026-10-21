/// Reusable form field validators for TourneyZone.
class FormValidators {
  FormValidators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  static final RegExp _phoneRegExp = RegExp(r'^\d{10}$');

  /// Validates that a field is not empty.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates standard email address syntax.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates password security rules:
  /// - Minimum 8 characters
  /// - At least one letter
  /// - At least one number
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    final hasLetter = value.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = value.contains(RegExp(r'[0-9]'));

    if (!hasLetter) {
      return 'Password must contain at least one letter';
    }
    if (!hasDigit) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validates that password and confirm password match.
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates standard 10-digit phone number.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (!_phoneRegExp.hasMatch(clean)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  /// Validates in-game UID.
  static String? inGameUid(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'In-game UID is required';
    }
    if (value.trim().length < 3) {
      return 'UID must be at least 3 characters';
    }
    return null;
  }
}

