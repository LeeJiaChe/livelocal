import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/reviews/data/demo_review_repository.dart';
import 'package:live_local/features/reviews/presentation/review_controller.dart';
import 'package:live_local/features/reviews/domain/review_repository.dart';
import 'package:live_local/services/seed_data_service.dart';

void main() {
  testWidgets('one review per target is edited with a version increment',
      (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    }));

    final authRepository = DemoAuthRepository();
    await authRepository.signIn(
      email: 'foodie@livelocal.com',
      password: SeedDataService.demoPassword,
    );
    final controller = ReviewController(
      repository: DemoReviewRepository(authRepository),
    );
    await controller.loadReviews();

    expect(
      await controller.addReview(
        ctx,
        spotId: 'spot-002',
        rating: 4,
        comment: 'A useful first review.',
      ),
      isTrue,
    );
    final first = controller
        .getReviewsForSpot('spot-002')
        .singleWhere((review) => review.isOwnedByCurrentUser);

    expect(
      await controller.addReview(
        ctx,
        spotId: 'spot-002',
        rating: 5,
        comment: 'Updated after another visit.',
      ),
      isTrue,
    );
    final updated = controller
        .getReviewsForSpot('spot-002')
        .singleWhere((review) => review.isOwnedByCurrentUser);
    expect(updated.id, first.id);
    expect(updated.version, first.version + 1);
    expect(updated.rating, 5);
  });

  test('report is pending, personally hidden, and cannot be duplicated',
      () async {
    final authRepository = DemoAuthRepository();
    await authRepository.signIn(
      email: 'foodie@livelocal.com',
      password: SeedDataService.demoPassword,
    );
    final controller = ReviewController(
      repository: DemoReviewRepository(authRepository),
    );
    await controller.loadReviews();
    final target = controller.reviews.first;

    expect(
      await controller.reportReview(
        reviewId: target.id,
        reason: 'spam',
      ),
      isTrue,
    );
    expect(controller.reviews.any((review) => review.id == target.id), isFalse);
    expect(
      await controller.reportReview(
        reviewId: target.id,
        reason: 'spam',
      ),
      isFalse,
    );
  });

  testWidgets('review photos can be added, retained, and removed on edit',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (value) {
      context = value;
      return const SizedBox();
    }));
    final authRepository = DemoAuthRepository();
    await authRepository.signIn(
      email: 'foodie@livelocal.com',
      password: SeedDataService.demoPassword,
    );
    final controller = ReviewController(
      repository: DemoReviewRepository(authRepository),
    );
    await controller.loadReviews();

    expect(
      await controller.addReview(
        context,
        spotId: 'spot-002',
        rating: 5,
        comment: 'The trail was clear and easy to follow.',
        photos: [
          ReviewPhotoInput.upload(
            bytes: Uint8List.fromList([1, 2, 3]),
            mimeType: 'image/jpeg',
          ),
          ReviewPhotoInput.upload(
            bytes: Uint8List.fromList([4, 5, 6]),
            mimeType: 'image/png',
          ),
        ],
      ),
      isTrue,
    );
    final created = controller
        .getReviewsForSpot('spot-002')
        .singleWhere((review) => review.isOwnedByCurrentUser);
    expect(created.photos, hasLength(2));

    expect(
      await controller.addReview(
        context,
        spotId: 'spot-002',
        rating: 4,
        comment: 'Still worth visiting, especially before noon.',
        photos: [ReviewPhotoInput.existing(created.photos.first.path)],
      ),
      isTrue,
    );
    final edited = controller
        .getReviewsForSpot('spot-002')
        .singleWhere((review) => review.isOwnedByCurrentUser);
    expect(edited.photos, hasLength(1));
    expect(edited.photos.single.path, created.photos.first.path);
  });

  testWidgets('anonymous review displays Anonymous and can toggle anonymity',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (value) {
      context = value;
      return const SizedBox();
    }));
    final authRepository = DemoAuthRepository();
    await authRepository.signIn(
      email: 'foodie@livelocal.com',
      password: SeedDataService.demoPassword,
    );
    final controller = ReviewController(
      repository: DemoReviewRepository(authRepository),
    );
    await controller.loadReviews();

    // 1. Post anonymously
    expect(
      await controller.addReview(
        context,
        spotId: 'spot-003',
        rating: 5,
        comment: 'Hidden gem, highly recommended anonymously!',
        isAnonymous: true,
      ),
      isTrue,
    );
    final createdAnon = controller
        .getReviewsForSpot('spot-003')
        .singleWhere((review) => review.isOwnedByCurrentUser);
    expect(createdAnon.isAnonymous, isTrue);
    expect(createdAnon.userName, 'Anonymous');

    // 2. Edit to named
    expect(
      await controller.addReview(
        context,
        spotId: 'spot-003',
        rating: 5,
        comment: 'Updated review now with my real name.',
        isAnonymous: false,
      ),
      isTrue,
    );
    final updatedNamed = controller
        .getReviewsForSpot('spot-003')
        .singleWhere((review) => review.isOwnedByCurrentUser);
    expect(updatedNamed.isAnonymous, isFalse);
    expect(updatedNamed.userName, isNot('Anonymous'));

    // 3. Edit back to anonymous
    expect(
      await controller.addReview(
        context,
        spotId: 'spot-003',
        rating: 4,
        comment: 'Switched back to anonymous.',
        isAnonymous: true,
      ),
      isTrue,
    );
    final revertedAnon = controller
        .getReviewsForSpot('spot-003')
        .singleWhere((review) => review.isOwnedByCurrentUser);
    expect(revertedAnon.isAnonymous, isTrue);
    expect(revertedAnon.userName, 'Anonymous');
  });
}
