import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/itinerary_controller.dart';
import 'package:live_local/core/errors/app_exception.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/itinerary/domain/saved_itinerary_repository.dart';
import 'package:live_local/services/seed_data_service.dart';

void main() {
  group('saved collections and itineraries', () {
    test(
        'save is user-scoped, multi-collection capable, and persisted into an itinerary',
        () async {
      final auth = DemoAuthRepository();
      await auth.signIn(
        email: 'tourist@livelocal.com',
        password: SeedDataService.demoPassword,
      );
      final repository = DemoSavedItineraryRepository(auth);
      final controller = ItineraryController(repository: repository);
      final spot = SeedDataService.getInitialSpots().first;

      expect(await controller.toggleSave(spotId: spot.id), isTrue);
      await controller.loadSavedPlaces();
      expect(controller.savedPlaces, hasLength(1));
      expect(controller.isSaved(spotId: spot.id), isTrue);
      expect(controller.collections, isNotEmpty);

      // Create a custom collection and add place
      final customCol = await controller.createCollection(
        name: 'Penang Highlights',
        description: 'Best spots in Penang',
      );
      expect(customCol, isNotNull);
      expect(customCol!.name, 'Penang Highlights');

      final defaultColId =
          controller.collections.firstWhere((c) => c.name == 'Saved places').id;

      // Add spot to both collections
      final updatedMemberships = await controller.setPlaceCollections(
        targetType: 'spot',
        targetId: spot.id,
        collectionIds: [defaultColId, customCol.id],
      );
      expect(updatedMemberships.saved, isTrue);
      expect(updatedMemberships.collectionIds,
          containsAll([defaultColId, customCol.id]));

      final memberships = await controller.fetchPlaceCollectionIds(
        targetType: 'spot',
        targetId: spot.id,
      );
      expect(memberships, containsAll([defaultColId, customCol.id]));

      const origin = RouteOrigin(
        label: 'George Town, Penang',
        latitude: 5.4141,
        longitude: 100.3288,
        mode: 'manual',
        state: 'Penang',
        city: 'George Town',
      );
      final created = await controller.generateAndSaveItinerary(
        title: 'Penang morning',
        origin: origin,
        allSpots: SeedDataService.getInitialSpots(),
        allRestaurants: SeedDataService.getInitialRestaurants(),
        collectionId: customCol.id,
      );
      expect(created, isTrue);
      expect(controller.itinerarySteps, hasLength(1));
      expect(controller.itinerarySteps.first['area'], 'Air Itam');
      expect(controller.savedItineraries, hasLength(1));
      expect(repository.locationPreferenceForDemo?.mode, 'manual');

      // Sign in as a different user
      await auth.signOut();
      await auth.signIn(
        email: 'admin@livelocal.com',
        password: SeedDataService.demoPassword,
      );
      await controller.loadSavedPlaces();
      expect(controller.savedPlaces, isEmpty);
      expect(controller.isSaved(spotId: spot.id), isFalse);
    });

    test('removing place from all collections unsaves the place', () async {
      final auth = DemoAuthRepository();
      await auth.signIn(
        email: 'tourist@livelocal.com',
        password: SeedDataService.demoPassword,
      );
      final repository = DemoSavedItineraryRepository(auth);
      final controller = ItineraryController(repository: repository);
      final spot = SeedDataService.getInitialSpots().first;

      await controller.toggleSave(spotId: spot.id);
      expect(controller.isSaved(spotId: spot.id), isTrue);

      // Remove from all collections
      await controller.setPlaceCollections(
        targetType: 'spot',
        targetId: spot.id,
        collectionIds: const [],
      );

      expect(controller.isSaved(spotId: spot.id), isFalse);
      expect(controller.savedPlaces, isEmpty);
    });

    test('an itinerary cannot use a place the account has not saved', () async {
      final auth = DemoAuthRepository();
      await auth.signIn(
        email: 'tourist@livelocal.com',
        password: SeedDataService.demoPassword,
      );
      final repository = DemoSavedItineraryRepository(auth);
      expect(
        () => repository.createItinerary(
          title: 'Invalid route',
          origin: const RouteOrigin(
            label: 'Ipoh, Perak',
            latitude: 4.5975,
            longitude: 101.0901,
            mode: 'manual',
          ),
          orderedTargets: const [
            ItineraryTarget(type: 'spot', id: 'spot-001'),
          ],
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}
