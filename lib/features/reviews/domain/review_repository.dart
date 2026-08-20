import '../../../models/review_model.dart';

class ModerationCaseReceipt {
  const ModerationCaseReceipt({
    required this.id,
    required this.status,
    required this.version,
  });

  final String id;
  final String status;
  final int version;
}

class ReviewReactionResult {
  const ReviewReactionResult({
    required this.likesCount,
    required this.dislikesCount,
    required this.userVote,
  });
  final int likesCount;
  final int dislikesCount;
  final int? userVote;
}

abstract interface class ReviewReactionRepository {
  Future<ReviewReactionResult> setReaction(String reviewId, int? vote);
}

abstract interface class ReviewRepository {
  Future<List<ReviewModel>> fetchReviews({
    String? spotId,
    String? restaurantId,
  });

  Future<ReviewModel> upsertReview({
    String? spotId,
    String? restaurantId,
    required int rating,
    required String comment,
    int? expectedVersion,
  });

  Future<void> deleteReview({
    required String reviewId,
    required int expectedVersion,
  });

  Future<ModerationCaseReceipt> reportReview({
    required String reviewId,
    required String reason,
    String? explanation,
    required bool hideForReporter,
  });
}
