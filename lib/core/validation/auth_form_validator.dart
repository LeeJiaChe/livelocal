class AuthFormValidator {
  AuthFormValidator._();

  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

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

  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    return null;
  }
}
