import 'account_identity.dart';

enum PasswordResetDelivery { email, demo }

enum AuthSessionEvent {
  sessionChanged,
  passwordRecovery,
}

abstract interface class AuthRepository {
  Stream<void> get sessionChanges;

  Stream<AuthSessionEvent> get authEvents;

  Future<AccountIdentity?> restoreSession();

  Future<AccountIdentity> signIn({
    required String email,
    required String password,
  });

  Future<AccountIdentity> registerTourist({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> resendVerificationEmail(String email);

  Future<PasswordResetDelivery> requestPasswordReset(String email);

  Future<void> updatePassword(String newPassword);

  Future<void> signOut();

  Future<AccountIdentity> refreshAccount();
}
