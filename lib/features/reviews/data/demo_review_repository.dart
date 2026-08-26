import '../../../core/errors/app_exception.dart';
import '../../../models/review_model.dart';
import '../../../services/seed_data_service.dart';
import '../../auth/data/demo_auth_repository.dart';
import '../../auth/domain/account_identity.dart';
import '../domain/review_repository.dart';

class DemoReviewRepository
    implements ReviewRepository, ReviewReactionRepository {
  DemoReviewRepository(this._authRepository)
      : _reviews = List<ReviewModel>.of(SeedDataService.getInitialReviews());

  final DemoAuthRepository _authRepository;
  final List<ReviewModel> _reviews;
  final Set<String> _hiddenReviewIds = {};
  final Set<String> _reportedReviewIds = {};
  final Map<String, int> _votes = {};

  @override
  Future<List<ReviewModel>> fetchReviews({
    String? spotId,
    String? restaurantId,
  }) async {
    final currentUserId = _authRepository.currentAccountForDemo?.id;
    return _reviews
        .where(
          (review) =>
              !_hiddenReviewIds.contains(review.id) &&
              (spotId == null || review.spotId == spotId) &&
              (restaurantId == null || review.restaurantId == restaurantId),
        )
        .map(
          (review) => _copy(
            review,
            isOwnedByCurrentUser: review.userId == currentUserId,
          ),
        )
        .toList();
  }

  @override
  Future<ReviewReactionResult> setReaction(String reviewId, int? vote) async {
    final account = _requireAccount();
    final review = _reviews.where((item) => item.id == reviewId);
    if (review.isEmpty) {
      throw const AppException(
        code: AppErrorCode.notFound,
        userMessage: 'The review is no longer available.',
      );
    }
    final key = '${account.id}:$reviewId';
    if (vote == null) {
      _votes.remove(key);
    } else {
      _votes[key] = vote;
    }
    final likes = _votes.entries
        .where((entry) => entry.key.endsWith(':$reviewId') && entry.value == 1)
        .length;
    final dislikes = _votes.entries
        .where((entry) => entry.key.endsWith(':$reviewId') && entry.value == -1)
        .length;
    return ReviewReactionResult(
      likesCount: likes,
      dislikesCount: dislikes,
      userVote: vote,
    );
  }

  @override
  Future<ReviewModel> upsertReview({
    String? reviewId,
    String? spotId,
    String? restaurantId,
    required int rating,
    required String comment,
    int? expectedVersion,
    bool isAnonymous = false,
    List<ReviewPhotoInput> photos = const [],
  }) async {
    if (photos.length > 3) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Add no more than 3 review photos.',
      );
    }
    final account = _requireAccount();
    final savedPhotos = photos.indexed
        .map(
          (entry) => ReviewPhotoModel(
            path: entry.$2.existingPath ??
                'demo/${reviewId ?? 'review'}/photo-${entry.$1}',
            url: '',
            sortOrder: entry.$1,
            bytes: entry.$2.bytes,
          ),
        )
        .toList(growable: false);
    final index = _reviews.indexWhere(
      (review) =>
          review.userId == account.id &&
          review.spotId == spotId &&
          review.restaurantId == restaurantId,
    );
    if (index >= 0) {
      final existing = _reviews[index];
      if (expectedVersion != existing.version) {
        throw const AppException(
          code: AppErrorCode.conflict,
          userMessage: 'Your review changed. Refresh and try again.',
        );
      }
      final updated = _copy(
        existing,
        userName: isAnonymous ? 'Anonymous' : account.fullName,
        rating: rating.toDouble(),
        comment: comment.trim(),
        version: existing.version + 1,
        isAnonymous: isAnonymous,
        updatedAt: DateTime.now(),
        isOwnedByCurrentUser: true,
        photos: savedPhotos,
      );
      _reviews[index] = updated;
      return updated;
    }
    final created = ReviewModel(
      id: reviewId ?? 'demo-review-${DateTime.now().microsecondsSinceEpoch}',
      spotId: spotId,
      restaurantId: restaurantId,
      userId: account.id,
      userName: isAnonymous ? 'Anonymous' : account.fullName,
      rating: rating.toDouble(),
      comment: comment.trim(),
      createdAt: DateTime.now(),
      isAnonymous: isAnonymous,
      isOwnedByCurrentUser: true,
      photos: savedPhotos,
    );
    _reviews.add(created);
    return created;
  }

  @override
  Future<void> deleteReview({
    required String reviewId,
    required int expectedVersion,
  }) async {
    final account = _requireAccount();
    final index = _reviews.indexWhere(
      (review) => review.id == reviewId && review.userId == account.id,
    );
    if (index < 0) {
      throw const AppException(
        code: AppErrorCode.notFound,
        userMessage: 'The review is no longer available.',
      );
    }
    if (_reviews[index].version != expectedVersion) {
      throw const AppException(
        code: AppErrorCode.conflict,
        userMessage: 'Your review changed. Refresh and try again.',
      );
    }
    _reviews.removeAt(index);
  }

  @override
  Future<ModerationCaseReceipt> reportReview({
    required String reviewId,
    required String reason,
    String? explanation,
    required bool hideForReporter,
  }) async {
    final account = _requireAccount();
    final target = _reviews.where((review) => review.id == reviewId);
    if (target.isEmpty) {
      throw const AppException(
        code: AppErrorCode.notFound,
        userMessage: 'The review is no longer available.',
      );
    }
    if (target.single.userId == account.id) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'You cannot report your own review.',
      );
    }
    if (!_reportedReviewIds.add(reviewId)) {
      throw const AppException(
        code: AppErrorCode.conflict,
        userMessage: 'You already have an active report for this review.',
      );
    }
    if (hideForReporter) _hiddenReviewIds.add(reviewId);
    return ModerationCaseReceipt(
      id: 'demo-case-${DateTime.now().microsecondsSinceEpoch}',
      status: 'pending',
      version: 1,
    );
  }

  AccountIdentity _requireAccount() {
    final account = _authRepository.currentAccountForDemo;
    if (account == null || account.accessStatus != AccountAccessStatus.active) {
      throw const AppException(
        code: AppErrorCode.authentication,
        userMessage: 'Sign in with an active account to continue.',
      );
    }
    return account;
  }

  ReviewModel _copy(
    ReviewModel review, {
    String? userName,
    double? rating,
    String? comment,
    int? version,
    bool? isAnonymous,
    DateTime? updatedAt,
    bool? isOwnedByCurrentUser,
    List<ReviewPhotoModel>? photos,
  }) {
    return ReviewModel(
      id: review.id,
      spotId: review.spotId,
      restaurantId: review.restaurantId,
      userId: review.userId,
      userName: userName ?? review.userName,
      rating: rating ?? review.rating,
      comment: comment ?? review.comment,
      createdAt: review.createdAt,
      updatedAt: updatedAt ?? review.updatedAt,
      version: version ?? review.version,
      isAnonymous: isAnonymous ?? review.isAnonymous,
      isOwnedByCurrentUser: isOwnedByCurrentUser ?? review.isOwnedByCurrentUser,
      photos: photos ?? review.photos,
      likesCount: review.likesCount,
      dislikesCount: review.dislikesCount,
      userVote:
          _votes['${_authRepository.currentAccountForDemo?.id}:${review.id}'],
    );
  }
}
