import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/core/errors/app_exception.dart';
import 'package:live_local/core/validation/social_url_validator.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/auth/presentation/auth_controller.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/restaurants/domain/generated_restaurant_listing.dart';
import 'package:live_local/features/restaurants/domain/local_eats_repository.dart';
import 'package:live_local/features/restaurants/presentation/local_eats_controller.dart';
import 'package:live_local/models/restaurant_model.dart';
import 'package:live_local/screens/add_restaurant_screen.dart';
import 'package:provider/provider.dart';

void main() {
  Widget buildApp({
    required AuthController authController,
    required LocalEatsController localEatsController,
    Widget? child,
    RestaurantModel? source,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<LocalEatsController>.value(
          value: localEatsController,
        ),
      ],
      child: MaterialApp(
        home: child ?? AddRestaurantScreen(source: source),
        routes: {
          '/creator-application': (_) =>
              const Scaffold(body: Text('Creator Application Screen')),
          '/login': (_) => const Scaffold(body: Text('Login Screen')),
          '/my-submissions': (_) =>
              const Scaffold(body: Text('My Submissions Screen')),
        },
      ),
    );
  }

  group('AI Restaurant Import & Moderation Full Pipeline Tests', () {
    test('1. Instagram post URL is accepted', () {
      expect(
        SocialUrlValidator.isReviewPost(
            'https://www.instagram.com/p/C9xyz456/'),
        isTrue,
      );
    });

    test('2. Instagram Reel URL is accepted', () {
      expect(
        SocialUrlValidator.isReviewPost(
          'https://instagram.com/reel/DEfg890/?igsh=123',
        ),
        isTrue,
      );
    });

    test('3. TikTok video URL is accepted', () {
      expect(
        SocialUrlValidator.isReviewPost(
          'https://www.tiktok.com/@penangfood/video/7182930495829102938',
        ),
        isTrue,
      );
      expect(
        SocialUrlValidator.isReviewPost('https://vt.tiktok.com/ZS2aBcDe/'),
        isTrue,
      );
    });

    testWidgets(
      '4 & 6 & 7. TikTok profile URL is rejected in ACTIVE UI without calling repository and no connect button appears',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');
        final mockRepo = _MockSpyLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: mockRepo);

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
          ),
        );
        await tester.pumpAndSettle();

        // 6. Verify Connect creator account button never appears
        expect(find.text('Connect creator account'), findsNothing);

        await tester.enterText(
          find.byKey(const Key('ai_source_field')),
          'https://www.tiktok.com/@somecreator',
        );
        await tester.tap(find.byKey(const Key('ai_generate_button')));
        await tester.pumpAndSettle();

        // 4. Rejected with specific message
        expect(
          find.text(
            'Paste a TikTok review video or Instagram post/Reel link, not a profile link.',
          ),
          findsOneWidget,
        );

        // 7. Generation repository is NOT called
        expect(mockRepo.generateCalls, 0);
        expect(find.text('Connect creator account'), findsNothing);
      },
    );

    testWidgets(
      '5 & 7. Instagram profile URL is rejected in ACTIVE UI without calling repository',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');
        final mockRepo = _MockSpyLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: mockRepo);

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('ai_source_field')),
          'https://instagram.com/klfoodie/',
        );
        await tester.tap(find.byKey(const Key('ai_generate_button')));
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Paste a TikTok review video or Instagram post/Reel link, not a profile link.',
          ),
          findsOneWidget,
        );
        expect(mockRepo.generateCalls, 0);
      },
    );

    testWidgets(
      '8. AI draft remains fully editable after generation',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');
        final mockRepo = _MockSpyLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: mockRepo);

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('ai_source_field')),
          'https://www.tiktok.com/@foodie/video/7182930495829102938',
        );
        await tester.tap(find.byKey(const Key('ai_generate_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('ai_draft_notice')), findsOneWidget);

        // Edit restaurant name
        await tester.enterText(
          find.byKey(const Key('restaurant_name_field')),
          'Custom Hand-Edited Restaurant',
        );
        final nameField = tester.widget<TextFormField>(
          find.byKey(const Key('restaurant_name_field')),
        );
        expect(nameField.controller?.text, 'Custom Hand-Edited Restaurant');
      },
    );

    testWidgets(
      '9. Applying AI draft does not auto-submit restaurant',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');
        final mockRepo = _MockSpyLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: mockRepo);

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('ai_source_field')),
          'https://www.tiktok.com/@foodie/video/7182930495829102938',
        );
        await tester.tap(find.byKey(const Key('ai_generate_button')));
        await tester.pumpAndSettle();

        // No submit occurred
        expect(mockRepo.submittedRevisionId, isNull);
        expect(
            find.byKey(const Key('restaurant_submit_button')), findsOneWidget);
      },
    );

    testWidgets(
      '10. User-entered fields are not silently overwritten; confirmation dialog is shown',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');
        final mockRepo = _MockSpyLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: mockRepo);

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
          ),
        );
        await tester.pumpAndSettle();

        // User enters a manual name
        await tester.enterText(
          find.byKey(const Key('restaurant_name_field')),
          'Pre-existing Manual Entry',
        );

        // User triggers AI generation
        await tester.enterText(
          find.byKey(const Key('ai_source_field')),
          'https://www.tiktok.com/@foodie/video/7182930495829102938',
        );
        await tester.tap(find.byKey(const Key('ai_generate_button')));
        await tester.pumpAndSettle();

        // Dialog should appear
        expect(
          find.text('Replace current details with this AI draft?'),
          findsOneWidget,
        );

        // User taps Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Manual entry is preserved
        final nameField = tester.widget<TextFormField>(
          find.byKey(const Key('restaurant_name_field')),
        );
        expect(nameField.controller?.text, 'Pre-existing Manual Entry');
      },
    );

    testWidgets(
      '11. Revision with existing cover photo may reuse it without new image upload',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');
        final mockRepo = _MockSpyLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: mockRepo);

        final sourceWithCover = RestaurantModel(
          id: 'rest-with-cover',
          revisionId: 'rev-with-cover',
          name: 'Existing Resto',
          address: '123 Jalan Ampang',
          state: 'Kuala Lumpur',
          city: 'Kuala Lumpur',
          cuisineType: 'Local Kopitiam',
          priceRange: r'53133',
          reviewedDishes: 'Kaya Toast',
          influencerId: 'foodie-id',
          influencerName: 'Foodie',
          socialMediaUrl:
              'https://www.tiktok.com/@foodie/video/1112223334445556667',
          coverPhotoUrl: 'https://example.com/cover.jpg',
          isOwnedByCurrentUser: true,
        );

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
            source: sourceWithCover,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Submit revision without selecting a new image
        await tester.tap(find.byKey(const Key('restaurant_submit_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(mockRepo.revisedInputs, hasLength(1));
        expect(mockRepo.revisedInputs.first.name, 'Existing Resto');
      },
    );

    testWidgets(
      '12. Revision without existing cover photo requires selecting a cover photo',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');
        final mockRepo = _MockSpyLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: mockRepo);

        final sourceWithoutCover = RestaurantModel(
          id: 'rest-no-cover',
          revisionId: 'rev-no-cover',
          name: 'Existing Resto No Cover',
          address: '123 Jalan Ampang',
          state: 'Kuala Lumpur',
          city: 'Kuala Lumpur',
          cuisineType: 'Local Kopitiam',
          priceRange: r'53133',
          reviewedDishes: 'Kaya Toast',
          influencerId: 'foodie-id',
          influencerName: 'Foodie',
          socialMediaUrl:
              'https://www.tiktok.com/@foodie/video/1112223334445556667',
          coverPhotoUrl: '', // empty cover
          isOwnedByCurrentUser: true,
        );

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
            source: sourceWithoutCover,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('restaurant_submit_button')));
        await tester.pumpAndSettle();

        expect(find.text('Please select a cover photo.'), findsOneWidget);
        expect(mockRepo.revisedInputs, isEmpty);
      },
    );

    testWidgets(
      '13. Tourist cannot access real Creator Restaurant generation flow',
      (tester) async {
        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('tourist@livelocal.com', '123456');
        final localEatsRepo = DemoLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: localEatsRepo);

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Creator tools required'), findsOneWidget);
        expect(find.byKey(const Key('ai_source_field')), findsNothing);
        expect(find.byKey(const Key('ai_generate_button')), findsNothing);

        expect(
          () => localEatsRepo.generateRestaurantListingFromSource(
            'https://www.instagram.com/reel/C7abc123/',
          ),
          throwsA(isA<AppException>().having(
            (e) => e.code,
            'code',
            AppErrorCode.forbidden,
          )),
        );
      },
    );

    test(
      '14. Final Restaurant enters Admin moderation pipeline and is not public until approved',
      () async {
        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');
        final localEatsRepo = DemoLocalEatsRepository(authRepo);

        // Creator creates draft and submits
        final draft = await localEatsRepo.createRestaurantDraft(
          input: const RestaurantDraftInput(
            name: 'Moderation Test Resto',
            address: '100 Beach Street',
            state: 'Penang',
            city: 'George Town',
            cuisineType: 'Nyonya',
            priceRange: r'53133',
            reviewedDishes: 'Asam Laksa',
            socialMediaUrl: 'https://www.instagram.com/reel/C8pipeline/',
          ),
          imageBytes: Uint8List.fromList([
            0xff,
            0xd8,
            0xff,
            0xe0,
            0x00,
            0x10,
            0x4a,
            0x46,
            0x49,
            0x46,
          ]),
          imageMimeType: 'image/jpeg',
        );

        await localEatsRepo.submitRestaurant(revisionId: draft.revisionId);

        // Not in public listings before approval
        final publicBefore = await localEatsRepo.fetchPublicRestaurants();
        expect(
          publicBefore.any((r) => r.name == 'Moderation Test Resto'),
          isFalse,
        );

        // Appears in Admin pending submissions
        await authCtrl.login('admin@livelocal.com', '123456');
        final pending = await localEatsRepo.fetchPendingRestaurants();
        final submittedRest =
            pending.firstWhere((r) => r.name == 'Moderation Test Resto');
        expect(submittedRest.status, 'submitted');

        // Admin approves
        await localEatsRepo.moderateRestaurant(
          restaurant: submittedRest,
          decision: 'approved',
          reason: 'Verified authentic local restaurant',
        );

        // Now appears in public listings
        final publicAfter = await localEatsRepo.fetchPublicRestaurants();
        expect(
          publicAfter.any((r) => r.name == 'Moderation Test Resto'),
          isTrue,
        );
      },
    );
  });
}

class _MockSpyLocalEatsRepository extends DemoLocalEatsRepository {
  _MockSpyLocalEatsRepository(super.authRepository);

  int generateCalls = 0;
  String? submittedRevisionId;
  final List<RestaurantDraftInput> revisedInputs = [];

  @override
  Future<SocialSourceAnalysisResult> generateRestaurantListingFromSource(
    String sourceUrl,
  ) async {
    generateCalls++;
    return const SocialSourceAnalysisResult(
      sourceType: 'post',
      platform: 'tiktok',
      candidates: [
        GeneratedRestaurantListing(
          restaurantName: 'Famous Nasi Kandar',
          address: '45 Jalan Penang',
          state: 'Penang',
          city: 'George Town',
          cuisineType: 'Nasi Kandar / Indian Muslim',
          priceRange: r'$$',
          reviewedDishes: 'Nasi Kandar Ayam Bawang',
          sourcePlatform: 'tiktok',
          sourcePostUrl:
              'https://www.tiktok.com/@foodie/video/7182930495829102938',
          confidence: 0.95,
          missingFields: [],
        ),
      ],
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
      restaurantId: 'rest-rev-id',
      revisionId: 'rev-rev-id',
      probableDuplicates: [],
    );
  }

  @override
  Future<void> submitRestaurant({
    required String revisionId,
    String? duplicateOverrideReason,
  }) async {
    submittedRevisionId = revisionId;
  }
}
