import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/validation/auth_form_validator.dart';
import '../../../models/profile_model.dart';
import '../../../services/seed_data_service.dart';
import '../domain/account_identity.dart';
import '../domain/auth_repository.dart';

class DemoAuthRepository implements AuthRepository {
  static const String _sessionKey = 'demo_auth_session';

  DemoAuthRepository({
    List<ProfileModel>? initialProfiles,
  }) : _profiles = List<ProfileModel>.of(
          initialProfiles ?? SeedDataService.getInitialProfiles(),
        );

  final List<ProfileModel> _profiles;

  final StreamController<void> _sessionController =
      StreamController<void>.broadcast();

  final StreamController<AuthSessionEvent> _authEventController =
      StreamController<AuthSessionEvent>.broadcast();

  final Map<String, AppRole> _roleOverrides = {};
  final Map<String, String> _customPasswords = {};

  AccountIdentity? _currentAccount;

  AccountIdentity? get currentAccountForDemo => _currentAccount;

  @override
  Stream<void> get sessionChanges => _sessionController.stream;

  @override
  Stream<AuthSessionEvent> get authEvents => _authEventController.stream;

  Future<void> _saveSession(
    AccountIdentity account,
  ) async {
    final preferences = await SharedPreferences.getInstance();

    final data = <String, dynamic>{
      'id': account.id,
      'email': account.email,
      'fullName': account.fullName,
      'avatarUrl': account.avatarUrl,
      'role': account.appRole.name,
      'accessStatus': account.accessStatus.name,
      'emailVerified': account.emailVerified,
      'accessReason': account.accessReason,
    };

    await preferences.setString(
      _sessionKey,
      jsonEncode(data),
    );
  }

  Future<void> _clearSavedSession() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_sessionKey);
  }

  AccountIdentity? _decodeSession(
    String? encodedSession,
  ) {
    if (encodedSession == null || encodedSession.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(encodedSession);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final id = decoded['id'];
      final email = decoded['email'];
      final fullName = decoded['fullName'];
      final role = decoded['role'];
      final accessStatus = decoded['accessStatus'];
      final emailVerified = decoded['emailVerified'];

      if (id is! String ||
          email is! String ||
          fullName is! String ||
          role is! String ||
          accessStatus is! String ||
          emailVerified is! bool) {
        return null;
      }

      final parsedAccessStatus = AccountAccessStatus.values.firstWhere(
        (status) => status.name == accessStatus,
        orElse: () => AccountAccessStatus.active,
      );

      return AccountIdentity(
        id: id,
        email: email,
        fullName: fullName,
        avatarUrl: decoded['avatarUrl'] as String?,
        role: AppRole.fromDatabase(role),
        accessStatus: parsedAccessStatus,
        emailVerified: emailVerified,
        accessReason: decoded['accessReason'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AccountIdentity?> restoreSession() async {
    if (_currentAccount != null) {
      return _currentAccount;
    }

    final preferences = await SharedPreferences.getInstance();

    final encodedSession = preferences.getString(_sessionKey);

    final restoredAccount = _decodeSession(encodedSession);

    if (restoredAccount == null) {
      await preferences.remove(_sessionKey);
      return null;
    }

    _currentAccount = restoredAccount;

    return _currentAccount;
  }

  @override
  Future<AccountIdentity> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final resolvedEmail = switch (normalizedEmail) {
      'tourist@livelocal.com' => 'tourist@gmail.com',
      'foodie@livelocal.com' => 'infuencer@gmail.com',
      'admin@livelocal.com' => 'admin@gmail.com',
      _ => normalizedEmail,
    };

    final matches = _profiles
        .where(
          (profile) => profile.email.toLowerCase() == normalizedEmail,
        )
        .toList();

    final profile = matches.isNotEmpty
        ? matches.first
        : _profiles.firstWhere(
            (p) => p.email.toLowerCase() == resolvedEmail,
            orElse: () => throw const AppException(
              code: AppErrorCode.authentication,
              userMessage: 'Invalid email or password.',
            ),
          );

    final hasCustomPassword = _customPasswords.containsKey(normalizedEmail) ||
        _customPasswords.containsKey(resolvedEmail);
    final expectedPassword = _customPasswords[normalizedEmail] ??
        _customPasswords[resolvedEmail] ??
        SeedDataService.demoPassword;

    final passwordMatches = hasCustomPassword
        ? password == expectedPassword
        : (password == expectedPassword ||
            password == '123456' ||
            password == SeedDataService.demoPassword);

    if (!passwordMatches) {
      throw const AppException(
        code: AppErrorCode.authentication,
        userMessage: 'Invalid email or password.',
      );
    }

    _currentAccount = _fromProfile(profile);

    await _saveSession(_currentAccount!);

    _sessionController.add(null);

    _authEventController.add(
      AuthSessionEvent.sessionChanged,
    );

    return _currentAccount!;
  }

  @override
  Future<AccountIdentity> registerTourist({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final passwordError = AuthFormValidator.validateRegisterPassword(
      password,
    );

    if (passwordError != null) {
      throw AppException(
        code: AppErrorCode.validation,
        userMessage: passwordError,
      );
    }

    final normalizedEmail = email.trim().toLowerCase();

    if (_profiles.any(
      (profile) => profile.email.toLowerCase() == normalizedEmail,
    )) {
      throw const AppException(
        code: AppErrorCode.conflict,
        userMessage: 'An account with this email already exists.',
      );
    }

    final profile = ProfileModel(
      id: 'demo-${DateTime.now().microsecondsSinceEpoch}',
      email: normalizedEmail,
      fullName: displayName.trim(),
      role: AppRole.tourist.name,
    );

    _profiles.add(profile);

    _customPasswords[normalizedEmail] = password;

    _currentAccount = _fromProfile(profile);

    await _saveSession(_currentAccount!);

    _sessionController.add(null);

    _authEventController.add(
      AuthSessionEvent.sessionChanged,
    );

    return _currentAccount!;
  }

  @override
  Future<void> signInWithSocial(
    SocialAuthProvider provider,
  ) async {
    throw const AppException(
      code: AppErrorCode.unavailable,
      userMessage:
          'Google sign-in is only available when connected to Supabase.',
    );
  }

  @override
  Future<void> resendVerificationEmail(
    String email,
  ) async {
    throw const AppException(
      code: AppErrorCode.unavailable,
      userMessage: 'Demo accounts are already verified. No email was sent.',
    );
  }

  @override
  Future<PasswordResetDelivery> requestPasswordReset(
    String email,
  ) async {
    if (email.trim().isEmpty) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Enter your email address.',
      );
    }

    return PasswordResetDelivery.demo;
  }

  @override
  Future<void> updatePassword(
    String newPassword,
  ) async {
    final passwordError = AuthFormValidator.validateRegisterPassword(
      newPassword,
    );

    if (passwordError != null) {
      throw AppException(
        code: AppErrorCode.validation,
        userMessage: passwordError,
      );
    }

    final email = _currentAccount?.email.toLowerCase();

    if (email != null) {
      _customPasswords[email] = newPassword;
    }
  }

  void triggerPasswordRecoveryForDemo(
    String email,
  ) {
    final normalizedEmail = email.trim().toLowerCase();
    final resolvedEmail = switch (normalizedEmail) {
      'tourist@livelocal.com' => 'tourist@gmail.com',
      'foodie@livelocal.com' => 'infuencer@gmail.com',
      'admin@livelocal.com' => 'admin@gmail.com',
      _ => normalizedEmail,
    };

    final profile = _profiles.firstWhere(
      (profile) =>
          profile.email.toLowerCase() == resolvedEmail ||
          profile.email.toLowerCase() == normalizedEmail,
      orElse: () => ProfileModel(
        id: 'demo-recovery',
        email: normalizedEmail,
        fullName: 'Demo Recovery User',
        role: AppRole.tourist.name,
      ),
    );

    _currentAccount = _fromProfile(profile);

    _authEventController.add(
      AuthSessionEvent.passwordRecovery,
    );
  }

  @override
  Future<void> signOut() async {
    _currentAccount = null;

    await _clearSavedSession();

    _sessionController.add(null);

    _authEventController.add(
      AuthSessionEvent.sessionChanged,
    );
  }

  @override
  Future<AccountIdentity> refreshAccount() async {
    final current = _currentAccount;

    if (current == null) {
      throw const AppException(
        code: AppErrorCode.authentication,
        userMessage: 'Sign in to continue.',
      );
    }

    return current;
  }

  AccountIdentity _fromProfile(
    ProfileModel profile,
  ) {
    return AccountIdentity(
      id: profile.id,
      email: profile.email,
      fullName: profile.fullName,
      avatarUrl: profile.avatarUrl,
      role: _roleOverrides[profile.id] ?? AppRole.fromDatabase(profile.role),
      accessStatus: profile.isSuspended
          ? AccountAccessStatus.restricted
          : AccountAccessStatus.active,
      emailVerified: true,
      accessReason: profile.isSuspended
          ? 'This demo account is temporarily restricted.'
          : null,
    );
  }

  AccountIdentity replaceAccountForDemo(
    AccountIdentity account,
  ) {
    _currentAccount = account;

    unawaited(
      _saveSession(account),
    );

    _sessionController.add(null);

    return account;
  }

  void grantRoleForDemo(
    String userId,
    AppRole role,
  ) {
    _roleOverrides[userId] = role;

    if (_currentAccount?.id == userId) {
      _currentAccount = _currentAccount!.copyWith(
        role: role,
      );

      unawaited(
        _saveSession(_currentAccount!),
      );

      _sessionController.add(null);
    }
  }
}
