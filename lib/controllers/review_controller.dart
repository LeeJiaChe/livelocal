// Temporary compatibility export for screens not yet moved into feature folders.
export '../features/reviews/presentation/review_controller.dart';
import 'package:flutter/material.dart';
import '../features/reviews/domain/review.dart';
import '../features/reviews/domain/review_repository.dart';

class ReviewController extends ChangeNotifier {
  final ReviewRepository repository;
  ReviewController({required this.repository});

  List<Review> _reviews = [];
  List<Review> get reviews => _reviews;

  Future<void> toggleLike(Review review) async {
    // If already liked, remove vote (null). Otherwise, set to 1.
    final int? newVote = review.userVote == 1 ? null : 1;
    await _handleVote(review, newVote);
  }

  Future<void> toggleDislike(Review review) async {
    // If already disliked, remove vote (null). Otherwise, set to -1.
    final int? newVote = review.userVote == -1 ? null : -1;
    await _handleVote(review, newVote);
  }

  Future<void> _handleVote(Review review, int? vote) async {
    try {
      await repository.voteReview(reviewId: review.id, vote: vote);

      // Optional: Optimistic UI update (update local list immediately)
      // Or just re-fetch the reviews:
      // fetchReviews(review.spotId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error voting: $e');
    }
  }
}