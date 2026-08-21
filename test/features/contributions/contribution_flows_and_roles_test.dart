import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/routing/protected_navigation.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/guides/data/demo_guide_repository.dart';
import 'package:live_local/features/guides/presentation/guide_controller.dart';
import 'package:live_local/features/guides/presentation/submit_guide_screen.dart';
import 'package:live_local/features/influencer_applications/data/demo_influencer_application_repository.dart';
import 'package:live_local/features/influencer_applications/presentation/creator_application_screen.dart';
import 'package:live_local/features/influencer_applications/presentation/influencer_application_controller.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/screens/add_restaurant_screen.dart';
import 'package:live_local/screens/login_screen.dart';
import 'package:live_local/screens/my_submissions_screen.dart';
import 'package:live_local/screens/submit_spot_screen.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Contribution Flows and Role Gating Tests', () {
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

      await authCtrl.initialize();
    });

    Widget createTestApp({required Widget home}) {
      return MultiProvider(
        providers: [
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
        '2. Guest opening SubmitGuideScreen shows sign in prompt with lock icon',
        (tester) async {
      await tester.pumpWidget(createTestApp(home: const SubmitGuideScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to create a guide'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets(
        '3. Tourist opening AddRestaurantScreen shows Creator eligibility explanation',
        (tester) async {
      await authCtrl.login('tourist@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const AddRestaurantScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Creator tools required'), findsOneWidget);
      expect(find.text('Apply to become a Creator'), findsOneWidget);
    });

    testWidgets(
        '4. Creator opening AddRestaurantScreen displays full submission form',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('foodie@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const AddRestaurantScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Recommend a restaurant'), findsWidgets);
      expect(find.text('Restaurant info'), findsOneWidget);
      expect(find.text('Location details'), findsOneWidget);
      expect(find.text('Recommended dishes & social source'), findsOneWidget);
      expect(find.text('Cover photo'), findsOneWidget);
    });

    testWidgets(
        '5. Tourist opening SubmitSpotScreen displays full spot submission form',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('tourist@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const SubmitSpotScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Share a local place'), findsWidgets);
      expect(find.text('Place basics'), findsOneWidget);
      expect(find.text('Location details'), findsOneWidget);
      expect(find.text('About this place'), findsOneWidget);
      expect(find.text('Cover photo'), findsOneWidget);
    });

    testWidgets(
        '6. Tourist opening SubmitGuideScreen displays full guide form with stop management',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await authCtrl.login('tourist@livelocal.com', '123456');

      await tester.pumpWidget(createTestApp(home: const SubmitGuideScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create a travel guide'), findsWidgets);
      expect(find.text('Guide overview'), findsOneWidget);
      expect(find.text('Ordered stops (Min. 2 stops)'), findsOneWidget);
      expect(find.text('Add another stop'), findsOneWidget);
    });

    testWidgets(
        '7. MySubmissionsScreen loads and renders sections for submissions',
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
  });
}
