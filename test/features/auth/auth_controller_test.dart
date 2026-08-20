import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/auth/presentation/auth_controller.dart';
import 'package:live_local/models/profile_model.dart';
import 'package:live_local/services/seed_data_service.dart';

void main() {
  group('AuthController session and access states', () {
    test('restores a guest session explicitly', () async {
      final controller = AuthController(repository: DemoAuthRepository());

      await controller.initialize();

      expect(controller.status, AuthStatus.guest);
      expect(controller.currentUser, isNull);
    });

    test('maps a restricted account to a restricted gate', () async {
      final repository = DemoAuthRepository(
        initialProfiles: [
          ProfileModel(
            id: 'restricted-user',
            email: 'restricted@example.test',
            fullName: 'Restricted User',
            role: 'tourist',
            isSuspended: true,
          ),
        ],
      );
      final controller = AuthController(repository: repository);

      final signedIn = await controller.login(
        'restricted@example.test',
        SeedDataService.demoPassword,
      );

      expect(signedIn, isTrue);
      expect(controller.status, AuthStatus.restricted);
      expect(controller.canWrite, isFalse);
    });

    test('logout clears account state', () async {
      final controller = AuthController(repository: DemoAuthRepository());
      await controller.login(
        'tourist@livelocal.com',
        SeedDataService.demoPassword,
      );

      await controller.logout();

      expect(controller.status, AuthStatus.guest);
      expect(controller.currentUser, isNull);
    });
  });

  group('Password Recovery and Demo Passwords', () {
    test('handles passwordRecovery event and updates status', () async {
      final repository = DemoAuthRepository();
      final controller = AuthController(repository: repository);
      await controller.initialize();

      expect(controller.status, AuthStatus.guest);

      // Trigger recovery event
      repository.triggerPasswordRecoveryForDemo('tourist@livelocal.com');
      await Future<void>.delayed(Duration.zero);

      expect(controller.status, AuthStatus.passwordRecovery);

      // Successfully update password
      final updateSuccess = await controller.updatePassword('NewValidPass123!');
      expect(updateSuccess, isTrue);

      // Complete reset logs out and returns to guest
      await controller.completePasswordReset('NewValidPass123!');
      expect(controller.status, AuthStatus.guest);
    });

    test(
        'newly registered Demo accounts use standard password validation and can log in with new password',
        () async {
      final repository = DemoAuthRepository();
      final controller = AuthController(repository: repository);
      await controller.initialize();

      // Attempt registration with too short password
      final shortFail = await controller.register(
        'newuser@example.com',
        'short1',
        'New User',
      );
      expect(shortFail, isFalse);
      expect(controller.errorMessage, contains('10+ characters'));

      // Register with valid password
      final success = await controller.register(
        'newuser@example.com',
        'ValidPassword123!',
        'New User',
      );
      expect(success, isTrue);
      expect(controller.currentUser?.email, 'newuser@example.com');

      // Log out
      await controller.logout();
      expect(controller.status, AuthStatus.guest);

      // Log in with wrong password
      final wrongLogin = await controller.login(
        'newuser@example.com',
        'WrongPassword123!',
      );
      expect(wrongLogin, isFalse);

      // Log in with 123456 (should fail for newly registered user who set custom password)
      final defaultFail = await controller.login(
        'newuser@example.com',
        '123456',
      );
      expect(defaultFail, isFalse);

      // Log in with the correct registered password
      final correctLogin = await controller.login(
        'newuser@example.com',
        'ValidPassword123!',
      );
      expect(correctLogin, isTrue);
      expect(controller.status, AuthStatus.authenticated);
    });

    test('seeded Demo accounts continue to accept 123456', () async {
      final repository = DemoAuthRepository();
      final controller = AuthController(repository: repository);
      await controller.initialize();

      final loginSuccess = await controller.login(
        'tourist@livelocal.com',
        SeedDataService.demoPassword,
      );
      expect(loginSuccess, isTrue);
      expect(controller.status, AuthStatus.authenticated);
    });
  });
}
