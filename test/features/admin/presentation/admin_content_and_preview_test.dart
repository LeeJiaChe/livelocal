import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/admin_controller.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/guide_controller.dart';
import 'package:live_local/controllers/itinerary_controller.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/moderation_controller.dart';
import 'package:live_local/controllers/notification_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/config/app_environment.dart';
import 'package:live_local/core/localization/app_localizations.dart';
import 'package:live_local/core/routing/protected_navigation.dart';
import 'package:live_local/features/admin/data/demo_admin_repository.dart';
import 'package:live_local/features/admin/presentation/screens/admin_content_page.dart';
import 'package:live_local/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:live_local/features/admin/presentation/screens/admin_guides_page.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/guides/data/demo_guide_repository.dart';
import 'package:live_local/features/influencer_applications/data/demo_influencer_application_repository.dart';
import 'package:live_local/features/influencer_applications/presentation/influencer_application_controller.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/moderation/data/demo_moderation_repository.dart';
import 'package:live_local/features/notifications/data/demo_notification_repository.dart';
import 'package:live_local/features/profile/data/demo_account_repository.dart';
import 'package:live_local/features/profile/presentation/account_controller.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/services/seed_data_service.dart';
import 'package:provider/provider.dart';

void main() {
  group('Admin Content and Safe Public Preview Tests', () {
    late DemoAuthRepository authRepo;
    late AuthController authController;
    late SpotController spotController;
    late LocalEatsController localEatsController;
    late GuideController guideController;
    late ItineraryController itineraryController;
    late NotificationController notificationController;
    late AdminController adminController;
    late InfluencerApplicationController influencerController;
    late ModerationController moderationController;
    late AccountController accountController;

    setUp(() async {
      authRepo = DemoAuthRepository();
      authController = AuthController(repository: authRepo);
      await authController.initialize();
      await authController.login(
          'admin@livelocal.com', SeedDataService.demoPassword);

      spotController = SpotController(repository: DemoSpotRepository(authRepo));
      localEatsController =
          LocalEatsController(repository: DemoLocalEatsRepository(authRepo));
      guideController =
          GuideController(repository: DemoGuideRepository(authRepo));
      itineraryController = ItineraryController(
          repository: DemoSavedItineraryRepository(authRepo));
      notificationController = NotificationController(
          repository: DemoNotificationRepository(authRepo));
      final accountRepo = DemoAccountRepository(authRepo);
      accountController = AccountController(
        repository: accountRepo,
        authController: authController,
      );
      adminController = AdminController(
        repository: DemoAdminRepository(authRepo, accountRepo),
      );
      influencerController = InfluencerApplicationController(
        repository: DemoInfluencerApplicationRepository(authRepo),
      );
      moderationController =
          ModerationController(repository: DemoModerationRepository(authRepo));

      await spotController.loadSpots();
      await localEatsController.loadData();
      await guideController.loadGuides();
      await adminController.loadDashboard();
    });

    Widget createAdminWidget() {
      return MultiProvider(
        providers: [
          Provider<AppConfiguration>.value(
            value: AppConfiguration.demoForTesting(),
          ),
          ChangeNotifierProvider(create: (_) => AppLocaleController()),
          ChangeNotifierProvider<AuthController>.value(value: authController),
          ChangeNotifierProvider<SpotController>.value(value: spotController),
          ChangeNotifierProvider<LocalEatsController>.value(
            value: localEatsController,
          ),
          ChangeNotifierProvider<GuideController>.value(value: guideController),
          ChangeNotifierProvider<ItineraryController>.value(
            value: itineraryController,
          ),
          ChangeNotifierProvider<NotificationController>.value(
            value: notificationController,
          ),
          ChangeNotifierProvider<AdminController>.value(value: adminController),
          ChangeNotifierProvider<InfluencerApplicationController>.value(
            value: influencerController,
          ),
          ChangeNotifierProvider<ModerationController>.value(
            value: moderationController,
          ),
          ChangeNotifierProvider<AccountController>.value(
            value: accountController,
          ),
          Provider<ProtectedNavigation>.value(value: ProtectedNavigation()),
        ],
        child: const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      );
    }

    testWidgets(
        'Admin dashboard exposes Content tab with Spots, Restaurants, and Guides',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createAdminWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Content destination in bottom navigation bar
      expect(find.widgetWithText(NavigationDestination, 'Content'),
          findsOneWidget);
      expect(
          find.widgetWithText(NavigationDestination, 'Guides'), findsNothing);

      // Tap Content tab
      await tester.tap(find.widgetWithText(NavigationDestination, 'Content'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AdminContentPage), findsOneWidget);

      // Verify Spots segment is active and lists spots
      expect(find.text('Spots'), findsWidgets);
      expect(find.text('Restaurants'), findsWidgets);
      expect(find.text('Guides'), findsWidgets);
      expect(find.textContaining('published spots'), findsWidgets);

      // Switch to Restaurants segment
      await tester.tap(find.text('Restaurants').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('published restaurants'), findsWidgets);

      // Switch to Guides segment
      await tester.tap(find.text('Guides').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(AdminGuidesPage), findsOneWidget);
    });

    testWidgets('Public preview in Admin More is isolated and read-only',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createAdminWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Navigate to More tab
      await tester.tap(find.widgetWithText(NavigationDestination, 'More'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Preview public experience'), findsOneWidget);

      // Tap Preview public experience
      await tester.tap(find.text('Preview public experience'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Read-Only banner
      expect(find.text('Public Preview (Read-Only)'), findsOneWidget);
      expect(find.text('Previewing public discovery experience as Guest'),
          findsOneWidget);

      // Verify no Admin Profile tab is shown
      expect(
          find.widgetWithText(NavigationDestination, 'Profile'), findsNothing);
      expect(find.widgetWithText(NavigationDestination, 'Trips'), findsNothing);
    });
  });
}
