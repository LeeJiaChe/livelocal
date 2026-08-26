import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/admin_controller.dart';
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
import 'package:live_local/features/admin/data/demo_admin_repository.dart';
import 'package:live_local/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/auth/domain/account_identity.dart';
import 'package:live_local/features/auth/domain/auth_repository.dart';
import 'package:live_local/features/auth/presentation/auth_navigation_coordinator.dart';
import 'package:live_local/features/auth/presentation/password_reset_screen.dart';
import 'package:live_local/features/auth/presentation/session_gate.dart';
import 'package:live_local/features/auth/presentation/set_new_password_screen.dart';
import 'package:live_local/features/guides/data/demo_guide_repository.dart';
import 'package:live_local/features/influencer_applications/data/demo_influencer_application_repository.dart';
import 'package:live_local/features/influencer_applications/presentation/influencer_application_controller.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/moderation/data/demo_moderation_repository.dart';
import 'package:live_local/features/notifications/data/demo_notification_repository.dart';
import 'package:live_local/features/profile/data/demo_account_repository.dart';
import 'package:live_local/features/profile/presentation/account_controller.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/reviews/data/demo_review_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/screens/login_screen.dart';
import 'package:live_local/screens/main_navigation_screen.dart';
import 'package:live_local/screens/register_screen.dart';
import 'package:provider/provider.dart';

class _FakeAuthRepository extends DemoAuthRepository {
  _FakeAuthRepository({AccountIdentity? initialAccount})
      : _currentAccount = initialAccount;

  AccountIdentity? _currentAccount;
  final StreamController<AuthSessionEvent> _authEventsController =
      StreamController<AuthSessionEvent>.broadcast();

  void triggerPasswordRecovery() {
    _authEventsController.add(AuthSessionEvent.passwordRecovery);
  }

  void setAccount(AccountIdentity account) {
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
    _currentAccount = AccountIdentity(
      id: 'logged-in-user',
      email: email,
      fullName: 'Tourist User',
      role: AppRole.tourist,
      accessStatus: AccountAccessStatus.active,
      emailVerified: true,
    );
    return _currentAccount!;
  }

  @override
  Future<AccountIdentity> registerTourist({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _currentAccount = AccountIdentity(
      id: 'new-user',
      email: email,
      fullName: displayName,
      role: AppRole.tourist,
      accessStatus: AccountAccessStatus.active,
      emailVerified: false,
    );
    return _currentAccount!;
  }

  @override
  Future<void> signOut() async {
    _currentAccount = null;
  }
}

Widget _buildTestApp({
  required AuthController authController,
  required _FakeAuthRepository authRepository,
  ProtectedNavigation? protectedNavigation,
  GlobalKey<NavigatorState>? navigatorKey,
  Widget? home,
  String? initialRoute,
}) {
  final navKey = navigatorKey ?? GlobalKey<NavigatorState>();
  final protectedNav = protectedNavigation ?? ProtectedNavigation();
  final accountRepository = DemoAccountRepository(authRepository);
  final spotRepository = DemoSpotRepository(authRepository);
  final localEatsRepository = DemoLocalEatsRepository(authRepository);
  final guideRepository = DemoGuideRepository(authRepository);
  final reviewRepository = DemoReviewRepository(authRepository);
  final itineraryRepository = DemoSavedItineraryRepository(authRepository);
  final notificationRepository = DemoNotificationRepository(authRepository);
  final moderationRepository = DemoModerationRepository(authRepository);
  final adminRepository =
      DemoAdminRepository(authRepository, accountRepository);
  final influencerRepository =
      DemoInfluencerApplicationRepository(authRepository);

  return MultiProvider(
    providers: [
      Provider<AppConfiguration>.value(
        value: AppConfiguration.demoForTesting(),
      ),
      ChangeNotifierProvider(create: (_) => AppLocaleController()),
      Provider<ProtectedNavigation>.value(value: protectedNav),
      ChangeNotifierProvider<AuthController>.value(value: authController),
      ChangeNotifierProvider(
        create: (_) => AccountController(
          repository: accountRepository,
          authController: authController,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => SpotController(repository: spotRepository),
      ),
      ChangeNotifierProvider(
        create: (_) => LocalEatsController(repository: localEatsRepository),
      ),
      ChangeNotifierProvider(
        create: (_) => GuideController(repository: guideRepository),
      ),
      ChangeNotifierProvider(
        create: (_) => ReviewController(repository: reviewRepository),
      ),
      ChangeNotifierProvider(
        create: (_) => ItineraryController(repository: itineraryRepository),
      ),
      ChangeNotifierProvider(
        create: (_) =>
            NotificationController(repository: notificationRepository),
      ),
      ChangeNotifierProvider(
        create: (_) => ModerationController(repository: moderationRepository),
      ),
      ChangeNotifierProvider(
        create: (_) => AdminController(repository: adminRepository),
      ),
      ChangeNotifierProvider(
        create: (_) => InfluencerApplicationController(
          repository: influencerRepository,
        ),
      ),
    ],
    child: AuthNavigationCoordinator(
      navigatorKey: navKey,
      child: MaterialApp(
        navigatorKey: navKey,
        home: home,
        initialRoute: initialRoute,
        routes: {
          '/home': (context) => const SessionGate(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/password-reset': (context) => const PasswordResetScreen(),
          '/submit-spot': (context) =>
              const Scaffold(body: Text('Submit Spot Target Screen')),
          '/set-new-password': (context) => const SetNewPasswordScreen(),
        },
      ),
    ),
  );
}

void main() {
  group('App Navigation Flow Tests', () {
    testWidgets('1. Login -> Register uses replacement so stack does not loop',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeAuthRepository();
      final authCtrl = AuthController(repository: repo);
      await authCtrl.initialize();

      await tester.pumpWidget(
        _buildTestApp(
          authController: authCtrl,
          authRepository: repo,
          home: const LoginScreen(),
        ),
      );

      await tester.pump();
      expect(find.byType(LoginScreen), findsOneWidget);

      // Tap 'Sign up' link
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Tap 'Log in' link back
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(RegisterScreen), findsNothing);
    });

    testWidgets('2. Guest protected action -> Login -> Target resumes',
        (tester) async {
      final repo = _FakeAuthRepository();
      final authCtrl = AuthController(repository: repo);
      await authCtrl.initialize();
      final protectedNav = ProtectedNavigation();

      await tester.pumpWidget(
        _buildTestApp(
          authController: authCtrl,
          authRepository: repo,
          protectedNavigation: protectedNav,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    protectedNav.open(context, '/submit-spot');
                  },
                  child: const Text('Add Spot Action'),
                ),
              );
            },
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Add Spot Action'), findsOneWidget);

      // Tap protected button
      await tester.tap(find.text('Add Spot Action'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Should have routed to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);

      // Fill in credentials and log in
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'tourist@example.com');
      await tester.enterText(fields.last, 'ValidPass123!');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Target protected route (/submit-spot) resumes
      expect(find.text('Submit Spot Target Screen'), findsOneWidget);
      expect(protectedNav.hasPending, isFalse);
    });

    testWidgets(
        '3. Guest protected action -> Register -> Email verification -> Verify -> Target resumes',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeAuthRepository();
      final authCtrl = AuthController(repository: repo);
      await authCtrl.initialize();
      final protectedNav = ProtectedNavigation();

      await tester.pumpWidget(
        _buildTestApp(
          authController: authCtrl,
          authRepository: repo,
          protectedNavigation: protectedNav,
          home: const SessionGate(),
        ),
      );

      await tester.pump();

      // Trigger protected navigation
      final context = tester.element(find.byType(SessionGate));
      protectedNav.open(context, '/submit-spot');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);

      // Switch to Register
      await tester.tap(find.text('Sign up'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);

      // Fill registration form
      final registerFields = find.descendant(
        of: find.byType(RegisterScreen),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(registerFields.at(0), 'Pending User');
      await tester.enterText(registerFields.at(1), 'pending@example.com');
      await tester.enterText(registerFields.at(2), 'SecurePass123!');
      await tester.enterText(registerFields.at(3), 'SecurePass123!');
      final createButton =
          find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Lands on EmailVerificationScreen because emailVerified is false
      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);

      // Simulate backend email verification confirmation
      repo.setAccount(
        const AccountIdentity(
          id: 'new-user',
          email: 'pending@example.com',
          fullName: 'Pending User',
          role: AppRole.tourist,
          accessStatus: AccountAccessStatus.active,
          emailVerified: true,
        ),
      );

      // Trigger resume check
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Target protected route resumes after email verification!
      expect(find.text('Submit Spot Target Screen'), findsOneWidget);
      expect(protectedNav.hasPending, isFalse);
    });

    testWidgets('4. Abandoning protected login clears stale pending target',
        (tester) async {
      final repo = _FakeAuthRepository();
      final authCtrl = AuthController(repository: repo);
      await authCtrl.initialize();
      final protectedNav = ProtectedNavigation();

      await tester.pumpWidget(
        _buildTestApp(
          authController: authCtrl,
          authRepository: repo,
          protectedNavigation: protectedNav,
          home: const SessionGate(),
        ),
      );

      await tester.pump();

      // Open protected route
      final context = tester.element(find.byType(SessionGate));
      protectedNav.open(context, '/submit-spot');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);

      // Tap back button to abandon login
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Returns to SessionGate / MainNavigationScreen and pending is cleared
      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(protectedNav.hasPending, isFalse);
    });

    testWidgets(
        '4A. System back on Login clears abandoned pending navigation (tester.binding.handlePopRoute)',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeAuthRepository();
      final authCtrl = AuthController(repository: repo);
      await authCtrl.initialize();
      final protectedNav = ProtectedNavigation();

      await tester.pumpWidget(
        _buildTestApp(
          authController: authCtrl,
          authRepository: repo,
          protectedNavigation: protectedNav,
          home: const SessionGate(),
        ),
      );
      await tester.pump();

      // Trigger protected navigation
      final context = tester.element(find.byType(SessionGate));
      protectedNav.open(context, '/submit-spot');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);

      // Simulate Android system back gesture/button
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Returns to SessionGate / MainNavigationScreen and pending is cleared
      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(protectedNav.hasPending, isFalse);
    });

    testWidgets(
        '4B. System back from Register after switching clears pending navigation',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeAuthRepository();
      final authCtrl = AuthController(repository: repo);
      await authCtrl.initialize();
      final protectedNav = ProtectedNavigation();

      await tester.pumpWidget(
        _buildTestApp(
          authController: authCtrl,
          authRepository: repo,
          protectedNavigation: protectedNav,
          home: const SessionGate(),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(SessionGate));
      protectedNav.open(context, '/submit-spot');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);

      // Switch to Register (using replacement)
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);

      // System back from Register (since replacement was used, system back goes to root /home)
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(protectedNav.hasPending, isFalse);
    });

    testWidgets(
        '4C. Switching between Login and Register preserves pending navigation',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeAuthRepository();
      final authCtrl = AuthController(repository: repo);
      await authCtrl.initialize();
      final protectedNav = ProtectedNavigation();

      await tester.pumpWidget(
        _buildTestApp(
          authController: authCtrl,
          authRepository: repo,
          protectedNavigation: protectedNav,
          home: const SessionGate(),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(SessionGate));
      protectedNav.open(context, '/submit-spot');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);

      // Switch to Register
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);

      // Switch back to Login
      final logInLink = find.text('Log in');
      await tester.ensureVisible(logInLink);
      await tester.tap(logInLink);
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);
    });

    testWidgets('5. Password recovery does not consume pending protected route',
        (tester) async {
      final repo = _FakeAuthRepository();
      final authCtrl = AuthController(repository: repo);
      await authCtrl.initialize();
      final protectedNav = ProtectedNavigation();

      await tester.pumpWidget(
        _buildTestApp(
          authController: authCtrl,
          authRepository: repo,
          protectedNavigation: protectedNav,
          home: const SessionGate(),
        ),
      );

      await tester.pump();

      // Simulate a pending navigation existing
      final context = tester.element(find.byType(SessionGate));
      protectedNav.open(context, '/submit-spot');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(protectedNav.hasPending, isTrue);

      // Trigger password recovery event
      repo.triggerPasswordRecovery();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Password recovery status active
      expect(authCtrl.status, AuthStatus.passwordRecovery);
      // Pending navigation is untouched/not consumed
      expect(protectedNav.hasPending, isTrue);
    });

    testWidgets(
        'Recovery Test 1: Password recovery event while PasswordResetScreen is top routes directly to SetNewPasswordScreen',
        (tester) async {
      final repo = _FakeAuthRepository();
      final authCtrl = AuthController(repository: repo);
      await authCtrl.initialize();
      final protectedNav = ProtectedNavigation();
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        _buildTestApp(
          authController: authCtrl,
          authRepository: repo,
          protectedNavigation: protectedNav,
          navigatorKey: navKey,
          home: const SessionGate(),
        ),
      );
      await tester.pump();

      // Open protected route to have pending action
      final context = tester.element(find.byType(SessionGate));
      protectedNav.open(context, '/submit-spot');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      // Navigate to /password-reset
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.byType(PasswordResetScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);

      // User opens link from email -> emit passwordRecovery
      repo.triggerPasswordRecovery();
      await tester.pumpAndSettle();

      // SetNewPasswordScreen is active and visible
      expect(find.byType(SetNewPasswordScreen), findsOneWidget);
      expect(find.byType(PasswordResetScreen), findsNothing);
      expect(find.text('Create new password'), findsOneWidget);

      // Pending action is untouched
      expect(protectedNav.hasPending, isTrue);
    });

    testWidgets(
        'Recovery Test 2: Password recovery event while LoginScreen is top routes directly to SetNewPasswordScreen',
        (tester) async {
      final repo = _FakeAuthRepository();
      final authCtrl = AuthController(repository: repo);
      await authCtrl.initialize();
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        _buildTestApp(
          authController: authCtrl,
          authRepository: repo,
          navigatorKey: navKey,
          home: const SessionGate(),
        ),
      );
      await tester.pump();

      // Navigate to /login
      navKey.currentState?.pushNamed('/login');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      // Trigger recovery
      repo.triggerPasswordRecovery();
      await tester.pumpAndSettle();

      expect(find.byType(SetNewPasswordScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets(
        'Recovery Test 3: Multiple passwordRecovery events do not push duplicate screens',
        (tester) async {
      final repo = _FakeAuthRepository();
      final authCtrl = AuthController(repository: repo);
      await authCtrl.initialize();
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        _buildTestApp(
          authController: authCtrl,
          authRepository: repo,
          navigatorKey: navKey,
          home: const SessionGate(),
        ),
      );
      await tester.pump();

      navKey.currentState?.pushNamed('/login');
      await tester.pumpAndSettle();

      // Emit twice
      repo.triggerPasswordRecovery();
      await tester.pumpAndSettle();
      repo.triggerPasswordRecovery();
      await tester.pumpAndSettle();

      expect(find.byType(SetNewPasswordScreen), findsOneWidget);
    });

    testWidgets(
        'Recovery Test 4: Completing password reset logs out and navigates to LoginScreen',
        (tester) async {
      final repo = _FakeAuthRepository();
      final authCtrl = AuthController(repository: repo);
      await authCtrl.initialize();
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        _buildTestApp(
          authController: authCtrl,
          authRepository: repo,
          navigatorKey: navKey,
          home: const SessionGate(),
        ),
      );
      await tester.pump();

      repo.triggerPasswordRecovery();
      await tester.pumpAndSettle();

      expect(find.byType(SetNewPasswordScreen), findsOneWidget);

      // Enter matching valid passwords (10+ chars, letter and number)
      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(0), 'BrandNewPass123!');
      await tester.enterText(passwordFields.at(1), 'BrandNewPass123!');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Update Password'));
      await tester.pumpAndSettle();

      // After update, user is redirected to /login and SetNewPasswordScreen is gone
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SetNewPasswordScreen), findsNothing);
    });

    testWidgets('6. Admin account enters AdminDashboardScreen directly',
        (tester) async {
      final repo = _FakeAuthRepository(
        initialAccount: const AccountIdentity(
          id: 'admin-1',
          email: 'admin@livelocal.com',
          fullName: 'Admin User',
          role: AppRole.admin,
          accessStatus: AccountAccessStatus.active,
          emailVerified: true,
        ),
      );
      final authCtrl = AuthController(repository: repo);
      await authCtrl.initialize();

      await tester.pumpWidget(
        _buildTestApp(
          authController: authCtrl,
          authRepository: repo,
          home: const SessionGate(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(find.byType(MainNavigationScreen), findsNothing);
    });

    testWidgets('7. Guest enters MainNavigationScreen directly',
        (tester) async {
      final repo = _FakeAuthRepository();
      final authCtrl = AuthController(repository: repo);
      await authCtrl.initialize();

      await tester.pumpWidget(
        _buildTestApp(
          authController: authCtrl,
          authRepository: repo,
          home: const SessionGate(),
        ),
      );

      await tester.pump();

      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.text('Spots'), findsOneWidget);
      expect(find.text('Eats'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Guides'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });
}
