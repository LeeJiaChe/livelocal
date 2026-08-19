import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/itinerary_controller.dart';
import 'package:live_local/controllers/review_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/routing/protected_navigation.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/moderation/data/demo_moderation_repository.dart';
import 'package:live_local/features/moderation/presentation/moderation_controller.dart';
import 'package:live_local/features/reviews/data/demo_review_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/screens/spot_detail_screen.dart';
import 'package:live_local/services/seed_data_service.dart';
import 'package:provider/provider.dart';

void main() {
  late DemoAuthRepository authRepository;
  late DemoSpotRepository spotRepository;
  late DemoReviewRepository reviewRepository;
  late DemoSavedItineraryRepository savedRepository;
  late DemoModerationRepository moderationRepository;
  late AuthController authController;
  late SpotController spotController;
  late ReviewController reviewController;
  late ItineraryController itineraryController;
  late ModerationController moderationController;

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

    spotController = SpotController(repository: spotRepository);
    reviewController = ReviewController(repository: reviewRepository);
    itineraryController = ItineraryController(repository: savedRepository);
    moderationController =
        ModerationController(repository: moderationRepository);

    await Future.wait([
      spotController.loadSpots(),
      reviewController.loadReviews(),
      itineraryController.loadSavedPlaces(),
    ]);
  });

  Widget buildSpotDetailApp({required Widget child}) {
    return MultiProvider(
      providers: [
        Provider<ProtectedNavigation>(create: (_) => ProtectedNavigation()),
        ChangeNotifierProvider.value(value: authController),
        ChangeNotifierProvider.value(value: spotController),
        ChangeNotifierProvider.value(value: reviewController),
        ChangeNotifierProvider.value(value: itineraryController),
        ChangeNotifierProvider.value(value: moderationController),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets(
      'Spot Detail renders review text once and provides language controls',
      (tester) async {
    final spot = SeedDataService.getInitialSpots().first;
    await tester.pumpWidget(
      buildSpotDetailApp(
        child: SpotDetailScreen(spot: spot),
      ),
    );
    await tester.pumpAndSettle();

    // The initial seed review comment
    const expectedComment =
        'Super authentic Hainanese coffee! The toast was perfectly crispy and charcoal grilled. A true hidden gem.';

    // Scroll down until review is visible
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    // Verify the review comment appears EXACTLY ONCE
    expect(find.text(expectedComment), findsOneWidget);

    // Verify language selector affordances appear
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('ZH'), findsOneWidget);
    expect(find.text('MS'), findsOneWidget);

    // Switch to ZH -> shows fallback notice without fake translated text
    await tester.tap(find.text('ZH'));
    await tester.pumpAndSettle();

    expect(find.text(expectedComment), findsNothing);
    expect(find.textContaining('【中文】'), findsNothing);
    expect(
      find.text(
          'Translation (ZH) is not available for this review in this build.'),
      findsOneWidget,
    );

    // Switch to MS -> shows fallback notice
    await tester.tap(find.text('MS'));
    await tester.pumpAndSettle();

    expect(find.textContaining('[Malay]'), findsNothing);
    expect(
      find.text(
          'Translation (MS) is not available for this review in this build.'),
      findsOneWidget,
    );

    // Switch back to EN -> restores original comment
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(find.text(expectedComment), findsOneWidget);
  });

  testWidgets(
      'Spot Detail scroll-to-top is hidden at top and shows when scrolled',
      (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final spot = SeedDataService.getInitialSpots().first;
    await tester.pumpWidget(
      buildSpotDetailApp(
        child: SpotDetailScreen(spot: spot),
      ),
    );
    await tester.pumpAndSettle();

    // At top of screen, back-to-top FAB is NOT present
    expect(find.byTooltip('Back to top'), findsNothing);

    // Scroll down meaningfully
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    // FAB becomes available
    expect(find.byTooltip('Back to top'), findsOneWidget);

    // Tap back-to-top button
    await tester.tap(find.byTooltip('Back to top'));
    await tester.pumpAndSettle();

    // Verify returned to top without exception
    expect(find.byTooltip('Back to top'), findsNothing);
  });

  testWidgets(
      'Spot Detail preserves actions (upvote, save, review, safety menu)',
      (tester) async {
    final spot = SeedDataService.getInitialSpots().first;
    await tester.pumpWidget(
      buildSpotDetailApp(
        child: SpotDetailScreen(spot: spot),
      ),
    );
    await tester.pumpAndSettle();

    // Spot actions
    expect(find.byTooltip('Save place'), findsOneWidget);
    expect(find.byTooltip('Spot safety options'), findsOneWidget);
    expect(find.text('Write Review'), findsOneWidget);
    expect(find.textContaining('Upvote this spot'), findsOneWidget);
  });

  testWidgets(
      'Spot Detail renders cleanly across mobile viewports without overflow',
      (tester) async {
    final spot = SeedDataService.getInitialSpots().first;
    final viewports = [
      const Size(360, 640),
      const Size(390, 844),
      const Size(412, 915),
    ];

    for (final size in viewports) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        buildSpotDetailApp(
          child: SpotDetailScreen(spot: spot),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    }
    tester.view.resetPhysicalSize();
  });
}
