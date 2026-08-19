import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/core/validation/auth_form_validator.dart';

void main() {
  // ============================================================
  // FULL NAME VALIDATION
  // ============================================================

  group('AuthFormValidator - Full Name Validation', () {
    test('returns required error when full name is null', () {
      expect(
        AuthFormValidator.validateFullName(null),
        'Full name is required',
      );
    });

    test('returns required error when full name is empty', () {
      expect(
        AuthFormValidator.validateFullName(''),
        'Full name is required',
      );
    });

    test('returns required error when full name contains only spaces', () {
      expect(
        AuthFormValidator.validateFullName('   '),
        'Full name is required',
      );
    });

    test('rejects full name shorter than 2 characters', () {
      expect(
        AuthFormValidator.validateFullName('A'),
        'Use between 2 and 80 characters',
      );
    });

    test('rejects full name longer than 80 characters', () {
      final longName = List.filled(81, 'A').join();

      expect(
        AuthFormValidator.validateFullName(longName),
        'Use between 2 and 80 characters',
      );
    });

    test('accepts 2 character full name', () {
      expect(
        AuthFormValidator.validateFullName('Li'),
        isNull,
      );
    });

    test('accepts valid full name', () {
      expect(
        AuthFormValidator.validateFullName('Yeoh Ka Hou'),
        isNull,
      );
    });

    test('trims spaces around valid full name', () {
      expect(
        AuthFormValidator.validateFullName('  Yeoh Ka Hou  '),
        isNull,
      );
    });
  });

  // ============================================================
  // EMAIL VALIDATION
  // ============================================================

  group('AuthFormValidator - Email Validation', () {
    test('returns required error when email is null', () {
      expect(
        AuthFormValidator.validateEmail(null),
        'Email address is required',
      );
    });

    test('returns required error when email is empty', () {
      expect(
        AuthFormValidator.validateEmail(''),
        'Email address is required',
      );
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
        AuthFormValidator.validateEmail(
          'user..name@example.com',
        ),
        'Enter a valid email address',
      );
    });

    test('rejects email starting with dot', () {
      expect(
        AuthFormValidator.validateEmail(
          '.user@example.com',
        ),
        'Enter a valid email address',
      );
    });

    test('rejects local part ending with dot', () {
      expect(
        AuthFormValidator.validateEmail(
          'user.@example.com',
        ),
        'Enter a valid email address',
      );
    });

    test('rejects email with consecutive dots in domain', () {
      expect(
        AuthFormValidator.validateEmail(
          'user@example..com',
        ),
        'Enter a valid email address',
      );
    });

    test('rejects domain starting with dot', () {
      expect(
        AuthFormValidator.validateEmail(
          'user@.example.com',
        ),
        'Enter a valid email address',
      );
    });

    test('rejects local part longer than 64 characters', () {
      final email = '${List.filled(65, 'a').join()}@example.com';

      expect(
        AuthFormValidator.validateEmail(email),
        'Enter a valid email address',
      );
    });

    test('rejects email longer than 254 characters', () {
      final email = '${List.filled(245, 'a').join()}@example.com';

      expect(
        AuthFormValidator.validateEmail(email),
        'Enter a valid email address',
      );
    });

    test('accepts valid normal email', () {
      expect(
        AuthFormValidator.validateEmail(
          'tourist@livelocal.com',
        ),
        isNull,
      );
    });

    test('accepts valid email with uppercase letters', () {
      expect(
        AuthFormValidator.validateEmail(
          'Tourist@LiveLocal.com',
        ),
        isNull,
      );
    });

    test('accepts valid email with subdomain', () {
      expect(
        AuthFormValidator.validateEmail(
          'user@mail.example.com',
        ),
        isNull,
      );
    });

    test('accepts valid email with plus addressing', () {
      expect(
        AuthFormValidator.validateEmail(
          'user+test@example.com',
        ),
        isNull,
      );
    });

    test('trims spaces around valid email', () {
      expect(
        AuthFormValidator.validateEmail(
          '  tourist@livelocal.com  ',
        ),
        isNull,
      );
    });
  });

  // ============================================================
  // LOGIN PASSWORD VALIDATION
  // ============================================================

  group('AuthFormValidator - Login Password Validation', () {
    test('returns required error when login password is null', () {
      expect(
        AuthFormValidator.validateLoginPassword(null),
        'Password is required',
      );
    });

    test('returns required error when login password is empty', () {
      expect(
        AuthFormValidator.validateLoginPassword(''),
        'Password is required',
      );
    });

    test('accepts any non-empty login password', () {
      expect(
        AuthFormValidator.validateLoginPassword('123456'),
        isNull,
      );
    });

    test('accepts existing complex login password', () {
      expect(
        AuthFormValidator.validateLoginPassword(
          'ExistingPassword123!',
        ),
        isNull,
      );
    });
  });

  // ============================================================
  // REGISTER PASSWORD VALIDATION
  // ============================================================

  group('AuthFormValidator - Register Password Validation', () {
    test('returns required error when register password is null', () {
      expect(
        AuthFormValidator.validateRegisterPassword(null),
        'Password is required',
      );
    });

    test('returns required error when register password is empty', () {
      expect(
        AuthFormValidator.validateRegisterPassword(''),
        'Password is required',
      );
    });

    test('rejects password shorter than 10 characters', () {
      expect(
        AuthFormValidator.validateRegisterPassword(
          'Demo123',
        ),
        'Use 10+ characters with a letter and number',
      );
    });

    test('rejects 9 character password', () {
      expect(
        AuthFormValidator.validateRegisterPassword(
          'Demo12345',
        ),
        'Use 10+ characters with a letter and number',
      );
    });

    test('rejects password without letters', () {
      expect(
        AuthFormValidator.validateRegisterPassword(
          '1234567890',
        ),
        'Use 10+ characters with a letter and number',
      );
    });

    test('rejects password without numbers', () {
      expect(
        AuthFormValidator.validateRegisterPassword(
          'abcdefghij',
        ),
        'Use 10+ characters with a letter and number',
      );
    });

    test('accepts valid 10 character password', () {
      expect(
        AuthFormValidator.validateRegisterPassword(
          'Demo123456',
        ),
        isNull,
      );
    });

    test('accepts valid password with lowercase letters', () {
      expect(
        AuthFormValidator.validateRegisterPassword(
          'password123',
        ),
        isNull,
      );
    });

    test('accepts valid password with uppercase letters', () {
      expect(
        AuthFormValidator.validateRegisterPassword(
          'PASSWORD123',
        ),
        isNull,
      );
    });

    test('accepts valid password with special character', () {
      expect(
        AuthFormValidator.validateRegisterPassword(
          'DemoOnly123!',
        ),
        isNull,
      );
    });
  });

  // ============================================================
  // CONFIRM PASSWORD VALIDATION
  // ============================================================

  group('AuthFormValidator - Confirm Password Validation', () {
    test('returns required error when confirm password is null', () {
      expect(
        AuthFormValidator.validateConfirmPassword(
          null,
          'DemoOnly123!',
        ),
        'Confirm password is required',
      );
    });

    test('returns required error when confirm password is empty', () {
      expect(
        AuthFormValidator.validateConfirmPassword(
          '',
          'DemoOnly123!',
        ),
        'Confirm password is required',
      );
    });

    test('rejects confirm password when passwords do not match', () {
      expect(
        AuthFormValidator.validateConfirmPassword(
          'Different123!',
          'DemoOnly123!',
        ),
        'Passwords do not match',
      );
    });

    test('password matching is case sensitive', () {
      expect(
        AuthFormValidator.validateConfirmPassword(
          'demoonly123!',
          'DemoOnly123!',
        ),
        'Passwords do not match',
      );
    });

    test('accepts confirm password when passwords match', () {
      expect(
        AuthFormValidator.validateConfirmPassword(
          'DemoOnly123!',
          'DemoOnly123!',
        ),
        isNull,
      );
    });
  });
}
