import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/itinerary_controller.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/itinerary/domain/saved_itinerary_repository.dart';
import 'package:live_local/services/seed_data_service.dart';

void main() {
  group('Saved Collections Comprehensive Flows', () {
    late DemoAuthRepository authRepository;
    late DemoSavedItineraryRepository savedRepository;
    late ItineraryController itineraryController;

    setUp(() async {
      authRepository = DemoAuthRepository();
      await authRepository.signIn(
        email: 'tourist@livelocal.com',
        password: SeedDataService.demoPassword,
      );
      savedRepository = DemoSavedItineraryRepository(authRepository);
      itineraryController = ItineraryController(repository: savedRepository);
      await itineraryController.loadSavedPlaces();
    });

    test(
        'Full lifecycle: create, rename, add items to multiple collections, and delete collection',
        () async {
      // 1. Initial state has default "Saved places" collection
      expect(itineraryController.collections, hasLength(1));
      expect(itineraryController.collections.first.name, 'Saved places');

      // 2. Create two custom collections
      final col1 = await itineraryController.createCollection(
        name: 'KL Food Crawl',
        description: 'Best street food and cafes in KL',
      );
      final col2 = await itineraryController.createCollection(
        name: 'Penang Weekend',
        description: 'Heritage and scenic spots',
      );

      expect(col1, isNotNull);
      expect(col2, isNotNull);
      expect(itineraryController.collections, hasLength(3));

      // 3. Rename col1
      final renamed = await itineraryController.renameCollection(
        collectionId: col1!.id,
        name: 'Kuala Lumpur Food Hunt',
        description: 'Updated description',
      );
      expect(renamed?.name, 'Kuala Lumpur Food Hunt');

      // 4. Add a spot to multiple collections (Kuala Lumpur Food Hunt + Penang Weekend)
      final spot = SeedDataService.getInitialSpots().first;
      final restaurant = SeedDataService.getInitialRestaurants().first;

      await itineraryController.setPlaceCollections(
        targetType: 'spot',
        targetId: spot.id,
        collectionIds: [col1.id, col2!.id],
      );

      await itineraryController.setPlaceCollections(
        targetType: 'restaurant',
        targetId: restaurant.id,
        collectionIds: [col1.id],
      );

      // Verify memberships
      final spotMemberships = await itineraryController.fetchPlaceCollectionIds(
        targetType: 'spot',
        targetId: spot.id,
      );
      expect(spotMemberships, containsAll([col1.id, col2.id]));

      final restaurantMemberships =
          await itineraryController.fetchPlaceCollectionIds(
        targetType: 'restaurant',
        targetId: restaurant.id,
      );
      expect(restaurantMemberships, equals([col1.id]));

      // Verify place is marked as saved
      expect(itineraryController.isSaved(spotId: spot.id), isTrue);
      expect(itineraryController.isSaved(restaurantId: restaurant.id), isTrue);

      // 5. Delete col1
      final deleted = await itineraryController.deleteCollection(col1.id);
      expect(deleted, isTrue);

      // Spot should still be saved (still belongs to col2)
      expect(itineraryController.isSaved(spotId: spot.id), isTrue);

      // Restaurant had only col1 membership, so deleting col1 should orphan and unsave restaurant
      expect(itineraryController.isSaved(restaurantId: restaurant.id), isFalse);
    });

    test('Plan itinerary from a specific collection', () async {
      final col = await itineraryController.createCollection(
        name: 'George Town Walking Tour',
      );
      expect(col, isNotNull);

      final spots = SeedDataService.getInitialSpots();
      final penangSpot = spots.firstWhere((s) => s.city == 'George Town');

      await itineraryController.setPlaceCollections(
        targetType: 'spot',
        targetId: penangSpot.id,
        collectionIds: [col!.id],
      );

      const origin = RouteOrigin(
        label: 'George Town, Penang',
        latitude: 5.4141,
        longitude: 100.3288,
        mode: 'manual',
        state: 'Penang',
        city: 'George Town',
      );

      final success = await itineraryController.generateAndSaveItinerary(
        title: 'Walk in George Town',
        origin: origin,
        allSpots: spots,
        allRestaurants: SeedDataService.getInitialRestaurants(),
        collectionId: col.id,
      );

      expect(success, isTrue);
      expect(itineraryController.itinerarySteps, hasLength(1));
      expect(
          itineraryController.itinerarySteps.first['title'], penangSpot.name);
    });
  });
}
