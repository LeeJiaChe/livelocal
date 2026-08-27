import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/itinerary_controller.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/routing/protected_navigation.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/screens/saved_places_screen.dart';
import 'package:live_local/services/seed_data_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
      'SavedPlacesScreen displays collections grid and allows creating collections',
      (tester) async {
    final authRepository = DemoAuthRepository();
    await authRepository.signIn(
      email: 'tourist@livelocal.com',
      password: SeedDataService.demoPassword,
    );
    final authController = AuthController(repository: authRepository);
    await authController.initialize();

    final spotRepository = DemoSpotRepository(authRepository);
    final restaurantRepository = DemoLocalEatsRepository(authRepository);
    final savedRepository = DemoSavedItineraryRepository(authRepository);

    final spots = SeedDataService.getInitialSpots();
    final restaurants = SeedDataService.getInitialRestaurants();

    final penangSpot = spots.firstWhere((s) => s.state == 'Pulau Pinang');
    final penangRestaurant =
        restaurants.firstWhere((r) => r.city == 'George Town');

    await savedRepository.setSaved(
      targetType: 'spot',
      targetId: penangSpot.id,
      saved: true,
    );
    await savedRepository.setSaved(
      targetType: 'restaurant',
      targetId: penangRestaurant.id,
      saved: true,
    );

    final spotController = SpotController(repository: spotRepository);
    final restaurantController =
        LocalEatsController(repository: restaurantRepository);
    final itineraryController =
        ItineraryController(repository: savedRepository);
    await Future.wait([
      spotController.loadSpots(),
      restaurantController.loadData(),
      itineraryController.loadSavedPlaces(),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          ChangeNotifierProvider.value(value: spotController),
          ChangeNotifierProvider.value(value: restaurantController),
          ChangeNotifierProvider.value(value: itineraryController),
          Provider(create: (_) => ProtectedNavigation()),
        ],
        child: const MaterialApp(home: SavedPlacesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and collections exist
    expect(find.text('Saved collections'), findsOneWidget);
    expect(find.text('Your curated collections'), findsOneWidget);
    expect(find.text('New collection'), findsOneWidget);
    expect(find.text('Saved places'), findsOneWidget);

    // Tap "+ New collection"
    await tester.tap(find.text('New collection'));
    await tester.pumpAndSettle();

    // Dialog opens
    expect(find.text('Collection name'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Penang Food Trip');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // New collection appears in the list
    expect(find.text('Penang Food Trip'), findsOneWidget);
  });
}
