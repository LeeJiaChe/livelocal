class AuthFormValidator {
  AuthFormValidator._();

  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  // ============================================================
  // FULL NAME VALIDATION
  // ============================================================

  static String? validateFullName(String? value) {
    final String fullName = value?.trim() ?? '';

    if (fullName.isEmpty) {
      return 'Full name is required';
    }

    if (fullName.length < 2 || fullName.length > 80) {
      return 'Use between 2 and 80 characters';
    }

    return null;
  }

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

  static String? validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email address is required';
    }

    if (email.length > 254) {
      return 'Enter a valid email address';
    }

    if (!_emailPattern.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    final List<String> parts = email.split('@');

    if (parts.length != 2) {
      return 'Enter a valid email address';
    }

    final String localPart = parts.first;
    final String domainPart = parts.last;

    if (localPart.length > 64) {
      return 'Enter a valid email address';
    }

    if (localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains('..')) {
      return 'Enter a valid email address';
    }

    if (domainPart.startsWith('.') ||
        domainPart.endsWith('.') ||
        domainPart.contains('..')) {
      return 'Enter a valid email address';
    }

    return null;
  }

  // ============================================================
  // LOGIN PASSWORD VALIDATION
  // ============================================================

  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    return null;
  }

  // ============================================================
  // REGISTER PASSWORD VALIDATION
  // ============================================================

  static String? validateRegisterPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 10) {
      return 'Use 10+ characters with a letter and number';
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Use 10+ characters with a letter and number';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Use 10+ characters with a letter and number';
    }

    return null;
  }

  // ============================================================
  // CONFIRM PASSWORD VALIDATION
  // ============================================================

  static String? validateConfirmPassword(
    String? value,
    String password,
  ) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }
}
