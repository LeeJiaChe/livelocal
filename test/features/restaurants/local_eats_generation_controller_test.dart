import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/core/errors/app_exception.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/restaurants/domain/generated_restaurant_listing.dart';
import 'package:live_local/features/restaurants/presentation/local_eats_controller.dart';
import 'package:live_local/services/seed_data_service.dart';

void main() {
  late DemoAuthRepository auth;

  setUp(() async {
    auth = DemoAuthRepository();
    await auth.signIn(
      email: 'foodie@livelocal.com',
      password: SeedDataService.demoPassword,
    );
  });

  test('exposes generation loading, success and candidate selection', () async {
    final completion = Completer<SocialSourceAnalysisResult>();
    final repository = _GenerationRepository(auth, completion.future);
    final controller = LocalEatsController(repository: repository);

    final future = controller.generateRestaurantListingFromSource(
      'https://instagram.com/reel/123/',
    );
    expect(controller.isGeneratingListing, isTrue);
    completion.complete(_candidatesResult);
    expect(await future, isTrue);
    expect(controller.isGeneratingListing, isFalse);
    expect(controller.generatedCandidates, hasLength(2));
    expect(controller.selectedGeneratedCandidate, isNull);

    controller.selectGeneratedCandidate(controller.generatedCandidates.last);
    expect(controller.selectedGeneratedCandidate?.restaurantName, 'Cafe Two');
    controller.clearGeneratedResult();
    expect(controller.generatedCandidates, isEmpty);
  });

  test('keeps generation errors separate and user friendly', () async {
    final completion = Completer<SocialSourceAnalysisResult>();
    final repository = _GenerationRepository(auth, completion.future);
    final controller = LocalEatsController(repository: repository);

    final future = controller.generateRestaurantListingFromSource(
      'https://instagram.com/reel/123/',
    );
    completion.completeError(
      const AppException(
        code: AppErrorCode.unavailable,
        userMessage:
            'Paste a valid TikTok review video or Instagram post/Reel link.',
      ),
    );
    expect(
      await future,
      isFalse,
    );
    expect(controller.isGeneratingListing, isFalse);
    expect(controller.generationError, contains('Paste a valid TikTok'));
    expect(controller.errorMessage, isNull);
  });

  test('clear ignores a stale in-flight generation result', () async {
    final completion = Completer<SocialSourceAnalysisResult>();
    final repository = _GenerationRepository(auth, completion.future);
    final controller = LocalEatsController(repository: repository);

    final future = controller.generateRestaurantListingFromSource(
      'https://instagram.com/reel/123/',
    );
    controller.clearGeneratedResult();
    completion.complete(_candidatesResult);

    expect(await future, isFalse);
    expect(controller.isGeneratingListing, isFalse);
    expect(controller.generatedCandidates, isEmpty);
    expect(controller.generationError, isNull);
  });
}

class _GenerationRepository extends DemoLocalEatsRepository {
  _GenerationRepository(super.authRepository, this.result);

  final Future<SocialSourceAnalysisResult> result;

  @override
  Future<SocialSourceAnalysisResult> generateRestaurantListingFromSource(
    String sourceUrl, {
    String? restaurantName,
  }) =>
      result;
}

const _candidatesResult = SocialSourceAnalysisResult(
  sourceType: 'post',
  platform: 'instagram',
  candidates: [
    GeneratedRestaurantListing(
      restaurantName: 'Cafe One',
      sourcePlatform: 'instagram',
      sourcePostUrl: 'https://instagram.com/reel/ONE/',
      confidence: 0.8,
      missingFields: ['address'],
    ),
    GeneratedRestaurantListing(
      restaurantName: 'Cafe Two',
      sourcePlatform: 'instagram',
      sourcePostUrl: 'https://instagram.com/p/TWO/',
      confidence: 0.7,
      missingFields: ['priceRange'],
    ),
  ],
);
