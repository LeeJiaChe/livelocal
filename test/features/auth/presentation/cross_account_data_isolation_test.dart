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
import 'package:live_local/features/admin/data/demo_admin_repository.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/auth/presentation/auth_navigation_coordinator.dart';
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
  group('Cross-Account Data Isolation Tests', () {
    late DemoAuthRepository authRepo;
    late DemoSavedItineraryRepository itineraryRepo;
    late AuthController authController;
    late ItineraryController itineraryController;
    late NotificationController notificationController;
    late SpotController spotController;
    late LocalEatsController localEatsController;
    late GuideController guideController;
    late InfluencerApplicationController influencerController;
    late ModerationController moderationController;
    late AccountController accountController;
    late AdminController adminController;

    setUp(() async {
      authRepo = DemoAuthRepository();
      authController = AuthController(repository: authRepo);
      await authController.initialize();

      itineraryRepo = DemoSavedItineraryRepository(authRepo);
      itineraryController = ItineraryController(
        repository: itineraryRepo,
      );
      notificationController = NotificationController(
        repository: DemoNotificationRepository(authRepo),
      );
      spotController = SpotController(
        repository: DemoSpotRepository(authRepo),
      );
      localEatsController = LocalEatsController(
        repository: DemoLocalEatsRepository(authRepo),
      );
      guideController = GuideController(
        repository: DemoGuideRepository(authRepo),
      );
      influencerController = InfluencerApplicationController(
        repository: DemoInfluencerApplicationRepository(authRepo),
      );
      moderationController = ModerationController(
        repository: DemoModerationRepository(authRepo),
      );
      final accountRepo = DemoAccountRepository(authRepo);
      accountController = AccountController(
        repository: accountRepo,
        authController: authController,
      );
      adminController = AdminController(
        repository: DemoAdminRepository(authRepo, accountRepo),
      );
    });

    testWidgets(
      'Switching accounts triggers resetPrivateControllers and isolates private state',
      (tester) async {
        final navKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthController>.value(
                  value: authController),
              ChangeNotifierProvider<ItineraryController>.value(
                value: itineraryController,
              ),
              ChangeNotifierProvider<NotificationController>.value(
                value: notificationController,
              ),
              ChangeNotifierProvider<SpotController>.value(
                value: spotController,
              ),
              ChangeNotifierProvider<LocalEatsController>.value(
                value: localEatsController,
              ),
              ChangeNotifierProvider<GuideController>.value(
                value: guideController,
              ),
              ChangeNotifierProvider<InfluencerApplicationController>.value(
                value: influencerController,
              ),
              ChangeNotifierProvider<ModerationController>.value(
                value: moderationController,
              ),
              ChangeNotifierProvider<AccountController>.value(
                value: accountController,
              ),
              ChangeNotifierProvider<AdminController>.value(
                value: adminController,
              ),
            ],
            child: AuthNavigationCoordinator(
              navigatorKey: navKey,
              child: MaterialApp(
                navigatorKey: navKey,
                home: const Scaffold(body: Text('Test Root')),
              ),
            ),
          ),
        );
        await tester.pump();

        // 1. Sign in as tourist 1 and populate private state
        await authController.login(
          'tourist@livelocal.com',
          SeedDataService.demoPassword,
        );
        await tester.pumpAndSettle();

        // Populate tourist private data
        await itineraryRepo.setSaved(
          targetType: 'spot',
          targetId: 'spot-123',
          saved: true,
        );
        await itineraryController.loadSavedPlaces();
        expect(itineraryController.savedPlaces, isNotEmpty);

        // 2. Sign out / switch user
        await authController.logout();
        await tester.pumpAndSettle();

        // Verify private data is cleared
        expect(itineraryController.savedPlaces, isEmpty);
        expect(itineraryController.savedItineraries, isEmpty);
        expect(itineraryController.collections, isEmpty);
        expect(notificationController.notifications, isEmpty);
        expect(notificationController.unreadCount, 0);
        expect(spotController.pendingSpots, isEmpty);
        expect(spotController.ownedSubmissions, isEmpty);
        expect(localEatsController.pendingRestaurants, isEmpty);
        expect(localEatsController.ownedRestaurantSubmissions, isEmpty);
        expect(guideController.adminDrafts, isEmpty);
        expect(guideController.mySubmissions, isEmpty);
        expect(influencerController.mine, isNull);
        expect(accountController.submittedAppeal, isNull);
        expect(adminController.accounts, isEmpty);
      },
    );
  });
}
