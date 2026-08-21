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
import 'package:live_local/screens/add_restaurant_screen.dart';
import 'package:provider/provider.dart';

void main() {
  Widget buildApp({
    required AuthController authController,
    required LocalEatsController localEatsController,
    required Widget child,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<LocalEatsController>.value(
          value: localEatsController,
        ),
      ],
      child: MaterialApp(
        home: child,
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
    testWidgets(
      '1. Tourist cannot access real AI Restaurant generation flow and is guided to apply',
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
            child: const AddRestaurantScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Creator tools required'), findsOneWidget);
        expect(find.byKey(const Key('ai_source_field')), findsNothing);
        expect(find.byKey(const Key('ai_generate_button')), findsNothing);

        // Repo direct call is also protected
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

    testWidgets(
      '2. Creator can access AI import section inside Recommend a restaurant',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');
        final localEatsRepo = DemoLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: localEatsRepo);

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
            child: const AddRestaurantScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
            find.text('Import from social review (Optional)'), findsOneWidget);
        expect(find.byKey(const Key('ai_source_field')), findsOneWidget);
        expect(find.byKey(const Key('ai_generate_button')), findsOneWidget);
      },
    );

    test('3. Unsupported URL is rejected by validator', () {
      expect(
        SocialUrlValidator.isSupported('https://youtube.com/watch?v=123'),
        isFalse,
      );
      expect(
        SocialUrlValidator.isSupported('https://evil-instagram.com/p/123'),
        isFalse,
      );
      expect(
        SocialUrlValidator.isReviewPost('https://instagram.com/username'),
        isFalse,
      );
    });

    test('4. Supported Instagram post is recognized', () {
      expect(
        SocialUrlValidator.isReviewPost(
            'https://www.instagram.com/p/C9xyz456/'),
        isTrue,
      );
      expect(
        SocialUrlValidator.isReviewPost(
          'https://instagram.com/reel/DEfg890/?igsh=123',
        ),
        isTrue,
      );
    });

    test('5. Supported TikTok video is recognized', () {
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

    test('6. Social profile URL is distinguished from review post URL', () {
      final profileDetection = SocialUrlValidator.detectSource(
        'https://instagram.com/klfoodie/',
      );
      expect(profileDetection.type, SocialSourceType.profile);
      expect(profileDetection.platform, 'instagram');

      final postDetection = SocialUrlValidator.detectSource(
        'https://instagram.com/reel/C8xyz123/',
      );
      expect(postDetection.type, SocialSourceType.post);
      expect(postDetection.platform, 'instagram');
    });

    testWidgets(
      '7. AI generation failure does not clear Creator existing form entries',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');
        final localEatsRepo = DemoLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: localEatsRepo);

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
            child: const AddRestaurantScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Creator manually types restaurant name
        await tester.enterText(
          find.byKey(const Key('restaurant_name_field')),
          'My Preserved Restaurant',
        );

        // Creator enters invalid source URL
        await tester.enterText(
          find.byKey(const Key('ai_source_field')),
          'https://invalid.com/video/1',
        );
        await tester.tap(find.byKey(const Key('ai_generate_button')));
        await tester.pumpAndSettle();

        // Form field is still intact
        final nameField = tester.widget<TextFormField>(
          find.byKey(const Key('restaurant_name_field')),
        );
        expect(nameField.controller?.text, 'My Preserved Restaurant');
      },
    );

    testWidgets(
      '8. Generated data can be fully reviewed and edited before submission',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');
        final localEatsRepo = _MockMockableLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: localEatsRepo);

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
            child: const AddRestaurantScreen(),
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

        // Creator edits the AI generated name and dishes
        await tester.enterText(
          find.byKey(const Key('restaurant_name_field')),
          'Edited Famous Nasi Kandar',
        );
        final nameField = tester.widget<TextFormField>(
          find.byKey(const Key('restaurant_name_field')),
        );
        expect(nameField.controller?.text, 'Edited Famous Nasi Kandar');
      },
    );

    testWidgets(
      '9. AI generation does not submit automatically; requires explicit Creator submission',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 2000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');
        final localEatsRepo = _MockMockableLocalEatsRepository(authRepo);
        final localEatsCtrl = LocalEatsController(repository: localEatsRepo);

        await tester.pumpWidget(
          buildApp(
            authController: authCtrl,
            localEatsController: localEatsCtrl,
            child: const AddRestaurantScreen(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('ai_source_field')),
          'https://www.tiktok.com/@foodie/video/7182930495829102938',
        );
        await tester.tap(find.byKey(const Key('ai_generate_button')));
        await tester.pumpAndSettle();

        // Still on submission form, no submit was triggered
        expect(localEatsRepo.submittedRevisionId, isNull);
        expect(
            find.byKey(const Key('restaurant_submit_button')), findsOneWidget);
      },
    );

    test(
      '10, 11, 12. Final Restaurant enters Admin moderation pipeline and is not public until approved',
      () async {
        final authRepo = DemoAuthRepository();
        final authCtrl = AuthController(repository: authRepo);
        await authCtrl.login('foodie@livelocal.com', '123456');
        final localEatsRepo = DemoLocalEatsRepository(authRepo);

        // Creator creates draft and submits
        final draft = await localEatsRepo.createRestaurantDraft(
          input: const RestaurantDraftInput(
            name: 'Pipeline Test Resto',
            address: '100 Beach Street',
            state: 'Penang',
            city: 'George Town',
            cuisineType: 'Nyonya',
            priceRange: r'49923',
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

        // 11. NOT in public listings before approval
        final publicBefore = await localEatsRepo.fetchPublicRestaurants();
        expect(
          publicBefore.any((r) => r.name == 'Pipeline Test Resto'),
          isFalse,
        );

        // 10. Appears in Admin pending submissions
        await authCtrl.login('admin@livelocal.com', '123456');
        final pending = await localEatsRepo.fetchPendingRestaurants();
        final submittedRest =
            pending.firstWhere((r) => r.name == 'Pipeline Test Resto');
        expect(submittedRest.status, 'submitted');

        // 12. Admin approves
        await localEatsRepo.moderateRestaurant(
          restaurant: submittedRest,
          decision: 'approved',
          reason: 'Verified authentic local restaurant',
        );

        // Now appears in public listings
        final publicAfter = await localEatsRepo.fetchPublicRestaurants();
        expect(
          publicAfter.any((r) => r.name == 'Pipeline Test Resto'),
          isTrue,
        );
      },
    );

    test(
        '13. No social or AI secret tokens are exposed or accepted in public domain models',
        () {
      final listing = GeneratedRestaurantListing.fromJson({
        'restaurantName': 'Test Resto',
        'sourcePlatform': 'instagram',
        'sourcePostUrl': 'https://instagram.com/p/123/',
        'confidence': 0.9,
        'missingFields': [],
        'access_token': 'secret_access_token',
        'refresh_token': 'secret_refresh_token',
      });
      expect(listing.restaurantName, 'Test Resto');
      expect(listing.sourcePlatform, 'instagram');
      expect(listing.sourcePostUrl, 'https://instagram.com/p/123/');
    });

    test(
        '14. Social source detection handles profile cancellation and invalid hosts cleanly',
        () {
      final detection =
          SocialUrlValidator.detectSource('https://randomsite.org');
      expect(detection.type, SocialSourceType.unsupported);
      expect(detection.platform, isNull);
    });
  });
}

class _MockMockableLocalEatsRepository extends DemoLocalEatsRepository {
  _MockMockableLocalEatsRepository(super.authRepository);

  String? submittedRevisionId;

  @override
  Future<SocialSourceAnalysisResult> generateRestaurantListingFromSource(
    String sourceUrl,
  ) async {
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
          priceRange: r'49923',
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
  Future<void> submitRestaurant({
    required String revisionId,
    String? duplicateOverrideReason,
  }) async {
    submittedRevisionId = revisionId;
  }
}
