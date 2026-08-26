import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/guide_controller.dart';
import 'package:live_local/controllers/itinerary_controller.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/moderation_controller.dart';
import 'package:live_local/controllers/notification_controller.dart';
import 'package:live_local/controllers/review_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/config/app_environment.dart';
import 'package:live_local/core/localization/app_localizations.dart';
import 'package:live_local/core/routing/protected_navigation.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/auth/domain/account_identity.dart';
import 'package:live_local/features/auth/domain/auth_repository.dart';
import 'package:live_local/features/auth/presentation/session_gate.dart';
import 'package:live_local/features/guides/data/demo_guide_repository.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/moderation/data/demo_moderation_repository.dart';
import 'package:live_local/features/notifications/data/demo_notification_repository.dart';
import 'package:live_local/features/profile/data/demo_account_repository.dart';
import 'package:live_local/features/profile/presentation/account_controller.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/reviews/data/demo_review_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:provider/provider.dart';

class _FakeAuthRepository extends DemoAuthRepository {
  _FakeAuthRepository({AccountIdentity? initialAccount})
      : _currentAccount = initialAccount;

  AccountIdentity? _currentAccount;
  final StreamController<AuthSessionEvent> _authEventsController =
      StreamController<AuthSessionEvent>.broadcast();

  void setAccount(AccountIdentity? account) {
    _currentAccount = account;
    _authEventsController.add(AuthSessionEvent.sessionChanged);
  }

  @override
  Stream<void> get sessionChanges => _authEventsController.stream.map((_) {});

  @override
  Stream<AuthSessionEvent> get authEvents => _authEventsController.stream;

  @override
  Future<AccountIdentity?> restoreSession() async => _currentAccount;

  @override
  Future<AccountIdentity> refreshAccount() async {
    if (_currentAccount == null) throw Exception('No session');
    return _currentAccount!;
  }

  @override
  Future<AccountIdentity> signIn({
    required String email,
    required String password,
  }) async {
    return _currentAccount!;
  }

  @override
  Future<AccountIdentity> registerTourist({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _currentAccount = AccountIdentity(
      id: 'test-user',
      email: email,
      fullName: displayName,
      role: AppRole.tourist,
      accessStatus: AccountAccessStatus.active,
      emailVerified: false,
    );
    return _currentAccount!;
  }

  @override
  Future<void> resendVerificationEmail(String email) async {}

  @override
  Future<PasswordResetDelivery> requestPasswordReset(String email) async =>
      PasswordResetDelivery.email;

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> signOut() async {
    _currentAccount = null;
    _authEventsController.add(AuthSessionEvent.sessionChanged);
  }
}

void main() {
  Widget buildTestApp({
    required AuthController authController,
    required _FakeAuthRepository authRepository,
    required Widget child,
    void Function()? onLoginPushed,
  }) {
    final accountRepository = DemoAccountRepository(authRepository);
    final spotRepository = DemoSpotRepository(authRepository);
    final localEatsRepository = DemoLocalEatsRepository(authRepository);
    final guideRepository = DemoGuideRepository(authRepository);
    final reviewRepository = DemoReviewRepository(authRepository);
    final itineraryRepository = DemoSavedItineraryRepository(authRepository);
    final notificationRepository = DemoNotificationRepository(authRepository);
    final moderationRepository = DemoModerationRepository(authRepository);

    final accountController = AccountController(
      repository: accountRepository,
      authController: authController,
    );
    final spotController = SpotController(repository: spotRepository);
    final localEatsController =
        LocalEatsController(repository: localEatsRepository);
    final guideController = GuideController(repository: guideRepository);
    final reviewController = ReviewController(repository: reviewRepository);
    final itineraryController =
        ItineraryController(repository: itineraryRepository);
    final notificationController =
        NotificationController(repository: notificationRepository);
    final moderationController =
        ModerationController(repository: moderationRepository);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppLocaleController()),
        ChangeNotifierProvider.value(value: authController),
        ChangeNotifierProvider.value(value: accountController),
        ChangeNotifierProvider.value(value: spotController),
        ChangeNotifierProvider.value(value: localEatsController),
        ChangeNotifierProvider.value(value: guideController),
        ChangeNotifierProvider.value(value: reviewController),
        ChangeNotifierProvider.value(value: itineraryController),
        ChangeNotifierProvider.value(value: notificationController),
        ChangeNotifierProvider.value(value: moderationController),
        Provider.value(value: AppConfiguration.demoForTesting()),
        Provider(create: (_) => ProtectedNavigation()),
      ],
      child: MaterialApp(
        routes: {
          '/login': (context) {
            onLoginPushed?.call();
            return const Scaffold(body: Text('Login Screen Mock'));
          },
        },
        home: child,
      ),
    );
  }

  group('Email verification auto-refresh and navigation', () {
    test(
        'unverified account stays in verificationRequired and transitions to authenticated when verified',
        () async {
      final repo = _FakeAuthRepository(
        initialAccount: const AccountIdentity(
          id: 'user-1',
          email: 'unconfirmed@example.com',
          fullName: 'Test User',
          role: AppRole.tourist,
          accessStatus: AccountAccessStatus.active,
          emailVerified: false,
        ),
      );
      final controller = AuthController(repository: repo);
      await controller.initialize();

      expect(controller.status, AuthStatus.verificationRequired);
      expect(controller.pendingVerificationEmail, 'unconfirmed@example.com');

      // Simulate backend email confirmation happening out-of-band
      repo.setAccount(
        const AccountIdentity(
          id: 'user-1',
          email: 'unconfirmed@example.com',
          fullName: 'Test User',
          role: AppRole.tourist,
          accessStatus: AccountAccessStatus.active,
          emailVerified: true,
        ),
      );

      // Trigger verification check (e.g. on resume or auth change)
      await controller.checkEmailVerification();

      expect(controller.status, AuthStatus.authenticated);
      expect(controller.pendingVerificationEmail, isNull);
    });

    testWidgets('Use a different account logs out and navigates to /login',
        (tester) async {
      final repo = _FakeAuthRepository(
        initialAccount: const AccountIdentity(
          id: 'user-1',
          email: 'unconfirmed@example.com',
          fullName: 'Test User',
          role: AppRole.tourist,
          accessStatus: AccountAccessStatus.active,
          emailVerified: false,
        ),
      );
      final authController = AuthController(repository: repo);
      await authController.initialize();

      var loginRoutePushed = false;

      await tester.pumpWidget(
        buildTestApp(
          authController: authController,
          authRepository: repo,
          onLoginPushed: () => loginRoutePushed = true,
          child: const EmailVerificationScreen(),
        ),
      );

      await tester.pump();

      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.text('Check your inbox'), findsOneWidget);
      expect(find.text('Use a different account'), findsOneWidget);

      await tester.tap(find.text('Use a different account'));
      await tester.pumpAndSettle();

      expect(loginRoutePushed, isTrue);
      expect(find.text('Login Screen Mock'), findsOneWidget);
      expect(authController.status, AuthStatus.guest);
      expect(authController.currentUser, isNull);
    });

    testWidgets('Resuming app triggers checkEmailVerification', (tester) async {
      final repo = _FakeAuthRepository(
        initialAccount: const AccountIdentity(
          id: 'user-1',
          email: 'unconfirmed@example.com',
          fullName: 'Test User',
          role: AppRole.tourist,
          accessStatus: AccountAccessStatus.active,
          emailVerified: false,
        ),
      );
      final authController = AuthController(repository: repo);
      await authController.initialize();

      await tester.pumpWidget(
        buildTestApp(
          authController: authController,
          authRepository: repo,
          child: const SessionGate(),
        ),
      );

      await tester.pump();
      expect(find.text('Check your inbox'), findsOneWidget);

      // Mark account as verified in backend
      repo.setAccount(
        const AccountIdentity(
          id: 'user-1',
          email: 'unconfirmed@example.com',
          fullName: 'Test User',
          role: AppRole.tourist,
          accessStatus: AccountAccessStatus.active,
          emailVerified: true,
        ),
      );

      // Simulate app lifecycle resume
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(authController.status, AuthStatus.authenticated);
      expect(find.text('Check your inbox'), findsNothing);
    });
  });
}
