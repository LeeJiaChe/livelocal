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
  testWidgets('saved-place filters and city albums combine with area grouping',
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

    final penangSpot = spots.firstWhere((s) => s.city == 'George Town');
    final ipohSpot = spots.firstWhere((s) => s.city == 'Ipoh');
    final penangRestaurant =
        restaurants.firstWhere((r) => r.city == 'George Town');
    final ipohRestaurant = restaurants.firstWhere((r) => r.city == 'Ipoh');

    await savedRepository.setSaved(
      targetType: 'spot',
      targetId: penangSpot.id,
      saved: true,
    );
    await savedRepository.setSaved(
      targetType: 'spot',
      targetId: ipohSpot.id,
      saved: true,
    );
    await savedRepository.setSaved(
      targetType: 'restaurant',
      targetId: penangRestaurant.id,
      saved: true,
    );
    await savedRepository.setSaved(
      targetType: 'restaurant',
      targetId: ipohRestaurant.id,
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

    expect(find.text('4 saved places'), findsOneWidget);
    expect(find.text(penangSpot.name), findsOneWidget);
    expect(find.text(ipohSpot.name), findsOneWidget);
    expect(find.text(penangRestaurant.name), findsOneWidget);
    expect(find.text(ipohRestaurant.name), findsOneWidget);
    expect(find.textContaining('Suggested day ·'), findsWidgets);

    // City album buttons exist
    expect(find.text('George Town'), findsWidgets);
    expect(find.text('Ipoh'), findsWidgets);

    // Filter by George Town album
    await tester.tap(find.text('George Town').first);
    await tester.pumpAndSettle();
    expect(find.text(penangSpot.name), findsOneWidget);
    expect(find.text(penangRestaurant.name), findsOneWidget);
    expect(find.text(ipohSpot.name), findsNothing);
    expect(find.text(ipohRestaurant.name), findsNothing);

    // Combined filter: George Town + Restaurants only
    await tester.tap(find.text('Restaurants'));
    await tester.pumpAndSettle();
    expect(find.text(penangRestaurant.name), findsOneWidget);
    expect(find.text(penangSpot.name), findsNothing);
    expect(find.text(ipohRestaurant.name), findsNothing);

    // Reset album to All, keep Restaurants
    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();
    expect(find.text(penangRestaurant.name), findsOneWidget);
    expect(find.text(ipohRestaurant.name), findsOneWidget);
    expect(find.text(penangSpot.name), findsNothing);

    // Switch to Spots only
    await tester.tap(find.text('Spots'));
    await tester.pumpAndSettle();
    expect(find.text(penangSpot.name), findsOneWidget);
    expect(find.text(ipohSpot.name), findsOneWidget);
    expect(find.text(penangRestaurant.name), findsNothing);
  });
}
