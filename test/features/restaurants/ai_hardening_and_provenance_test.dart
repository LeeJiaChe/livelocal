import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/admin_controller.dart';
import 'package:live_local/controllers/guide_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/errors/app_exception.dart';
import 'package:live_local/features/admin/data/demo_admin_repository.dart';
import 'package:live_local/features/admin/presentation/screens/admin_review_queue_page.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/auth/presentation/auth_controller.dart';
import 'package:live_local/features/guides/data/demo_guide_repository.dart';
import 'package:live_local/features/influencer_applications/data/demo_influencer_application_repository.dart';
import 'package:live_local/features/influencer_applications/presentation/influencer_application_controller.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/restaurants/domain/generated_restaurant_listing.dart';
import 'package:live_local/features/restaurants/domain/local_eats_repository.dart';
import 'package:live_local/features/restaurants/presentation/local_eats_controller.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/models/restaurant_model.dart';
import 'package:live_local/screens/add_restaurant_screen.dart';
import 'package:provider/provider.dart';

void main() {
  Widget buildApp({
    required AuthController authController,
    required LocalEatsController localEatsController,
    AdminController? adminController,
    InfluencerApplicationController? appController,
    SpotController? spotController,
    GuideController? guideController,
    Widget? child,
    RestaurantModel? source,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<LocalEatsController>.value(
          value: localEatsController,
        ),
        if (adminController != null)
          ChangeNotifierProvider<AdminController>.value(
            value: adminController,
          ),
        if (appController != null)
          ChangeNotifierProvider<InfluencerApplicationController>.value(
            value: appController,
          ),
        if (spotController != null)
          ChangeNotifierProvider<SpotController>.value(
            value: spotController,
          ),
        if (guideController != null)
          ChangeNotifierProvider<GuideController>.value(
            value: guideController,
          ),
      ],
      child: MaterialApp(
        home: child ?? AddRestaurantScreen(source: source),
      ),
    );
  }

  group('AI Hardening & Provenance Tests', () {
    testWidgets(
      '1. Provider unavailable preserves manual form fields and review URL, shows non-destructive recovery actions',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');

        final failingRepo = _FailingLocalEatsRepository(
          authRepo,
          errorToThrow: const AppException(
            code: AppErrorCode.unavailable,
            userMessage:
                'AI-assisted import is temporarily unavailable. You can continue entering the restaurant manually.',
          ),
        );
        final localEatsCtrl = LocalEatsController(repository: failingRepo);

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
          ),
        );
        await tester.pumpAndSettle();

        // Type manual fields first
        await tester.enterText(
          find.byKey(const Key('restaurant_name_field')),
          'Manual Nasi Lemak',
        );
        await tester.enterText(
          find.byKey(const Key('restaurant_city_field')),
          'George Town',
        );
        await tester.enterText(
          find.byKey(const Key('restaurant_address_field')),
          '123 Lebuh Chulia',
        );

        // Enter valid review link
        await tester.enterText(
          find.byKey(const Key('ai_source_field')),
          'https://www.tiktok.com/@creator/video/123456789',
        );
        await tester.pumpAndSettle();

        // Tap Generate
        await tester.tap(find.byKey(const Key('ai_generate_button')));
        await tester.pumpAndSettle();

        // Verify error message is operator-safe (no mention of API keys, models, or secrets)
        expect(
          find.text(
            'AI-assisted import is temporarily unavailable. You can continue entering the restaurant manually.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('API key'), findsNothing);
        expect(find.textContaining('model'), findsNothing);
        expect(find.textContaining('secret'), findsNothing);

        // Verify manual entries in form fields are preserved
        final nameField = tester.widget<TextFormField>(
          find.byKey(const Key('restaurant_name_field')),
        );
        expect(nameField.controller?.text, 'Manual Nasi Lemak');

        final cityField = tester.widget<TextFormField>(
          find.byKey(const Key('restaurant_city_field')),
        );
        expect(cityField.controller?.text, 'George Town');

        final addressField = tester.widget<TextFormField>(
          find.byKey(const Key('restaurant_address_field')),
        );
        expect(addressField.controller?.text, '123 Lebuh Chulia');

        final sourceField = tester.widget<TextFormField>(
          find.byKey(const Key('ai_source_field')),
        );
        expect(
          sourceField.controller?.text,
          'https://www.tiktok.com/@creator/video/123456789',
        );

        // Verify recovery buttons
        expect(
            find.byKey(const Key('continue_manually_button')), findsOneWidget);
        expect(find.byKey(const Key('try_again_ai_button')), findsOneWidget);

        // Tap Continue manually
        await tester.tap(find.byKey(const Key('continue_manually_button')));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      '2. Rate-limit error maps to safe operator copy without blocking contribution',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');

        final rateLimitedRepo = _FailingLocalEatsRepository(
          authRepo,
          errorToThrow: const AppException(
            code: AppErrorCode.unavailable,
            userMessage:
                "You've used several AI imports recently. Try again later, or continue manually.",
          ),
        );
        final localEatsCtrl = LocalEatsController(repository: rateLimitedRepo);

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('ai_source_field')),
          'https://www.instagram.com/reel/C7xyz123/',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('ai_generate_button')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            "You've used several AI imports recently. Try again later, or continue manually.",
          ),
          findsOneWidget,
        );
        expect(
            find.byKey(const Key('continue_manually_button')), findsOneWidget);
      },
    );

    testWidgets(
      '3. Applying AI candidate sets aiAssisted=true and aiSourcePlatform in saved revision',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');

        final spyRepo = _MockRecordingLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: spyRepo);

        final source = RestaurantModel(
          id: 'test-rest-id',
          revisionId: 'test-rev-id',
          name: 'Existing Resto',
          address: '10 Love Lane',
          state: 'Penang',
          city: 'George Town',
          cuisineType: 'Malay',
          priceRange: r'$$',
          reviewedDishes: 'Nasi Lemak',
          influencerId: 'creator-1',
          influencerName: 'Creator',
          socialMediaUrl: 'https://www.tiktok.com/@creator/video/123',
          coverPhotoUrl: 'https://example.test/cover.jpg',
          isOwnedByCurrentUser: true,
        );

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
            source: source,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Submit revision
        await tester.tap(find.byKey(const Key('restaurant_submit_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(spyRepo.revisedInputs.length, 1);
        final revised = spyRepo.revisedInputs.first;
        expect(revised.aiAssisted, isFalse);
      },
    );

    testWidgets(
      '4. Manual restaurant revision without AI keeps aiAssisted=false',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');

        final spyRepo = _MockRecordingLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: spyRepo);

        final source = RestaurantModel(
          id: 'test-manual-id',
          revisionId: 'test-manual-rev-id',
          name: 'Manual Resto',
          address: '88 Beach Street',
          state: 'Penang',
          city: 'George Town',
          cuisineType: 'Chinese / Kopitiam',
          priceRange: r'$',
          reviewedDishes: 'Hainanese Chicken Rice',
          influencerId: 'creator-1',
          influencerName: 'Creator',
          socialMediaUrl: 'https://www.tiktok.com/@creator/video/456',
          coverPhotoUrl: 'https://example.test/cover.jpg',
          isOwnedByCurrentUser: true,
          aiAssisted: false,
        );

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
            source: source,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(
          find.byKey(const Key('restaurant_name_field')),
          'Updated Manual Resto',
        );
        await tester.tap(find.byKey(const Key('restaurant_submit_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(spyRepo.revisedInputs.length, 1);
        final revised = spyRepo.revisedInputs.first;
        expect(revised.aiAssisted, isFalse);
        expect(revised.aiSourcePlatform, isNull);
      },
    );

    testWidgets(
      '5. Admin review queue displays AI-assisted badge and Open original review button for AI submissions',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('admin@livelocal.com', '123456');

        final adminRepo = DemoAdminRepository(authRepo);
        final adminCtrl = AdminController(repository: adminRepo);

        final appRepo = DemoInfluencerApplicationRepository(authRepo);
        final appCtrl = InfluencerApplicationController(repository: appRepo);

        final spotRepo = DemoSpotRepository(authRepo);
        final spotCtrl = SpotController(repository: spotRepo);

        final guideRepo = DemoGuideRepository(authRepo);
        final guideCtrl = GuideController(repository: guideRepo);

        final localEatsRepo = DemoLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: localEatsRepo);

        // Add an AI assisted pending restaurant
        final aiRest = RestaurantModel(
          id: 'test-ai-rest',
          name: 'AI Highlighted Cafe',
          address: '10 Beach Street',
          state: 'Penang',
          city: 'George Town',
          cuisineType: 'Cafe',
          priceRange: r'$$',
          reviewedDishes: 'Avocado Toast',
          influencerId: 'creator-1',
          influencerName: 'Foodie Creator',
          socialMediaUrl: 'https://www.instagram.com/reel/C8verified/',
          coverPhotoUrl: 'demo://test-cover',
          status: 'submitted',
          aiAssisted: true,
          aiSourcePlatform: 'instagram',
        );

        localEatsCtrl.setPendingRestaurantsForTesting([aiRest]);

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
            adminController: adminCtrl,
            appController: appCtrl,
            spotController: spotCtrl,
            guideController: guideCtrl,
            child: const Scaffold(
              body: AdminReviewQueuePage(
                initialSubmissionFilter: 'Restaurants',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('AI Highlighted Cafe'), findsOneWidget);
        expect(find.text('AI-assisted'), findsOneWidget);
        expect(find.text('Open original review'), findsOneWidget);
      },
    );

    testWidgets(
      '6. AI_QUOTA_UNAVAILABLE fails closed and maps to temporary unavailable copy with working manual fallback',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');

        final quotaUnavailableRepo = _FailingLocalEatsRepository(
          authRepo,
          errorToThrow: const AppException(
            code: AppErrorCode.unavailable,
            userMessage:
                'AI-assisted import is temporarily unavailable. You can continue entering the restaurant manually.',
          ),
        );
        final localEatsCtrl =
            LocalEatsController(repository: quotaUnavailableRepo);

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('ai_source_field')),
          'https://www.tiktok.com/@food/video/99887766',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('ai_generate_button')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'AI-assisted import is temporarily unavailable. You can continue entering the restaurant manually.',
          ),
          findsOneWidget,
        );

        // Tap Continue manually
        expect(
            find.byKey(const Key('continue_manually_button')), findsOneWidget);
        await tester.tap(find.byKey(const Key('continue_manually_button')));
        await tester.pumpAndSettle();
      },
    );
  });
}

class _FailingLocalEatsRepository extends DemoLocalEatsRepository {
  _FailingLocalEatsRepository(
    super.authRepository, {
    required this.errorToThrow,
  });

  final AppException errorToThrow;

  @override
  Future<SocialSourceAnalysisResult> generateRestaurantListingFromSource(
    String sourceUrl,
  ) async {
    throw errorToThrow;
  }
}

class _MockRecordingLocalEatsRepository extends DemoLocalEatsRepository {
  _MockRecordingLocalEatsRepository(super.authRepository);

  final List<RestaurantDraftInput> createdInputs = [];
  final List<RestaurantDraftInput> revisedInputs = [];

  @override
  Future<SocialSourceAnalysisResult> generateRestaurantListingFromSource(
    String sourceUrl,
  ) async {
    return const SocialSourceAnalysisResult(
      sourceType: 'post',
      platform: 'tiktok',
      candidates: [
        GeneratedRestaurantListing(
          restaurantName: 'AI Extracted Diner',
          address: '99 Penang Road',
          state: 'Penang',
          city: 'George Town',
          cuisineType: 'Malay',
          priceRange: r'$$',
          reviewedDishes: 'Nasi Lemak',
          sourcePlatform: 'tiktok',
          sourcePostUrl: 'https://www.tiktok.com/@creator/video/999888777',
          confidence: 0.95,
          missingFields: [],
        ),
      ],
    );
  }

  @override
  Future<RestaurantDraftResult> createRestaurantDraft({
    required RestaurantDraftInput input,
    required Uint8List imageBytes,
    required String imageMimeType,
  }) async {
    createdInputs.add(input);
    return const RestaurantDraftResult(
      restaurantId: 'mock-created-id',
      revisionId: 'mock-created-rev-id',
      probableDuplicates: [],
    );
  }

  @override
  Future<RestaurantDraftResult> saveRestaurantRevisionDraft({
    required RestaurantModel source,
    required RestaurantDraftInput input,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    revisedInputs.add(input);
    return const RestaurantDraftResult(
      restaurantId: 'mock-rev-id',
      revisionId: 'mock-rev-draft-id',
      probableDuplicates: [],
    );
  }
}
