import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/core/validation/auth_form_validator.dart';

void main() {
  group('AuthFormValidator - Email Validation', () {
    test('returns required error when email is null', () {
      expect(
        AuthFormValidator.validateEmail(null),
        'Email address is required',
      );
    });

    test('returns required error when email is empty', () {
      expect(AuthFormValidator.validateEmail(''), 'Email address is required');
    });

    test('returns required error when email contains only spaces', () {
      expect(
        AuthFormValidator.validateEmail('   '),
        'Email address is required',
      );
    });

    test('rejects email without @ symbol', () {
      expect(
        AuthFormValidator.validateEmail('userexample.com'),
        'Enter a valid email address',
      );
    });

    test('rejects email without domain', () {
      expect(
        AuthFormValidator.validateEmail('user@'),
        'Enter a valid email address',
      );
    });

    test('rejects email without valid top-level domain', () {
      expect(
        AuthFormValidator.validateEmail('user@example.c'),
        'Enter a valid email address',
      );
    });

    test('rejects email with consecutive dots in local part', () {
      expect(
        AuthFormValidator.validateEmail('user..name@example.com'),
        'Enter a valid email address',
      );
    });

    test('rejects email starting with a dot', () {
      expect(
        AuthFormValidator.validateEmail('.user@example.com'),
        'Enter a valid email address',
      );
    });

    test('rejects email ending local part with a dot', () {
      expect(
        AuthFormValidator.validateEmail('user.@example.com'),
        'Enter a valid email address',
      );
    });

    test('rejects email with consecutive dots in domain', () {
      expect(
        AuthFormValidator.validateEmail('user@example..com'),
        'Enter a valid email address',
      );
    });

    test('rejects local part longer than 64 characters', () {
      final String email = '${List.filled(65, 'a').join()}@example.com';

      expect(
        AuthFormValidator.validateEmail(email),
        'Enter a valid email address',
      );
    });

    test('accepts valid normal email', () {
      expect(AuthFormValidator.validateEmail('tourist@livelocal.com'), isNull);
    });

    test('accepts valid email with subdomain', () {
      expect(AuthFormValidator.validateEmail('user@mail.example.com'), isNull);
    });

    test('accepts valid email with plus addressing', () {
      expect(AuthFormValidator.validateEmail('user+test@example.com'), isNull);
    });

    test('trims spaces around valid email', () {
      expect(
        AuthFormValidator.validateEmail('  tourist@livelocal.com  '),
        isNull,
      );
    });
  });

  group('AuthFormValidator - Login Password Validation', () {
    test('returns required error when password is null', () {
      expect(
        AuthFormValidator.validateLoginPassword(null),
        'Password is required',
      );
    });

    test('returns required error when password is empty', () {
      expect(
        AuthFormValidator.validateLoginPassword(''),
        'Password is required',
      );
    });

    test('accepts demo login password', () {
      expect(AuthFormValidator.validateLoginPassword('123456'), isNull);
    });

    test('accepts any non-empty existing password', () {
      expect(
        AuthFormValidator.validateLoginPassword('ExistingPassword123!'),
        isNull,
      );
    });
  });
}
