import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/constants/malaysia_states.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/config/app_environment.dart';
import 'package:live_local/core/routing/protected_navigation.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/guides/data/demo_guide_repository.dart';
import 'package:live_local/features/guides/presentation/guide_controller.dart';
import 'package:live_local/features/guides/presentation/submit_guide_screen.dart';
import 'package:live_local/features/influencer_applications/data/demo_influencer_application_repository.dart';
import 'package:live_local/features/influencer_applications/presentation/creator_application_screen.dart';
import 'package:live_local/features/influencer_applications/presentation/influencer_application_controller.dart';
import 'package:live_local/features/moderation/presentation/ugc_consent_dialog.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/features/spots/domain/spot_taxonomy.dart';
import 'package:live_local/models/guide_model.dart';
import 'package:live_local/models/restaurant_model.dart';
import 'package:live_local/models/spot_model.dart';
import 'package:live_local/screens/add_restaurant_screen.dart';
import 'package:live_local/screens/login_screen.dart';
import 'package:live_local/screens/my_submissions_screen.dart';
import 'package:live_local/screens/submit_spot_screen.dart';
import 'package:live_local/widgets/guide_list_item.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Comprehensive Contribution Flows, Roles & Attribution Tests', () {
    late DemoAuthRepository authRepo;
    late DemoSpotRepository spotRepo;
    late DemoGuideRepository guideRepo;
    late DemoLocalEatsRepository eatsRepo;
    late DemoInfluencerApplicationRepository influencerRepo;

    late AuthController authCtrl;
    late SpotController spotCtrl;
    late GuideController guideCtrl;
    late LocalEatsController eatsCtrl;
    late InfluencerApplicationController influencerCtrl;
    late ProtectedNavigation protectedNav;
    late AppConfiguration appConfig;

    setUp(() async {
      authRepo = DemoAuthRepository();
      spotRepo = DemoSpotRepository(authRepo);
      guideRepo = DemoGuideRepository(authRepo);
      eatsRepo = DemoLocalEatsRepository(authRepo);
      influencerRepo = DemoInfluencerApplicationRepository(authRepo);

      authCtrl = AuthController(repository: authRepo);
      spotCtrl = SpotController(repository: spotRepo);
      guideCtrl = GuideController(repository: guideRepo);
      eatsCtrl = LocalEatsController(repository: eatsRepo);
      influencerCtrl =
          InfluencerApplicationController(repository: influencerRepo);
      protectedNav = ProtectedNavigation();
      appConfig = AppConfiguration.demoForTesting();
      UgcConsentDialog.onAcceptOverride = () async {};

      await authCtrl.initialize();
    });

    tearDown(() {
      UgcConsentDialog.onAcceptOverride = null;
    });

    Widget createTestApp({required Widget home}) {
      return MultiProvider(
        providers: [
          Provider<AppConfiguration>.value(value: appConfig),
          ChangeNotifierProvider.value(value: authCtrl),
          ChangeNotifierProvider.value(value: spotCtrl),
          ChangeNotifierProvider.value(value: guideCtrl),
          ChangeNotifierProvider.value(value: eatsCtrl),
          ChangeNotifierProvider.value(value: influencerCtrl),
          Provider<ProtectedNavigation>.value(value: protectedNav),
        ],
        child: MaterialApp(
          home: home,
          routes: {
            '/login': (_) => const LoginScreen(),
            '/submit-spot': (_) => const SubmitSpotScreen(),
            '/submit-guide': (_) => const SubmitGuideScreen(),
            '/add-restaurant': (_) => const AddRestaurantScreen(),
            '/creator-application': (_) => const CreatorApplicationScreen(),
            '/my-submissions': (_) => const MySubmissionsScreen(),
          },
        ),
      );
    }

    testWidgets(
        '1. Guest opening SubmitSpotScreen shows sign in prompt with lock icon',
        (tester) async {
      await tester.pumpWidget(createTestApp(home: const SubmitSpotScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to share a place'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets(
        '2. Guest tapping Sign in on SubmitSpotScreen redirects to login with pending nav',
        (tester) async {
      await tester.pumpWidget(createTestApp(home: const SubmitSpotScreen()));
      await tester.pumpAndSettle();

      final signInBtn = find.widgetWithText(FilledButton, 'Sign in');
      expect(signInBtn, findsOneWidget);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);
    });

    testWidgets(
        '3. Guest opening SubmitGuideScreen shows sign in prompt with lock icon',
        (tester) async {
      await tester.pumpWidget(createTestApp(home: const SubmitGuideScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to create a guide'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets(
        '4. Guest tapping Sign in on SubmitGuideScreen redirects to login with pending nav',
        (tester) async {
      await tester.pumpWidget(createTestApp(home: const SubmitGuideScreen()));
      await tester.pumpAndSettle();

      final signInBtn = find.widgetWithText(FilledButton, 'Sign in');
      expect(signInBtn, findsOneWidget);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);
    });

    testWidgets(
        '5. Guest opening AddRestaurantScreen shows sign in prompt with lock icon',
        (tester) async {
      await tester.pumpWidget(createTestApp(home: const AddRestaurantScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to recommend a restaurant'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets(
        '6. Guest tapping Sign in on AddRestaurantScreen redirects to login with pending nav',
        (tester) async {
      await tester.pumpWidget(createTestApp(home: const AddRestaurantScreen()));
      await tester.pumpAndSettle();

      final signInBtn = find.widgetWithText(FilledButton, 'Sign in');
      expect(signInBtn, findsOneWidget);
      await tester.tap(signInBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(protectedNav.hasPending, isTrue);
    });

    testWidgets(
        '7. Tourist opening AddRestaurantScreen shows Creator eligibility explanation',
        (tester) async {
      await authCtrl.login('tourist@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const AddRestaurantScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Creator tools required'), findsOneWidget);
      expect(find.text('Apply to become a Creator'), findsOneWidget);
    });

    testWidgets(
        '8. Tourist tapping Apply to become a Creator navigates to /creator-application',
        (tester) async {
      await authCtrl.login('tourist@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const AddRestaurantScreen()));
      await tester.pumpAndSettle();

      final applyBtn =
          find.widgetWithText(FilledButton, 'Apply to become a Creator');
      expect(applyBtn, findsOneWidget);
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      expect(find.byType(CreatorApplicationScreen), findsOneWidget);
    });

    testWidgets(
        '9. Creator opening AddRestaurantScreen displays full submission form',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('foodie@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const AddRestaurantScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Recommend a restaurant'), findsWidgets);
      expect(find.text('Restaurant info'), findsOneWidget);
      expect(find.text('Location details'), findsOneWidget);
      expect(find.text('Recommended dishes & source'), findsOneWidget);
      expect(find.text('Cover photo'), findsOneWidget);
    });

    testWidgets(
        '10. Creator submitting restaurant with unsupported source URL fails validation',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('foodie@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const AddRestaurantScreen()));
      await tester.pumpAndSettle();

      // Enter restaurant name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Restaurant name'),
        'Test Restaurant',
      );
      // Enter invalid URL
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Source / reference link'),
        'http://invalid-video-site.com/123',
      );
      await tester.pumpAndSettle();

      // Tap submit
      final submitBtn =
          find.widgetWithText(FilledButton, 'Submit restaurant for review');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Enter a public Google Maps, website, TikTok, or Instagram HTTPS URL.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        '11. Tourist opening SubmitSpotScreen displays SpotTaxonomy categories and MalaysiaStates',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('tourist@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const SubmitSpotScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Share a local place'), findsWidgets);
      expect(find.text('Place basics'), findsOneWidget);
      expect(find.text('Location details'), findsOneWidget);

      // Verify SpotTaxonomy default and canonical items exist
      expect(SpotTaxonomy.canonicalCategories.contains('Nature'), isTrue);
      expect(SpotTaxonomy.canonicalCategories.contains('Heritage'), isTrue);
      expect(MalaysiaStates.displayPenang, 'Penang');
      expect(MalaysiaStates.toCanonical('Penang'), 'Pulau Pinang');
    });

    testWidgets(
        '12. Revising a Spot with legacy category preserves the legacy category value',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('tourist@livelocal.com', '123456');

      final legacySpot = SpotModel(
        id: 'legacy-spot-1',
        submittedBy: 'tourist-id',
        name: 'Legacy Spot',
        description: 'A legacy spot with special non-canonical category.',
        category: 'Kopitiam / Traditional Hawker',
        state: 'Pulau Pinang',
        city: 'George Town',
        address: '10 Campbell Street',
        priceRange: r'$',
        bestTime: 'Morning',
        thingsToDo: 'Eat breakfast',
        imageUrl: '',
      );

      await tester.pumpWidget(
        createTestApp(home: SubmitSpotScreen(source: legacySpot)),
      );
      await tester.pumpAndSettle();

      // The category should be preserved as 'Kopitiam / Traditional Hawker'
      expect(find.text('Kopitiam / Traditional Hawker'), findsWidgets);
      expect(find.text('Penang'), findsWidgets);
    });

    testWidgets(
        '13. Revising a Restaurant preserves custom cuisine without defaulting',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('foodie@livelocal.com', '123456');

      final legacyRest = RestaurantModel(
        id: 'legacy-rest-1',
        influencerId: 'foodie-id',
        influencerName: 'Foodie Creator',
        name: 'Hainanese Heritage Kitchen',
        address: '25 Muntri Street',
        state: 'Pulau Pinang',
        city: 'George Town',
        cuisineType: 'Hainanese / Peranakan Fusion',
        priceRange: r'$$',
        reviewedDishes: 'Hainanese chicken chop, pie tee',
        socialMediaUrl: 'https://www.tiktok.com/@foodie/video/1234567890123456',
        coverPhotoUrl: '',
        status: 'approved',
      );

      await tester.pumpWidget(
        createTestApp(home: AddRestaurantScreen(source: legacyRest)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hainanese / Peranakan Fusion'), findsWidgets);
      expect(find.text('Penang'), findsWidgets);
    });

    testWidgets(
        '14. Tourist opening SubmitGuideScreen displays full form with 2 stops',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('tourist@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const SubmitGuideScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create a travel guide'), findsWidgets);
      expect(find.text('Guide overview'), findsOneWidget);
      expect(find.text('Ordered stops (Min. 2 stops)'), findsOneWidget);
      expect(find.text('Stop 1'), findsOneWidget);
      expect(find.text('Stop 2'), findsOneWidget);
    });

    testWidgets(
        '15. Adding another stop in SubmitGuideScreen increases stops to 3',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('tourist@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const SubmitGuideScreen()));
      await tester.pumpAndSettle();

      final addStopBtn =
          find.widgetWithText(OutlinedButton, 'Add another stop');
      expect(addStopBtn, findsOneWidget);
      await tester.tap(addStopBtn);
      await tester.pumpAndSettle();

      expect(find.text('Stop 3'), findsOneWidget);
    });

    testWidgets('16. Stop management UI correctly enforces minimum 2 stops',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('tourist@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const SubmitGuideScreen()));
      await tester.pumpAndSettle();

      // With 2 stops, no remove buttons are rendered (preventing dropping below 2)
      expect(find.byTooltip('Remove stop'), findsNothing);

      // Add a 3rd stop
      final addStopBtn =
          find.widgetWithText(OutlinedButton, 'Add another stop');
      await tester.tap(addStopBtn);
      await tester.pumpAndSettle();

      // Now remove button is available
      final removeButtons = find.byTooltip('Remove stop');
      expect(removeButtons, findsWidgets);

      // Tap remove
      await tester.tap(removeButtons.last);
      await tester.pumpAndSettle();

      // Back to 2 stops, remove button disappears
      expect(find.text('Stop 3'), findsNothing);
      expect(find.byTooltip('Remove stop'), findsNothing);
    });

    testWidgets(
        '17. Submitting valid 2-stop guide completes and displays success view',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('tourist@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const SubmitGuideScreen()));
      await tester.pumpAndSettle();

      // Fill in guide fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Guide title'),
        'George Town Heritage Walk',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Description & route summary'),
        'A comprehensive historic walking trail through central George Town.',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Neighbourhood or area'),
        'George Town',
      );
      await tester.pumpAndSettle();

      // Fill in stop 1 & 2 as custom stops
      final customSegments = find.text('Custom');
      expect(customSegments, findsNWidgets(2));
      await tester.tap(customSegments.first);
      await tester.tap(customSegments.last);
      await tester.pumpAndSettle();

      final stopNameFields =
          find.widgetWithText(TextFormField, 'Custom stop name');
      expect(stopNameFields, findsNWidgets(2));
      await tester.enterText(stopNameFields.first, 'Clan Jetties');

      final stopInstrFields =
          find.widgetWithText(TextFormField, 'Tips & walking directions');
      expect(stopInstrFields, findsNWidgets(2));
      await tester.enterText(
          stopInstrFields.first, 'Start at the main pier entrance');

      await tester.enterText(stopNameFields.last, 'Pinang Peranakan Mansion');
      await tester.enterText(stopInstrFields.last,
          'Walk 400m north along Church Street to the mansion');
      await tester.pumpAndSettle();

      // Select state
      final stateDropdown = find.byType(DropdownButtonFormField<String>);
      if (stateDropdown.evaluate().isNotEmpty) {
        await tester.tap(stateDropdown.first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Penang').last);
        await tester.pumpAndSettle();
      }

      // Submit
      final submitBtn =
          find.widgetWithText(FilledButton, 'Submit guide for review');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Accept UGC dialog if present
      final agreeBtn = find.text('Agree & Continue');
      if (agreeBtn.evaluate().isNotEmpty) {
        await tester.tap(agreeBtn);
        await tester.pumpAndSettle();
      }

      expect(find.text('Guide submitted for review'), findsOneWidget);
    });

    testWidgets('18. GuideListItem renders author attribution and stops count',
        (tester) async {
      final guide = GuideModel(
        id: 'guide-test-1',
        title: 'Penang Food Explorer',
        locationName: 'George Town',
        state: 'Penang',
        routeOverview:
            'Delicious spots along Campbell Street and Kimberley Street.',
        stops: ['Toh Soon Cafe', 'Line Clear', 'Chulia Night Market'],
        walkingSequence: [
          'Start at Toh Soon',
          'Walk to Line Clear',
          'Head to Chulia'
        ],
        estimatedDuration: '2 hours',
        authorDisplayName: 'Chef Tan',
        authorIsCreator: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuideListItem(
              guide: guide,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Penang Food Explorer'), findsOneWidget);
      expect(find.text('by Chef Tan'), findsOneWidget);
      expect(find.text('Creator'), findsOneWidget);
      expect(find.text('3 stops'), findsOneWidget);
      expect(find.text('2 hours'), findsOneWidget);
    });

    testWidgets(
        '19. GuideListItem for tourist author renders by Name without Creator badge',
        (tester) async {
      final guide = GuideModel(
        id: 'guide-test-2',
        title: 'Nature Trail',
        locationName: 'Penang Hill',
        state: 'Penang',
        routeOverview: 'Scenic hiking route from bottom station to the peak.',
        stops: ['Station Base', 'Halfway Tea House', 'The Habitat'],
        walkingSequence: ['Start at base', 'Climb path', 'Reach Habitat'],
        estimatedDuration: '3 hours',
        authorDisplayName: 'John Traveller',
        authorIsCreator: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GuideListItem(
              guide: guide,
              onTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nature Trail'), findsOneWidget);
      expect(find.text('by John Traveller'), findsOneWidget);
      expect(find.text('Creator'), findsNothing);
    });

    testWidgets(
        '20. MySubmissionsScreen loads and renders sections for submissions',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('tourist@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const MySubmissionsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('My Submissions'), findsOneWidget);
      expect(find.text('Contribution history'), findsOneWidget);
      expect(find.text('Local spots'), findsOneWidget);
      expect(find.text('Travel guides'), findsOneWidget);
    });

    testWidgets(
        '21. Restaurant quick cuisine chips update visible field text and source of truth',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('foodie@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const AddRestaurantScreen()));
      await tester.pumpAndSettle();

      final cuisineField = find.widgetWithText(TextFormField, 'Cuisine type');
      expect(cuisineField, findsOneWidget);

      // Tap 'Peranakan / Nyonya' chip
      await tester.tap(find.text('Peranakan / Nyonya'));
      await tester.pumpAndSettle();

      // Visible text field should now show 'Peranakan / Nyonya'
      expect(
          find.descendant(
              of: cuisineField, matching: find.text('Peranakan / Nyonya')),
          findsOneWidget);

      // Tap 'Hainanese' chip
      await tester.tap(find.text('Hainanese'));
      await tester.pumpAndSettle();

      // Visible text field should now show 'Hainanese'
      expect(
          find.descendant(of: cuisineField, matching: find.text('Hainanese')),
          findsOneWidget);
    });

    testWidgets(
        '22. Initial Hainanese revision visibly displays cuisine in AddRestaurantScreen',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('foodie@livelocal.com', '123456');

      final hainaneseRest = RestaurantModel(
        id: 'rest-hainan-1',
        influencerId: 'foodie-id',
        influencerName: 'Foodie Creator',
        name: 'Uncle Lim Hainan Chicken Rice',
        address: '15 Bishop Street',
        state: 'Pulau Pinang',
        city: 'George Town',
        cuisineType: 'Hainanese',
        priceRange: r'$',
        reviewedDishes: 'Steamed chicken, fragrance rice',
        socialMediaUrl:
            'https://www.tiktok.com/@foodie/video/998877665544332211',
        coverPhotoUrl: '',
        status: 'approved',
      );

      await tester.pumpWidget(
        createTestApp(home: AddRestaurantScreen(source: hainaneseRest)),
      );
      await tester.pumpAndSettle();

      final cuisineField = find.widgetWithText(TextFormField, 'Cuisine type');
      expect(
          find.descendant(of: cuisineField, matching: find.text('Hainanese')),
          findsOneWidget);
    });

    testWidgets(
        '23. New Spot and Guide forms require explicit non-default category and state selection',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('tourist@livelocal.com', '123456');

      // 1. SubmitSpotScreen
      await tester.pumpWidget(createTestApp(home: const SubmitSpotScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Select category'), findsOneWidget);
      expect(find.text('Select state'), findsOneWidget);

      await tester
          .tap(find.widgetWithText(FilledButton, 'Submit place for review'));
      await tester.pumpAndSettle();

      expect(find.text('Select category.'), findsOneWidget);
      expect(find.text('Select state.'), findsOneWidget);

      // 2. SubmitGuideScreen
      await tester.pumpWidget(createTestApp(home: const SubmitGuideScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Select state'), findsOneWidget);
    });
  });
}
