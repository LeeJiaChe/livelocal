import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/guide_controller.dart';
import 'package:live_local/controllers/itinerary_controller.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/notification_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/config/app_environment.dart';
import 'package:live_local/core/localization/app_localizations.dart';
import 'package:live_local/core/routing/protected_navigation.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/guides/data/demo_guide_repository.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/navigation/presentation/explore_hub_screen.dart';
import 'package:live_local/features/notifications/data/demo_notification_repository.dart';
import 'package:live_local/features/places/data/supabase_google_places_provider.dart';
import 'package:live_local/features/places/domain/place_provider.dart';
import 'package:live_local/features/places/presentation/external_places_screen.dart';
import 'package:live_local/features/places/presentation/place_discovery_controller.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/screens/localeats_screen.dart';
import 'package:live_local/screens/main_navigation_screen.dart';
import 'package:live_local/screens/neighbourhood_explorer_screen.dart';
import 'package:live_local/screens/spots_discovery_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('Home CTA Destination Integrity Tests', () {
    late DemoAuthRepository authRepo;
    late AuthController authController;
    late SpotController spotController;
    late LocalEatsController localEatsController;
    late GuideController guideController;
    late ItineraryController itineraryController;
    late NotificationController notificationController;

    setUp(() async {
      authRepo = DemoAuthRepository();
      authController = AuthController(repository: authRepo);
      await authController.initialize();

      spotController = SpotController(repository: DemoSpotRepository(authRepo));
      localEatsController =
          LocalEatsController(repository: DemoLocalEatsRepository(authRepo));
      guideController =
          GuideController(repository: DemoGuideRepository(authRepo));
      itineraryController = ItineraryController(
          repository: DemoSavedItineraryRepository(authRepo));
      notificationController = NotificationController(
          repository: DemoNotificationRepository(authRepo));

      await spotController.loadSpots();
      await localEatsController.loadData();
      await guideController.loadGuides();
    });

    Widget createWidgetUnderTest() {
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
          Provider<ProtectedNavigation>.value(value: ProtectedNavigation()),
          Provider<PlaceProvider>.value(
              value: const UnavailablePlaceProvider()),
          ChangeNotifierProvider(
            create: (_) => PlaceDiscoveryController(
              provider: const UnavailablePlaceProvider(),
            ),
          ),
        ],
        child: const MaterialApp(
          home: MainNavigationScreen(),
        ),
      );
    }

    testWidgets('Local Eats tile opens Explore Hub on Eat tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.scrollUntilVisible(
        find.text('Local Eats'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Local Eats'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ExploreHubScreen), findsOneWidget);
      expect(find.byType(LocalEatsScreen), findsOneWidget);
    });

    testWidgets('Local Spots tile opens Explore Hub on Things to Do tab',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.scrollUntilVisible(
        find.text('Local Spots'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Local Spots'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ExploreHubScreen), findsOneWidget);
      expect(find.byType(SpotsDiscoveryScreen), findsOneWidget);
    });

    testWidgets('Community Guides tile opens Explore Hub on Guides tab',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.scrollUntilVisible(
        find.text('Community Guides'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Community Guides'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ExploreHubScreen), findsOneWidget);
      expect(find.byType(NeighbourhoodExplorerScreen), findsOneWidget);
    });

    testWidgets('Places to know View all opens Explore Hub on Things to Do tab',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.scrollUntilVisible(
        find.text('View all'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('View all'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ExploreHubScreen), findsOneWidget);
      expect(find.byType(SpotsDiscoveryScreen), findsOneWidget);
    });

    testWidgets(
        'Explore Malaysia hero button opens Explore Hub on Discover tab',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Explore Malaysia hero button
      await tester.tap(find.text('Explore Malaysia'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ExploreHubScreen), findsOneWidget);
      expect(find.byType(ExternalPlacesScreen), findsOneWidget);
    });
  });
}
