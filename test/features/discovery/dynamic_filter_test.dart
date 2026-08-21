import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';

void main() {
  group('Dynamic Filters Tests', () {
    late DemoAuthRepository authRepository;
    late DemoSpotRepository spotRepository;
    late DemoLocalEatsRepository restaurantRepository;
    late SpotController spotController;
    late LocalEatsController localEatsController;

    setUp(() async {
      authRepository = DemoAuthRepository();
      spotRepository = DemoSpotRepository(authRepository);
      restaurantRepository = DemoLocalEatsRepository(authRepository);
      spotController = SpotController(repository: spotRepository);
      localEatsController =
          LocalEatsController(repository: restaurantRepository);

      await Future.wait([
        spotController.loadSpots(),
        localEatsController.loadData(),
      ]);
    });

    test(
        'SpotController loads dynamic categories and states from published data',
        () async {
      final filterOptions = spotController.filterOptions;
      expect(filterOptions.categories, isNotEmpty);
      expect(filterOptions.states, isNotEmpty);

      // Verify Penang alias mapping
      final penangOption = filterOptions.states.firstWhere(
        (s) => s.rawValue == 'Pulau Pinang' || s.displayName == 'Penang',
      );
      expect(penangOption.displayName, 'Penang');

      // Filter by state
      spotController.filterByState(penangOption.rawValue);
      expect(spotController.selectedStateDisplayName, 'Penang');
      expect(spotController.hasActiveFilters, isTrue);

      await spotController.loadSpots();
      final filteredSpots = spotController.spots;
      expect(filteredSpots, isNotEmpty);
      for (final spot in filteredSpots) {
        expect(['Penang', 'Pulau Pinang'], contains(spot.state));
      }
    });

    test(
        'LocalEatsController dynamically computes available states, cuisines, and budgets',
        () {
      final states = localEatsController.availableStates;
      final cuisines = localEatsController.availableCuisines;
      final priceRanges = localEatsController.availablePriceRanges;

      expect(states, contains('All'));
      expect(cuisines, contains('All'));
      expect(priceRanges, contains('All'));

      // Filter by cuisine
      final targetCuisine = cuisines.firstWhere((c) => c != 'All');
      localEatsController.filterByCuisine(targetCuisine);
      expect(localEatsController.selectedCuisine, targetCuisine);
      expect(localEatsController.hasActiveFilters, isTrue);

      final filtered = localEatsController.filteredRestaurants;
      expect(filtered, isNotEmpty);
      for (final restaurant in filtered) {
        expect(restaurant.cuisineType, targetCuisine);
      }

      // Reset filters
      localEatsController.resetFilters();
      expect(localEatsController.hasActiveFilters, isFalse);
      expect(localEatsController.selectedCuisine, 'All');
    });
  });
}
