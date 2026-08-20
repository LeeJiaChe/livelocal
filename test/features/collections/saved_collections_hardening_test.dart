import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/itinerary_controller.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/errors/app_exception.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/itinerary/domain/saved_itinerary_repository.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/models/saved_collection_model.dart';
import 'package:live_local/models/spot_model.dart';
import 'package:live_local/screens/collection_detail_screen.dart';
import 'package:live_local/services/seed_data_service.dart';
import 'package:live_local/shared/presentation/save_to_collection_sheet.dart';
import 'package:provider/provider.dart';

class _FailingMembershipRepo extends DemoSavedItineraryRepository {
  _FailingMembershipRepo(super.authRepository);

  bool shouldFailFetchMemberships = false;

  @override
  Future<List<String>> fetchPlaceCollectionIds({
    required String targetType,
    required String targetId,
  }) async {
    if (shouldFailFetchMemberships) {
      throw const AppException(
        code: AppErrorCode.network,
        userMessage: 'Failed to retrieve place collections.',
      );
    }
    return super.fetchPlaceCollectionIds(
      targetType: targetType,
      targetId: targetId,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Saved Collections Hardening Tests', () {
    late DemoAuthRepository authRepo;
    late DemoSavedItineraryRepository savedRepo;
    late DemoSpotRepository spotRepo;
    late DemoLocalEatsRepository eatsRepo;
    late ItineraryController itineraryCtrl;
    late SpotController spotCtrl;
    late LocalEatsController eatsCtrl;
    late AuthController authCtrl;

    setUp(() async {
      authRepo = DemoAuthRepository();
      await authRepo.signIn(
        email: 'tourist@livelocal.com',
        password: SeedDataService.demoPassword,
      );
      savedRepo = DemoSavedItineraryRepository(authRepo);
      spotRepo = DemoSpotRepository(authRepo);
      eatsRepo = DemoLocalEatsRepository(authRepo);

      itineraryCtrl = ItineraryController(repository: savedRepo);
      spotCtrl = SpotController(repository: spotRepo);
      eatsCtrl = LocalEatsController(repository: eatsRepo);
      authCtrl = AuthController(repository: authRepo);
      await authCtrl.initialize();
      await itineraryCtrl.loadSavedPlaces();
      await itineraryCtrl.loadCollections();
    });

    test(
        'P0-1: setPlaceCollections deselecting all returns saved: false result without error',
        () async {
      final spot = SeedDataService.getInitialSpots().first;
      final defaultCol = itineraryCtrl.collections.first;

      // Save spot
      final saveRes = await itineraryCtrl.setPlaceCollections(
        targetType: 'spot',
        targetId: spot.id,
        collectionIds: [defaultCol.id],
      );
      expect(saveRes.saved, isTrue);
      expect(itineraryCtrl.isSaved(spotId: spot.id), isTrue);

      // Deselect all
      final unsaveRes = await itineraryCtrl.setPlaceCollections(
        targetType: 'spot',
        targetId: spot.id,
        collectionIds: const [],
      );
      expect(unsaveRes.saved, isFalse);
      expect(unsaveRes.collectionIds, isEmpty);
      expect(itineraryCtrl.isSaved(spotId: spot.id), isFalse);
      expect(itineraryCtrl.savedPlaces, isEmpty);
    });

    testWidgets(
        'P0-1 & P0-2: SaveToCollectionSheet handles deselect all and fails closed on network error',
        (tester) async {
      final failingRepo = _FailingMembershipRepo(authRepo);
      final testItineraryCtrl = ItineraryController(repository: failingRepo);
      await testItineraryCtrl.loadCollections();
      final spot = SeedDataService.getInitialSpots().first;
      final defaultCol = testItineraryCtrl.collections.first;

      // First save it
      await testItineraryCtrl.setPlaceCollections(
        targetType: 'spot',
        targetId: spot.id,
        collectionIds: [defaultCol.id],
      );

      // 1. Test fail-closed on initial membership load
      failingRepo.shouldFailFetchMemberships = true;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authCtrl),
            ChangeNotifierProvider.value(value: testItineraryCtrl),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SaveToCollectionSheet(
                targetType: 'spot',
                targetId: spot.id,
                placeName: spot.name,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Inline error and retry button should appear
      expect(find.text('Could not load collection memberships. Please retry.'),
          findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Done button must be disabled
      final doneBtnFinder = find.widgetWithText(FilledButton, 'Done');
      expect(doneBtnFinder, findsOneWidget);
      final FilledButton doneButton = tester.widget(doneBtnFinder);
      expect(doneButton.onPressed, isNull);

      // 2. Test retry recovery
      failingRepo.shouldFailFetchMemberships = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Could not load collection memberships. Please retry.'),
          findsNothing);
      final FilledButton activeDoneButton = tester.widget(doneBtnFinder);
      expect(activeDoneButton.onPressed, isNotNull);

      // 3. Deselect collection and tap Done
      final checkboxFinder = find.byType(CheckboxListTile);
      expect(checkboxFinder, findsWidgets);
      await tester.tap(checkboxFinder.first);
      await tester.pumpAndSettle();

      await tester.tap(doneBtnFinder);
      await tester.pumpAndSettle();

      // Verify spot was unsaved
      expect(testItineraryCtrl.isSaved(spotId: spot.id), isFalse);
    });

    test(
        'P0-4: fetchSavedRouteCandidates resolves saved items without needing discovery cache',
        () async {
      final spots = SeedDataService.getInitialSpots();
      final restaurants = SeedDataService.getInitialRestaurants();
      final spot = spots.first;
      final restaurant = restaurants.first;

      final customCol = await itineraryCtrl.createCollection(
        name: 'Road Trip',
      );
      expect(customCol, isNotNull);

      await itineraryCtrl.setPlaceCollections(
        targetType: 'spot',
        targetId: spot.id,
        collectionIds: [customCol!.id],
      );
      await itineraryCtrl.setPlaceCollections(
        targetType: 'restaurant',
        targetId: restaurant.id,
        collectionIds: [customCol.id],
      );

      // Fetch candidates for this collection
      final candidates =
          await savedRepo.fetchSavedRouteCandidates(collectionId: customCol.id);
      expect(candidates, hasLength(2));
      expect(candidates.any((c) => c.targetId == spot.id && c.isSpot), isTrue);
      expect(candidates.any((c) => c.targetId == restaurant.id && !c.isSpot),
          isTrue);

      // Generate itinerary without passing any discovery spot/restaurant lists
      const origin = RouteOrigin(
        label: 'Start Point',
        latitude: 3.1390,
        longitude: 101.6869,
        mode: 'manual',
      );

      final success = await itineraryCtrl.generateAndSaveItinerary(
        title: 'Road Trip Route',
        origin: origin,
        collectionId: customCol.id,
      );

      expect(success, isTrue);
      expect(itineraryCtrl.itinerarySteps, hasLength(2));
      expect(itineraryCtrl.savedItineraries, hasLength(1));
    });

    testWidgets(
        'P0-3: CollectionDetailScreen fetches exact entity by ID without synthetic fallback',
        (tester) async {
      final spots = SeedDataService.getInitialSpots();
      final spot = spots.last; // May not be in first page if paginated
      final customCol =
          await itineraryCtrl.createCollection(name: 'Hidden Gems');
      expect(customCol, isNotNull);

      await itineraryCtrl.setPlaceCollections(
        targetType: 'spot',
        targetId: spot.id,
        collectionIds: [customCol!.id],
      );
      itineraryCtrl.setActiveCollection(customCol);
      await itineraryCtrl.loadActiveCollectionPlaces(customCol.id);

      SpotModel? navigatedSpot;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authCtrl),
            ChangeNotifierProvider.value(value: itineraryCtrl),
            ChangeNotifierProvider.value(value: spotCtrl),
            ChangeNotifierProvider.value(value: eatsCtrl),
          ],
          child: MaterialApp(
            routes: {
              '/spot-detail': (context) {
                final args =
                    ModalRoute.of(context)!.settings.arguments as dynamic;
                navigatedSpot = args.spot as SpotModel;
                return const Scaffold(body: Text('Spot Detail Destination'));
              },
            },
            home: CollectionDetailScreen(collection: customCol),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(spot.name), findsOneWidget);

      // Tap place item to open detail
      await tester.tap(find.text(spot.name));
      await tester.pumpAndSettle();

      expect(find.text('Spot Detail Destination'), findsOneWidget);
      expect(navigatedSpot, isNotNull);
      expect(navigatedSpot!.id, spot.id);
      expect(navigatedSpot!.name, spot.name);
      expect(navigatedSpot!.description, isNotEmpty);
      expect(navigatedSpot!.bestTime, spot.bestTime);
      expect(navigatedSpot!.thingsToDo, spot.thingsToDo);
    });

    test('P1-1: setActiveCollection is synchronous state assignment', () {
      final col = SavedCollectionModel(
        id: 'col-sync-test',
        userId: 'test-user',
        name: 'Sync Test',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      itineraryCtrl.setActiveCollection(col);
      expect(itineraryCtrl.activeCollection?.id, 'col-sync-test');

      itineraryCtrl.setActiveCollection(null);
      expect(itineraryCtrl.activeCollection, isNull);
      expect(itineraryCtrl.activeCollectionItems, isEmpty);
      expect(itineraryCtrl.activeCollectionPlaces, isEmpty);
    });
  });
}
