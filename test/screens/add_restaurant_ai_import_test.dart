import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/auth/presentation/auth_controller.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/restaurants/domain/generated_restaurant_listing.dart';
import 'package:live_local/features/restaurants/domain/local_eats_repository.dart';
import 'package:live_local/features/restaurants/presentation/local_eats_controller.dart';
import 'package:live_local/models/restaurant_model.dart';
import 'package:live_local/screens/add_restaurant_screen.dart';
import 'package:live_local/services/seed_data_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('generated values populate and remain editable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authRepository = DemoAuthRepository();
    final authController = AuthController(repository: authRepository);
    await authController.login(
      'foodie@livelocal.com',
      SeedDataService.demoPassword,
    );
    final localEats = LocalEatsController(
      repository: _WidgetGenerationRepository(authRepository),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: authController),
          ChangeNotifierProvider<LocalEatsController>.value(value: localEats),
        ],
        child: const MaterialApp(home: AddRestaurantScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('ai_source_field')),
      'https://instagram.com/reel/ABC/',
    );
    await tester.tap(find.byKey(const Key('ai_generate_button')));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('restaurant_name_field')),
    );
    expect(nameField.controller?.text, 'Village Park Restaurant');
    expect(find.byKey(const Key('ai_draft_notice')), findsOneWidget);
    expect(find.byKey(const Key('ai_missing_fields')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('restaurant_name_field')),
      'Corrected Restaurant Name',
    );
    expect(nameField.controller?.text, 'Corrected Restaurant Name');

    final socialFieldFinder = find.byKey(const Key('social_review_url_field'));
    await tester.ensureVisible(socialFieldFinder);
    final socialField = tester.widget<TextFormField>(socialFieldFinder);
    expect(socialField.controller?.text, 'https://instagram.com/reel/ABC/');
  });

  testWidgets('Google Maps link populates an editable AI-assisted draft',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final authRepository = DemoAuthRepository();
    final authController = AuthController(repository: authRepository);
    await authController.login(
      'foodie@livelocal.com',
      SeedDataService.demoPassword,
    );
    final localEats = LocalEatsController(
      repository: _WidgetGenerationRepository(authRepository),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: authController),
          ChangeNotifierProvider<LocalEatsController>.value(value: localEats),
        ],
        child: const MaterialApp(home: AddRestaurantScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('ai_source_field')),
      'https://maps.app.goo.gl/AbCdEf123456',
    );
    await tester.tap(find.byKey(const Key('ai_generate_button')));
    await tester.pumpAndSettle();

    final name = tester.widget<TextFormField>(
      find.byKey(const Key('restaurant_name_field')),
    );
    expect(name.controller?.text, 'Line Clear Nasi Kandar');
    await tester.enterText(
      find.byKey(const Key('restaurant_name_field')),
      'Line Clear Nasi Kandar (verified)',
    );
    expect(name.controller?.text, 'Line Clear Nasi Kandar (verified)');
    expect(find.byKey(const Key('ai_draft_notice')), findsOneWidget);
  });

  testWidgets(
    'manual revision submission still uses the existing workflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final authRepository = DemoAuthRepository();
      final authController = AuthController(repository: authRepository);
      await authController.login(
        'foodie@livelocal.com',
        SeedDataService.demoPassword,
      );
      final repository = _WidgetGenerationRepository(authRepository);
      final localEats = LocalEatsController(repository: repository);
      final source = RestaurantModel(
        id: 'restaurant-1',
        revisionId: 'revision-1',
        name: 'Manual Restaurant',
        address: '12 Test Street',
        state: 'Selangor',
        city: 'Petaling Jaya',
        cuisineType: 'Malay',
        priceRange: r'$$',
        reviewedDishes: 'Nasi lemak',
        influencerId: 'creator-1',
        influencerName: 'Creator',
        socialMediaUrl: 'https://instagram.com/reel/MANUAL/',
        coverPhotoUrl: 'https://example.test/photo.jpg',
        isOwnedByCurrentUser: true,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(
              value: authController,
            ),
            ChangeNotifierProvider<LocalEatsController>.value(
              value: localEats,
            ),
          ],
          child: MaterialApp(home: AddRestaurantScreen(source: source)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(
        find.byKey(const Key('restaurant_name_field')),
        'Manually Corrected Restaurant',
      );
      await tester.tap(find.byKey(const Key('restaurant_submit_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(repository.savedRevision?.name, 'Manually Corrected Restaurant');
      expect(
        repository.savedRevision?.socialMediaUrl,
        'https://instagram.com/reel/MANUAL/',
      );
      expect(repository.submittedRevisionId, 'revision-2');
    },
  );

  testWidgets(
    'candidate selection from multiple options updates form fields and stores review post URL',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final authRepository = DemoAuthRepository();
      final authController = AuthController(repository: authRepository);
      await authController.login(
        'foodie@livelocal.com',
        SeedDataService.demoPassword,
      );
      final localEats = LocalEatsController(
        repository: _WidgetGenerationRepository(authRepository),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(
              value: authController,
            ),
            ChangeNotifierProvider<LocalEatsController>.value(
              value: localEats,
            ),
          ],
          child: const MaterialApp(home: AddRestaurantScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('ai_source_field')),
        'https://instagram.com/reel/MULTI_REVIEW/',
      );
      await tester.tap(find.byKey(const Key('ai_generate_button')));
      await tester.pumpAndSettle();

      const selectedPost = 'https://instagram.com/p/REVIEW_TWO/';
      final candidate = find.byKey(
        const ValueKey('generated-candidate-$selectedPost'),
      );
      await tester.ensureVisible(candidate);
      await tester.tap(candidate);
      await tester.pumpAndSettle();

      final socialFieldFinder =
          find.byKey(const Key('social_review_url_field'));
      await tester.ensureVisible(socialFieldFinder);
      final socialField = tester.widget<TextFormField>(socialFieldFinder);
      expect(socialField.controller?.text, selectedPost);
      final nameField = tester.widget<TextFormField>(
        find.byKey(const Key('restaurant_name_field')),
      );
      expect(nameField.controller?.text, 'Cafe Two');
    },
  );
}

class _WidgetGenerationRepository extends DemoLocalEatsRepository {
  _WidgetGenerationRepository(super.authRepository);

  RestaurantDraftInput? savedRevision;
  String? submittedRevisionId;

  @override
  Future<SocialSourceAnalysisResult> generateRestaurantListingFromSource(
    String sourceUrl,
  ) async {
    if (sourceUrl.contains('maps.app.goo.gl')) {
      return SocialSourceAnalysisResult(
        sourceType: 'place',
        platform: 'google_maps',
        candidates: [
          GeneratedRestaurantListing(
            restaurantName: 'Line Clear Nasi Kandar',
            address: '177 Jalan Penang',
            state: 'Pulau Pinang',
            city: 'George Town',
            cuisineType: 'Indian Muslim',
            priceRange: r'$$',
            sourcePlatform: 'google_maps',
            sourcePostUrl: sourceUrl,
            confidence: 1,
            missingFields: const ['reviewedDishes'],
          ),
        ],
      );
    }
    if (sourceUrl.contains('MULTI_REVIEW')) {
      return const SocialSourceAnalysisResult(
        sourceType: 'post',
        platform: 'instagram',
        candidates: [
          GeneratedRestaurantListing(
            restaurantName: 'Cafe One',
            reviewedDishes: 'Laksa',
            sourcePlatform: 'instagram',
            sourcePostUrl: 'https://instagram.com/reel/REVIEW_ONE/',
            confidence: 0.8,
            missingFields: ['address'],
          ),
          GeneratedRestaurantListing(
            restaurantName: 'Cafe Two',
            reviewedDishes: 'Nasi lemak',
            sourcePlatform: 'instagram',
            sourcePostUrl: 'https://instagram.com/p/REVIEW_TWO/',
            confidence: 0.7,
            missingFields: ['priceRange'],
          ),
        ],
      );
    }
    return const SocialSourceAnalysisResult(
      sourceType: 'post',
      platform: 'instagram',
      candidates: [
        GeneratedRestaurantListing(
          restaurantName: 'Village Park Restaurant',
          state: 'Selangor',
          city: 'Petaling Jaya',
          cuisineType: 'Malay',
          reviewedDishes: 'Nasi Lemak Ayam Goreng',
          sourcePlatform: 'instagram',
          sourcePostUrl: 'https://instagram.com/reel/ABC/',
          influencerUsername: 'localfoodie',
          confidence: 0.9,
          missingFields: ['address', 'priceRange'],
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
    savedRevision = input;
    return const RestaurantDraftResult(
      restaurantId: 'restaurant-1',
      revisionId: 'revision-2',
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
