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
import 'package:live_local/features/moderation/domain/moderation_repository.dart';
import 'package:live_local/features/moderation/presentation/moderation_controller.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/restaurants/presentation/local_eats_controller.dart';
import 'package:live_local/features/reviews/data/demo_review_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/models/review_model.dart';
import 'package:live_local/screens/restaurant_detail_screen.dart';
import 'package:live_local/screens/spot_detail_screen.dart';
import 'package:live_local/services/seed_data_service.dart';
import 'package:provider/provider.dart';

class SpyModerationRepository implements ModerationRepository {
  final List<Map<String, String>> blockCalls = [];
  final List<Map<String, dynamic>> reportCalls = [];

  @override
  bool get supportsUserBlocking => true;

  @override
  Future<ModerationReceipt> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    String? explanation,
    required bool hideForReporter,
  }) async {
    reportCalls.add({
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'explanation': explanation,
      'hideForReporter': hideForReporter,
    });
    return const ModerationReceipt(
      id: 'mock-report-id',
      status: 'pending',
      version: 1,
    );
  }

  @override
  Future<UserBlockReceipt> blockContentAuthor({
    required String targetType,
    required String targetId,
  }) async {
    blockCalls.add({'targetType': targetType, 'targetId': targetId});
    return const UserBlockReceipt(
      userId: 'server-resolved-user-id',
      displayName: 'Anonymous',
    );
  }

  @override
  Future<List<BlockedUser>> listBlockedUsers() async => const [];

  @override
  Future<void> unblockUser(String userId) async {}
}

void main() {
  late DemoAuthRepository authRepository;
  late DemoSpotRepository spotRepository;
  late DemoReviewRepository reviewRepository;
  late DemoSavedItineraryRepository savedRepository;
  late SpyModerationRepository moderationRepository;
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
    moderationRepository = SpyModerationRepository();
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

  testWidgets(
      'Anonymous review offers Block this reviewer and Report without exposing author user_id',
      (tester) async {
    final spot = SeedDataService.getInitialSpots().first;

    // Seed an anonymous review from another user
    final anonReview = ReviewModel(
      id: 'anon-review-12345',
      spotId: spot.id,
      userId: 'secret-author-user-id',
      userName: 'Anonymous',
      rating: 4.5,
      comment: 'An anonymous perspective on this place.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isAnonymous: true,
      isOwnedByCurrentUser: false,
    );
    reviewRepository.addReviewForTesting(anonReview);
    await reviewController.loadReviews();

    await tester.pumpWidget(
      buildTestApp(
        child: SpotDetailScreen(spot: spot),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // Scroll to review
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify displayed author is "Anonymous" and secret-author-user-id is never present in widget tree
    expect(find.text('Anonymous'), findsWidgets);
    expect(find.text('secret-author-user-id'), findsNothing);

    // Open review safety menu
    final safetyMenuButton = find.byTooltip('Review safety options');
    expect(safetyMenuButton, findsWidgets);
    await tester.tap(safetyMenuButton.first);
    await tester.pumpAndSettle();

    // Verify Report review and Block this reviewer are available
    expect(find.text('Report review'), findsOneWidget);
    expect(find.text('Block this reviewer'), findsOneWidget);

    // Tap Block this reviewer
    await tester.tap(find.text('Block this reviewer'));
    await tester.pumpAndSettle();

    // Confirm block dialog
    expect(find.text('Block this account?'), findsOneWidget);
    await tester.tap(find.text('Block account'));
    await tester.pumpAndSettle();

    // Verify generic anonymous block message is displayed (no real name)
    expect(
      find.text('Reviewer blocked. Their public content is hidden for you.'),
      findsOneWidget,
    );

    // Verify backend block was called using targetType: review and targetId: review.id, NOT user_id
    expect(moderationRepository.blockCalls.length, 1);
    expect(moderationRepository.blockCalls.first['targetType'], 'review');
    expect(moderationRepository.blockCalls.first['targetId'], anonReview.id);
  });

  testWidgets(
      'BM localization displays Sekat pengulas ini and Laporkan ulasan for anonymous reviews',
      (tester) async {
    final spot = SeedDataService.getInitialSpots().first;

    final anonReview = ReviewModel(
      id: 'anon-review-bm-99',
      spotId: spot.id,
      userId: 'hidden-bm-author',
      userName: 'Anonymous',
      rating: 5.0,
      comment: 'Ulasan tanpa nama yang hebat.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isAnonymous: true,
      isOwnedByCurrentUser: false,
    );
    reviewRepository.addReviewForTesting(anonReview);
    await reviewController.loadReviews();

    await tester.pumpWidget(
      buildTestApp(
        locale: const Locale('ms'),
        child: SpotDetailScreen(spot: spot),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // Scroll to review
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 200));

    // Open Malay review safety menu
    final safetyMenuButton = find.byTooltip('Pilihan keselamatan ulasan');
    expect(safetyMenuButton, findsWidgets);
    await tester.tap(safetyMenuButton.first);
    await tester.pumpAndSettle();

    // Verify Malay action names
    expect(find.text('Laporkan ulasan'), findsOneWidget);
    expect(find.text('Sekat pengulas ini'), findsOneWidget);

    // Tap Sekat pengulas ini
    await tester.tap(find.text('Sekat pengulas ini'));
    await tester.pumpAndSettle();

    // Confirm dialog in BM
    expect(find.text('Sekat akaun ini?'), findsOneWidget);
    await tester.tap(find.text('Sekat akaun'));
    await tester.pumpAndSettle();

    // Verify generic BM snackbar message
    expect(
      find.text(
          'Pengulas telah disekat. Kandungan awam mereka disembunyikan untuk anda.'),
      findsOneWidget,
    );
  });

  testWidgets('Own anonymous review does not show Block or Report options',
      (tester) async {
    final spot = SeedDataService.getInitialSpots().first;

    // Current user's own anonymous review
    final myAnonReview = ReviewModel(
      id: 'my-own-anon-review-1',
      spotId: spot.id,
      userId: authRepository.currentAccountForDemo!.id,
      userName: 'Anonymous',
      rating: 5.0,
      comment: 'My own anonymous review here.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isAnonymous: true,
      isOwnedByCurrentUser: true,
    );
    reviewRepository.addReviewForTesting(myAnonReview);
    await reviewController.loadReviews();

    await tester.pumpWidget(
      buildTestApp(
        child: SpotDetailScreen(spot: spot),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // Scroll to reviews
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 200));

    // Should show "Your review" and edit icon, but no "Review safety options" tooltip for own review
    expect(find.text('Your review'), findsOneWidget);
    expect(find.byTooltip('Edit review'), findsWidgets);
    expect(find.text('Block this reviewer'), findsNothing);
  });
}
