import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/itinerary_controller.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/routing/protected_navigation.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/itinerary/domain/saved_itinerary_repository.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/screens/itinerary_screen.dart';
import 'package:live_local/services/seed_data_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
      'itinerary screen shows day grouping and opens map view with numbered markers',
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

    // Save 6 items to verify Day 1 + Day 2 multi-day grouping
    for (int i = 0; i < 4 && i < spots.length; i++) {
      await savedRepository.setSaved(
        targetType: 'spot',
        targetId: spots[i].id,
        saved: true,
      );
    }
    for (int i = 0; i < 2 && i < restaurants.length; i++) {
      await savedRepository.setSaved(
        targetType: 'restaurant',
        targetId: restaurants[i].id,
        saved: true,
      );
    }

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
        child: const MaterialApp(home: ItineraryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Initially without generated steps: map icon is not present
    expect(find.byIcon(Icons.map_outlined), findsNothing);

    // Generate itinerary with 6 stops
    const origin = RouteOrigin(
      label: 'Kuala Lumpur',
      latitude: 3.1390,
      longitude: 101.6869,
      mode: 'manual',
    );
    final generated = await itineraryController.generateAndSaveItinerary(
      title: '6 Stop Multi-Day Plan',
      origin: origin,
      allSpots: spots,
      allRestaurants: restaurants,
    );
    expect(generated, isTrue);
    expect(itineraryController.itinerarySteps, hasLength(6));

    await tester.pumpAndSettle();

    // "Suggested day itinerary" and "Day 1" are visible
    expect(find.text('Suggested day itinerary'), findsOneWidget);
    expect(find.text('Day 1'), findsOneWidget);

    // Scroll to see Day 2
    await tester.scrollUntilVisible(
      find.text('Day 2'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Day 2'), findsOneWidget);

    // Map icon is present in AppBar
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);

    // Tap Map icon to open "Itinerary on Map" sheet
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Itinerary on Map'), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Day breakdown'), findsOneWidget);
    expect(find.byType(MarkerLayer), findsOneWidget);
  });
}
