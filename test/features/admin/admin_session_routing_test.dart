import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/admin_controller.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/guide_controller.dart';
import 'package:live_local/controllers/itinerary_controller.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/localization/app_localizations.dart';
import 'package:live_local/features/admin/data/demo_admin_repository.dart';
import 'package:live_local/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/auth/presentation/session_gate.dart';
import 'package:live_local/features/guides/data/demo_guide_repository.dart';
import 'package:live_local/features/influencer_applications/data/demo_influencer_application_repository.dart';
import 'package:live_local/features/influencer_applications/presentation/influencer_application_controller.dart';
import 'package:live_local/features/moderation/data/demo_moderation_repository.dart';
import 'package:live_local/features/moderation/presentation/moderation_controller.dart';
import 'package:live_local/features/notifications/data/demo_notification_repository.dart';
import 'package:live_local/features/notifications/presentation/notification_controller.dart';
import 'package:live_local/features/profile/data/demo_account_repository.dart';
import 'package:live_local/features/profile/presentation/account_controller.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/screens/main_navigation_screen.dart';
import 'package:live_local/services/seed_data_service.dart';
import 'package:provider/provider.dart';

void main() {
  group('Session / Role Routing Tests', () {
    late DemoAuthRepository authRepository;
    late DemoAccountRepository accountRepository;
    late DemoAdminRepository adminRepository;
    late DemoSpotRepository spotRepository;
    late DemoLocalEatsRepository localEatsRepository;
    late DemoGuideRepository guideRepository;
    late DemoInfluencerApplicationRepository influencerRepository;
    late DemoNotificationRepository notificationRepository;
    late DemoModerationRepository moderationRepository;

    late AuthController authController;
    late AccountController accountController;
    late AdminController adminController;
    late SpotController spotController;
    late LocalEatsController localEatsController;
    late GuideController guideController;
    late InfluencerApplicationController influencerController;
    late NotificationController notificationController;
    late ItineraryController itineraryController;
    late ModerationController moderationController;

    setUp(() {
      authRepository = DemoAuthRepository();
      accountRepository = DemoAccountRepository(authRepository);
      adminRepository = DemoAdminRepository(authRepository, accountRepository);
      spotRepository = DemoSpotRepository(authRepository);
      localEatsRepository = DemoLocalEatsRepository(authRepository);
      guideRepository = DemoGuideRepository(authRepository);
      influencerRepository =
          DemoInfluencerApplicationRepository(authRepository);
      notificationRepository = DemoNotificationRepository(authRepository);
      moderationRepository = DemoModerationRepository(authRepository);

      authController = AuthController(repository: authRepository);
      accountController = AccountController(
        repository: accountRepository,
        authController: authController,
      );
      adminController = AdminController(repository: adminRepository);
      spotController = SpotController(repository: spotRepository);
      localEatsController =
          LocalEatsController(repository: localEatsRepository);
      guideController = GuideController(repository: guideRepository);
      influencerController = InfluencerApplicationController(
        repository: influencerRepository,
      );
      notificationController = NotificationController(
        repository: notificationRepository,
      );
      itineraryController = ItineraryController(
        repository: DemoSavedItineraryRepository(authRepository),
      );
      moderationController = ModerationController(
        repository: moderationRepository,
      );
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppLocaleController()),
          ChangeNotifierProvider.value(value: authController),
          ChangeNotifierProvider.value(value: accountController),
          ChangeNotifierProvider.value(value: adminController),
          ChangeNotifierProvider.value(value: spotController),
          ChangeNotifierProvider.value(value: localEatsController),
          ChangeNotifierProvider.value(value: guideController),
          ChangeNotifierProvider.value(value: influencerController),
          ChangeNotifierProvider.value(value: notificationController),
          ChangeNotifierProvider.value(value: itineraryController),
          ChangeNotifierProvider.value(value: moderationController),
        ],
        child: const MaterialApp(
          home: SessionGate(),
        ),
      );
    }

    testWidgets('1. admin authenticated session routes to AdminDashboardScreen',
        (tester) async {
      await authController.initialize();
      await authController.login(
        'admin@livelocal.com',
        SeedDataService.demoPassword,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(find.byType(MainNavigationScreen), findsNothing);
      expect(find.text('Admin Center'), findsWidgets);
    });

    testWidgets(
        '2. tourist authenticated session routes to MainNavigationScreen',
        (tester) async {
      await authController.initialize();
      await authController.login(
        'tourist@livelocal.com',
        SeedDataService.demoPassword,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.byType(AdminDashboardScreen), findsNothing);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Admin'), findsNothing);
    });

    testWidgets('3. influencer routes to MainNavigationScreen', (tester) async {
      await authController.initialize();
      await authController.login(
        'influencer@livelocal.com',
        SeedDataService.demoPassword,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.byType(AdminDashboardScreen), findsNothing);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Admin'), findsNothing);
    });

    testWidgets('4. MainNavigationScreen no longer exposes Admin tab logic',
        (tester) async {
      await authController.initialize();
      await authController.login(
        'tourist@livelocal.com',
        SeedDataService.demoPassword,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ensure bottom navigation has exactly Home, Explore, Saved, Trips, Profile
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Trips'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Admin'), findsNothing);
    });

    testWidgets(
        '5. admin workspace does not expose tourist bottom destinations',
        (tester) async {
      await authController.initialize();
      await authController.login(
        'admin@livelocal.com',
        SeedDataService.demoPassword,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ensure NavigationRail is rendered and tourist destinations like 'Saved' are not exposed
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Saved'), findsNothing);
      expect(find.text('Eats'), findsNothing);
    });
  });
}
