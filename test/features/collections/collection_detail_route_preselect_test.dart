import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/app/theme/app_theme.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/itinerary_controller.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/routing/protected_navigation.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/screens/collection_detail_screen.dart';
import 'package:live_local/services/seed_data_service.dart';
import 'package:provider/provider.dart';

void main() {
  group('Collection Detail Widget Navigation & Pagination Independence', () {
    late DemoAuthRepository authRepo;
    late DemoSavedItineraryRepository savedRepo;
    late AuthController authCtrl;
    late ItineraryController itineraryCtrl;
    late SpotController spotCtrl;
    late LocalEatsController eatsCtrl;
    late ProtectedNavigation protectedNav;

    setUp(() async {
      authRepo = DemoAuthRepository();
      await authRepo.signIn(
        email: 'tourist@livelocal.com',
        password: SeedDataService.demoPassword,
      );
      savedRepo = DemoSavedItineraryRepository(authRepo);
      authCtrl = AuthController(repository: authRepo)..initialize();
      itineraryCtrl = ItineraryController(repository: savedRepo);
      spotCtrl = SpotController(repository: DemoSpotRepository(authRepo));
      eatsCtrl = LocalEatsController(
        repository: DemoLocalEatsRepository(authRepo),
      );
      protectedNav = ProtectedNavigation();
    });

    Widget createTestApp(Widget home) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: authCtrl),
          ChangeNotifierProvider<ItineraryController>.value(
            value: itineraryCtrl,
          ),
          ChangeNotifierProvider<SpotController>.value(value: spotCtrl),
          ChangeNotifierProvider<LocalEatsController>.value(value: eatsCtrl),
          Provider<ProtectedNavigation>.value(value: protectedNav),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: home,
        ),
      );
    }

    testWidgets(
        'Collection Detail Plan route navigates to ItineraryScreen with source collection preselected',
        (tester) async {
      final col = await itineraryCtrl.createCollection(
        name: 'KL Food Hunt',
        description: 'Best spots in KL',
      );
      expect(col, isNotNull);

      await tester.pumpWidget(createTestApp(
        CollectionDetailScreen(collection: col!),
      ));
      await tester.pumpAndSettle();

      expect(find.text('KL Food Hunt'), findsWidgets);

      // Add a place to collection
      final spot = SeedDataService.getInitialSpots().first;
      await itineraryCtrl.setPlaceCollections(
        targetType: 'spot',
        targetId: spot.id,
        collectionIds: [col.id],
      );
      await tester.pumpAndSettle();

      final planRouteBtn = find.text('Plan route');
      expect(planRouteBtn, findsOneWidget);
      await tester.tap(planRouteBtn);
      await tester.pumpAndSettle();

      // Now on ItineraryScreen
      expect(find.text('Plan a route from your saved places'), findsOneWidget);

      // Tap Create itinerary
      final createBtn = find.text('Create itinerary');
      expect(createBtn, findsOneWidget);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      // In the modal sheet, source collection is preselected to 'KL Food Hunt'
      expect(find.text('Source collection'), findsOneWidget);
      expect(find.textContaining('KL Food Hunt'), findsWidgets);
    });

    testWidgets(
        'Collection Detail renders place metadata even if spot is not in current discovery page',
        (tester) async {
      final col = await itineraryCtrl.createCollection(
        name: 'Penang Escapes',
      );
      expect(col, isNotNull);

      final spot = SeedDataService.getInitialSpots().last;
      await itineraryCtrl.setPlaceCollections(
        targetType: 'spot',
        targetId: spot.id,
        collectionIds: [col!.id],
      );

      // Verify fetchCollectionPlaces returns it directly
      final places = await savedRepo.fetchCollectionPlaces(col.id);
      expect(places, hasLength(1));
      expect(places.first.name, equals(spot.name));
      expect(places.first.targetId, equals(spot.id));

      await tester.pumpWidget(createTestApp(
        CollectionDetailScreen(collection: col),
      ));
      await tester.pumpAndSettle();

      // Renders place card directly
      expect(find.text(spot.name), findsOneWidget);
      expect(find.textContaining('1 place saved'), findsOneWidget);
    });
  });
}
