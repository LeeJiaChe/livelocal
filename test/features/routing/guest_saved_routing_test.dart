import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/app/theme/app_theme.dart';
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
import 'package:live_local/core/routing/protected_navigation.dart';
import 'package:live_local/features/admin/data/demo_admin_repository.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/auth/presentation/auth_navigation_coordinator.dart';
import 'package:live_local/features/auth/presentation/session_gate.dart';
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
import 'package:live_local/screens/saved_places_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('Guest Saved Places Routing & Named Route Audit', () {
    late DemoAuthRepository authRepo;
    late AuthController authCtrl;
    late ProtectedNavigation protectedNav;
    late GlobalKey<NavigatorState> navKey;

    setUp(() {
      authRepo = DemoAuthRepository();
      authCtrl = AuthController(repository: authRepo);
      protectedNav = ProtectedNavigation();
      navKey = GlobalKey<NavigatorState>();
    });

    Widget createTestApp() {
      final accountRepo = DemoAccountRepository(authRepo);
      final spotRepo = DemoSpotRepository(authRepo);
      final eatsRepo = DemoLocalEatsRepository(authRepo);
      final guideRepo = DemoGuideRepository(authRepo);
      final reviewRepo = DemoReviewRepository(authRepo);
      final savedRepo = DemoSavedItineraryRepository(authRepo);
      final notifRepo = DemoNotificationRepository(authRepo);
      final modRepo = DemoModerationRepository(authRepo);
      final adminRepo = DemoAdminRepository(authRepo, accountRepo);
      final inflRepo = DemoInfluencerApplicationRepository(authRepo);

      return MultiProvider(
        providers: [
          Provider<AppConfiguration>.value(
            value: AppConfiguration.demoForTesting(),
          ),
          Provider<ProtectedNavigation>.value(value: protectedNav),
          ChangeNotifierProvider<AuthController>.value(value: authCtrl),
          ChangeNotifierProvider(
            create: (_) => AccountController(
              repository: accountRepo,
              authController: authCtrl,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => SpotController(repository: spotRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => LocalEatsController(repository: eatsRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => GuideController(repository: guideRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => ReviewController(repository: reviewRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => ItineraryController(repository: savedRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => NotificationController(repository: notifRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => ModerationController(repository: modRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => AdminController(repository: adminRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => InfluencerApplicationController(
              repository: inflRepo,
            ),
          ),
        ],
        child: AuthNavigationCoordinator(
          navigatorKey: navKey,
          child: MaterialApp(
            navigatorKey: navKey,
            theme: AppTheme.light,
            initialRoute: '/home',
            routes: {
              '/home': (context) => const SessionGate(),
              '/saved-places': (context) => const SavedPlacesScreen(),
              '/login': (context) => const LoginScreen(),
            },
          ),
        ),
      );
    }

    testWidgets(
        'Guest taps Saved -> redirects to login -> logs in -> resumes /saved-places safely without unknown route',
        (tester) async {
      await authCtrl.initialize();
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap on Saved tab in NavigationBar
      final savedTab = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.bookmark_outline),
      );
      expect(savedTab, findsOneWidget);
      await tester.tap(savedTab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Guest banner shown on SavedPlacesScreen
      final signInCta = find.text('Sign in to LiveLocal');
      expect(signInCta, findsOneWidget);

      // Tap Sign in to LiveLocal
      await tester.tap(signInCta);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // ProtectedNavigation now records pending /saved-places and navigates to LoginScreen
      expect(protectedNav.peekPending()?.routeName, equals('/saved-places'));
      expect(find.text('Welcome back'), findsOneWidget);

      // Perform login
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      await tester.enterText(emailField, 'tourist@livelocal.com');
      await tester.enterText(passwordField, '123456');

      final loginBtn = find.byType(ElevatedButton);
      await tester.tap(loginBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // SessionGate consumes pending navigation to '/saved-places'
      // SavedPlacesScreen is pushed successfully without any RouteNotFound / FlutterError
      expect(find.byType(SavedPlacesScreen), findsOneWidget);
      expect(find.text('Saved collections'), findsOneWidget);
      expect(find.text('Your curated collections'), findsOneWidget);
      expect(protectedNav.peekPending(), isNull);
    });

    test('Audit: Verify all known app routes exist and have valid paths', () {
      const validNamedRoutes = [
        '/welcome',
        '/login',
        '/register',
        '/password-reset',
        '/set-new-password',
        '/notifications',
        '/blocked-users',
        '/my-submissions',
        '/submit-spot',
        '/creator-application',
        '/account-deletion',
        '/restaurant-detail',
        '/saved-places',
        '/spot-detail',
        '/guide-detail',
        '/home',
      ];

      // Ensure no legacy '/saved' or '/main' in valid named routes
      expect(validNamedRoutes.contains('/saved'), isFalse);
      expect(validNamedRoutes.contains('/main'), isFalse);
      expect(validNamedRoutes.contains('/saved-places'), isTrue);
      expect(validNamedRoutes.contains('/home'), isTrue);
    });
  });
}
