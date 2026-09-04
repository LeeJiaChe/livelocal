import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/account_identity.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required SupabaseClient client,
    required Uri redirectUrl,
  })  : _client = client,
        _redirectUrl = redirectUrl;

  final SupabaseClient _client;
  final Uri _redirectUrl;

  @override
  Stream<void> get sessionChanges =>
      _client.auth.onAuthStateChange.map<void>((_) {});

  @override
  Stream<AuthSessionEvent> get authEvents =>
      _client.auth.onAuthStateChange.map<AuthSessionEvent>((data) {
        if (data.event == AuthChangeEvent.passwordRecovery) {
          return AuthSessionEvent.passwordRecovery;
        }

        return AuthSessionEvent.sessionChanged;
      });

  @override
  Future<AccountIdentity?> restoreSession() async {
    final session = _client.auth.currentSession;
    final cachedUser = _client.auth.currentUser;

    if (session == null && cachedUser == null) {
      return null;
    }

    User? user;

    try {
      final response = await _client.auth.getUser();
      user = response.user ?? _client.auth.currentUser;
    } catch (_) {
      user = _client.auth.currentUser;
    }

    if (user == null) {
      return null;
    }

    return _loadAccount(user);
  }

  @override
  Future<AccountIdentity> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;

      if (user == null) {
        throw const AppException(
          code: AppErrorCode.authentication,
          userMessage: 'Invalid email or password.',
        );
      }

      return await _loadAccount(user);
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  @override
  Future<AccountIdentity> registerTourist({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: _redirectUrl.toString(),
        data: <String, dynamic>{
          'display_name': displayName.trim(),
        },
      );

      final user = response.user;

      if (user == null) {
        throw const AppException(
          code: AppErrorCode.unexpected,
          userMessage: 'The account could not be created. Try again.',
        );
      }

      if (response.session == null) {
        return AccountIdentity(
          id: user.id,
          email: user.email ?? email.trim(),
          fullName: displayName.trim(),
          role: AppRole.tourist,
          accessStatus: AccountAccessStatus.active,
          emailVerified: false,
        );
      }

      return await _loadAccount(user);
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  @override
  Future<void> resendVerificationEmail(
    String email,
  ) async {
    if (email.trim().isEmpty) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Enter your email address.',
      );
    }

    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
        emailRedirectTo: _redirectUrl.toString(),
      );
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  @override
  Future<PasswordResetDelivery> requestPasswordReset(
    String email,
  ) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: _redirectUrl.toString(),
      );

      return PasswordResetDelivery.email;
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  @override
  Future<void> updatePassword(
    String newPassword,
  ) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  @override
  Future<void> signInWithSocial(
    SocialAuthProvider provider,
  ) async {
    try {
      late final OAuthProvider supabaseProvider;

      switch (provider) {
        case SocialAuthProvider.google:
          supabaseProvider = OAuthProvider.google;
          break;
      }

      final launched = await _client.auth.signInWithOAuth(
        supabaseProvider,
        redirectTo: _redirectUrl.toString(),
      );

      if (!launched) {
        throw const AppException(
          code: AppErrorCode.authentication,
          userMessage: 'Google sign-in could not be started.',
        );
      }
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut(
        scope: SignOutScope.global,
      );
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    }
  }

  @override
  Future<AccountIdentity> refreshAccount() async {
    User? user;

    try {
      final response = await _client.auth.getUser();
      user = response.user ?? _client.auth.currentUser;
    } catch (_) {
      user = _client.auth.currentUser;
    }

    if (user == null) {
      throw const AppException(
        code: AppErrorCode.authentication,
        userMessage: 'Your session has expired. Sign in again.',
      );
    }

    return _loadAccount(user);
  }

  Future<AccountIdentity> _loadAccount(
    User user,
  ) async {
    try {
      final response = await _client.rpc<Object?>(
        'get_my_account',
      );

      if (response is! Map<String, dynamic>) {
        throw const AppException(
          code: AppErrorCode.unexpected,
          userMessage: 'Your account could not be loaded.',
          technicalMessage: 'get_my_account returned an invalid payload.',
        );
      }

      return AccountIdentity(
        id: user.id,
        email: user.email ?? '',
        fullName: response['display_name'] as String? ?? '',
        avatarUrl: publicAvatarUrl(
          response['avatar_url'] as String?,
        ),
        role: AppRole.fromDatabase(
          response['role'] as String?,
        ),
        accessStatus: AccountAccessStatus.fromDatabase(
          response['access_status'] as String?,
        ),
        emailVerified: user.emailConfirmedAt != null,
        accessReason: response['access_message'] as String?,
        accessEndsAt: _parseDate(
          response['access_ends_at'],
        ),
        deletionScheduledFor: _parseDate(
          response['deletion_scheduled_for'],
        ),
        accessDecisionId: response['access_decision_id'] as String?,
      );
    } on PostgrestException catch (error) {
      throw AppException(
        code: AppErrorCode.unexpected,
        userMessage: 'Your account could not be loaded. Please try again.',
        technicalMessage: error.message,
        cause: error,
      );
    }
  }

  String? publicAvatarUrl(
    String? path,
  ) {
    if (path == null || path.isEmpty) {
      return null;
    }

    if (Uri.tryParse(path)?.hasScheme ?? false) {
      return path;
    }

    return _client.storage.from('avatars').getPublicUrl(path);
  }

  DateTime? _parseDate(
    Object? value,
  ) {
    if (value is! String) {
      return null;
    }

    return DateTime.tryParse(value)?.toLocal();
  }

  AppException _mapAuthException(
    AuthException error,
  ) {
    final normalized = error.message.toLowerCase();

    if (normalized.contains('invalid login') ||
        normalized.contains('invalid credentials')) {
      return AppException(
        code: AppErrorCode.authentication,
        userMessage: 'Invalid email or password.',
        technicalMessage: error.message,
        cause: error,
      );
    }

    if (normalized.contains('network') || normalized.contains('socket')) {
      return AppException(
        code: AppErrorCode.network,
        userMessage: 'Check your connection and try again.',
        technicalMessage: error.message,
        cause: error,
      );
    }

    if (normalized.contains('email not confirmed')) {
      return AppException(
        code: AppErrorCode.emailNotVerified,
        userMessage: 'Verify your email before signing in.',
        technicalMessage: error.message,
        cause: error,
      );
    }

    if (normalized.contains('already registered') ||
        normalized.contains('already exists')) {
      return AppException(
        code: AppErrorCode.conflict,
        userMessage: 'This email is already registered. Try signing in.',
        technicalMessage: error.message,
        cause: error,
      );
    }

    return AppException(
      code: AppErrorCode.authentication,
      userMessage:
          'Authentication could not be completed. Check your details and try again.',
      technicalMessage: error.message,
      cause: error,
    );
  }
}
