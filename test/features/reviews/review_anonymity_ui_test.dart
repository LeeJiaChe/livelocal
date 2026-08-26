import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/itinerary_controller.dart';
import 'package:live_local/controllers/review_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/localization/app_localizations.dart';
import 'package:live_local/core/routing/protected_navigation.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/moderation/data/demo_moderation_repository.dart';
import 'package:live_local/features/moderation/presentation/moderation_controller.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/restaurants/presentation/local_eats_controller.dart';
import 'package:live_local/features/reviews/data/demo_review_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/screens/restaurant_detail_screen.dart';
import 'package:live_local/screens/spot_detail_screen.dart';
import 'package:live_local/services/seed_data_service.dart';
import 'package:provider/provider.dart';

void main() {
  late DemoAuthRepository authRepository;
  late DemoSpotRepository spotRepository;
  late DemoReviewRepository reviewRepository;
  late DemoSavedItineraryRepository savedRepository;
  late DemoModerationRepository moderationRepository;
  late DemoLocalEatsRepository localEatsRepository;
  late AuthController authController;
  late SpotController spotController;
  late ReviewController reviewController;
  late ItineraryController itineraryController;
  late ModerationController moderationController;
  late LocalEatsController localEatsController;

  setUp(() async {
    authRepository = DemoAuthRepository();
    await authRepository.signIn(
      email: 'tourist@livelocal.com',
      password: SeedDataService.demoPassword,
    );
    authController = AuthController(repository: authRepository);
    await authController.initialize();

    spotRepository = DemoSpotRepository(authRepository);
    reviewRepository = DemoReviewRepository(authRepository);
    savedRepository = DemoSavedItineraryRepository(authRepository);
    moderationRepository = DemoModerationRepository(authRepository);
    localEatsRepository = DemoLocalEatsRepository(authRepository);

    spotController = SpotController(repository: spotRepository);
    reviewController = ReviewController(repository: reviewRepository);
    itineraryController = ItineraryController(repository: savedRepository);
    moderationController =
        ModerationController(repository: moderationRepository);
    localEatsController = LocalEatsController(repository: localEatsRepository);

    await Future.wait([
      spotController.loadSpots(),
      reviewController.loadReviews(),
      itineraryController.loadSavedPlaces(),
      localEatsController.loadData(),
    ]);
  });

  Widget buildTestApp({
    required Widget child,
    Locale locale = const Locale('en'),
  }) {
    return MultiProvider(
      providers: [
        Provider<ProtectedNavigation>(create: (_) => ProtectedNavigation()),
        ChangeNotifierProvider.value(value: authController),
        ChangeNotifierProvider.value(value: spotController),
        ChangeNotifierProvider.value(value: reviewController),
        ChangeNotifierProvider.value(value: itineraryController),
        ChangeNotifierProvider.value(value: moderationController),
        ChangeNotifierProvider.value(value: localEatsController),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: child,
      ),
    );
  }

  testWidgets(
      'Spot detail review composer contains anonymous switch defaulting to false',
      (tester) async {
    final spot = SeedDataService.getInitialSpots().first;
    await tester.pumpWidget(
      buildTestApp(
        child: SpotDetailScreen(spot: spot),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // Scroll down to reviews section
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 200));

    // Tap "Write Review" button
    final writeButton = find.byIcon(Icons.rate_review_outlined);
    expect(writeButton, findsOneWidget);
    await tester.tap(writeButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Check anonymous switch is present
    expect(find.text('Post anonymously'), findsOneWidget);
    expect(
        find.text('Hide my name from other LiveLocal users.'), findsOneWidget);

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    final switchWidget = tester.widget<Switch>(switchFinder);
    expect(switchWidget.value, isFalse);

    // Toggle switch to true
    await tester.tap(switchFinder);
    await tester.pump(const Duration(milliseconds: 200));

    final updatedSwitch = tester.widget<Switch>(find.byType(Switch));
    expect(updatedSwitch.value, isTrue);

    // Fill comment and submit
    await tester.enterText(
        find.byType(TextField), 'Fabulous place to explore in secret!');
    await tester.pump(const Duration(milliseconds: 100));

    final submitBtn = find.text('Submit Review');
    await tester.ensureVisible(submitBtn);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(submitBtn);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify review is now posted anonymously and shown as Anonymous
    final myReview = reviewController
        .getReviewsForSpot(spot.id)
        .singleWhere((r) => r.isOwnedByCurrentUser);
    expect(myReview.isAnonymous, isTrue);
    expect(myReview.userName, 'Anonymous');
    expect(find.text('Anonymous'), findsWidgets);
    expect(find.text('Your review'), findsOneWidget);
  });

  testWidgets(
      'BM localization renders correct Malay text for anonymity in Spot',
      (tester) async {
    final spot = SeedDataService.getInitialSpots().first;
    await tester.pumpWidget(
      buildTestApp(
        locale: const Locale('ms'),
        child: SpotDetailScreen(spot: spot),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // Scroll down to reviews section
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 200));

    // Tap write review button
    final writeButton = find.byIcon(Icons.rate_review_outlined);
    expect(writeButton, findsOneWidget);
    await tester.tap(writeButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Check Malay text
    expect(find.text('Siarkan secara tanpa nama'), findsOneWidget);
    expect(
      find.text('Sembunyikan nama saya daripada pengguna LiveLocal yang lain.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'Restaurant detail review sheet contains anonymous switch and saves review',
      (tester) async {
    final restaurant = SeedDataService.getInitialRestaurants().first;

    await tester.pumpWidget(
      buildTestApp(
        child: RestaurantDetailScreen(
          restaurant: restaurant,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // Scroll to review button
    final writeButton = find.byIcon(Icons.rate_review_outlined);
    await tester.scrollUntilVisible(
      writeButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 200));

    // Tap review button
    expect(writeButton, findsOneWidget);
    await tester.tap(writeButton);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify switch
    expect(find.text('Post anonymously'), findsOneWidget);
    expect(
        find.text('Hide my name from other LiveLocal users.'), findsOneWidget);

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<Switch>(switchFinder).value, isFalse);

    // Toggle switch on
    await tester.tap(switchFinder);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    // Enter text and save
    await tester.enterText(
        find.byType(TextField), 'Delicious food kept anonymous!');
    await tester.pump(const Duration(milliseconds: 100));

    final saveBtn = find.text('Save review');
    await tester.ensureVisible(saveBtn);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(saveBtn);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    final savedReview = reviewController
        .getReviewsForRestaurant(restaurant.id)
        .singleWhere((r) => r.isOwnedByCurrentUser);
    expect(savedReview.isAnonymous, isTrue);
    expect(savedReview.userName, 'Anonymous');
  });
}
