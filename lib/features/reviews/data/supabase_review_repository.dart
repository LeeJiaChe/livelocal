import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/supabase_error_mapper.dart';
import '../../../models/review_model.dart';
import '../domain/review_repository.dart';

class SupabaseReviewRepository
    implements ReviewRepository, ReviewReactionRepository {
  SupabaseReviewRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ReviewModel>> fetchReviews({
    String? spotId,
    String? restaurantId,
  }) async {
    try {
      var publicRequest = _client.from('public_reviews').select();
      if (spotId != null) {
        publicRequest =
            publicRequest.eq('target_type', 'spot').eq('target_id', spotId);
      } else if (restaurantId != null) {
        publicRequest = publicRequest
            .eq('target_type', 'restaurant')
            .eq('target_id', restaurantId);
      }
      final publicRows =
          await publicRequest.order('updated_at', ascending: false).limit(100);
      final ownRows = _client.auth.currentUser == null
          ? const <dynamic>[]
          : await _client.from('reviews').select().eq('status', 'published');
      final ownById = <String, Map<String, dynamic>>{
        for (final raw in ownRows)
          (raw as Map)['id'] as String: Map<String, dynamic>.from(raw),
      };
      final voteRows = _client.auth.currentUser == null
          ? const <dynamic>[]
          : await _client.from('review_votes').select('review_id, vote');
      final votesByReview = <String, int>{
        for (final raw in voteRows)
          (raw as Map)['review_id'] as String: (raw['vote'] as num).toInt(),
      };
      final publicList = publicRows as List<dynamic>;
      final reviewIds = publicList
          .map((raw) => (raw as Map)['id'] as String)
          .toList(growable: false);
      final photoRows = reviewIds.isEmpty
          ? const <dynamic>[]
          : await _client
              .from('review_photos')
              .select('review_id, storage_path, sort_order')
              .inFilter('review_id', reviewIds)
              .order('sort_order');
      final photosByReview = <String, List<ReviewPhotoModel>>{};
      for (final raw in photoRows) {
        final photo = Map<String, dynamic>.from(raw as Map);
        final reviewId = photo['review_id'] as String;
        final path = photo['storage_path'] as String;
        final url = await _signedPhoto(path);
        photosByReview.putIfAbsent(reviewId, () => []).add(
              ReviewPhotoModel(
                path: path,
                url: url,
                sortOrder: (photo['sort_order'] as num).toInt(),
              ),
            );
      }
      return publicList.map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final own = ownById[row['id']];
        final isSpot = row['target_type'] == 'spot';
        return ReviewModel(
          id: row['id'] as String,
          spotId: isSpot ? row['target_id'] as String : null,
          restaurantId: isSpot ? null : row['target_id'] as String,
          userId: own?['user_id'] as String? ?? '',
          userName: row['author_display_name'] as String,
          rating: (row['rating'] as num).toDouble(),
          comment: row['body'] as String,
          createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
          updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
          version: (row['version'] as num).toInt(),
          isOwnedByCurrentUser: own != null,
          likesCount: (row['likes_count'] as num?)?.toInt() ?? 0,
          dislikesCount: (row['dislikes_count'] as num?)?.toInt() ?? 0,
          userVote: votesByReview[row['id']],
          photos: photosByReview[row['id']] ?? const [],
        );
      }).toList();
    } on PostgrestException catch (error) {
      throw SupabaseErrorMapper.parseError(
        error,
        'Reviews could not be loaded.',
      );
    }
  }

  @override
  Future<ReviewReactionResult> setReaction(String reviewId, int? vote) async {
    try {
      final response = await _client.rpc('set_review_vote', params: {
        'p_review_id': reviewId,
        'p_vote': vote ?? 0,
      });
      final row = Map<String, dynamic>.from(response as Map);
      return ReviewReactionResult(
        likesCount: (row['likes_count'] as num).toInt(),
        dislikesCount: (row['dislikes_count'] as num).toInt(),
        userVote: (row['user_vote'] as num?)?.toInt(),
      );
    } on PostgrestException catch (error) {
      throw SupabaseErrorMapper.parseError(
          error, 'Your reaction could not be saved.');
    }
  }

  @override
  Future<ReviewModel> upsertReview({
    String? reviewId,
    String? spotId,
    String? restaurantId,
    required int rating,
    required String comment,
    int? expectedVersion,
    List<ReviewPhotoInput> photos = const [],
  }) async {
    final targetId = spotId ?? restaurantId;
    if (targetId == null || (spotId == null) == (restaurantId == null)) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Choose one place to review.',
      );
    }
    if (photos.length > 3) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Add no more than 3 review photos.',
      );
    }
    final selectedReviewId = reviewId ?? const Uuid().v4();
    final uploadedPaths = <String>[];
    try {
      final photoPaths = <String>[];
      for (final photo in photos) {
        if (photo.existingPath case final path?) {
          photoPaths.add(path);
          continue;
        }
        final bytes = photo.bytes;
        final mimeType = photo.mimeType;
        if (bytes == null || mimeType == null) {
          throw const AppException(
            code: AppErrorCode.validation,
            userMessage: 'Choose valid review photos and try again.',
          );
        }
        final path = await _uploadPhoto(
          reviewId: selectedReviewId,
          bytes: bytes,
          mimeType: mimeType,
        );
        uploadedPaths.add(path);
        photoPaths.add(path);
      }
      final response = await _client.rpc('upsert_review_with_photos', params: {
        'p_target_type': spotId != null ? 'spot' : 'restaurant',
        'p_target_id': targetId,
        'p_rating': rating,
        'p_body': comment,
        'p_expected_version': expectedVersion,
        'p_photo_paths': photoPaths,
        'p_new_review_id': selectedReviewId,
      });
      final row = Map<String, dynamic>.from(response as Map);
      return ReviewModel(
        id: row['id'] as String,
        spotId: spotId,
        restaurantId: restaurantId,
        userId: '',
        userName: row['author_display_name'] as String,
        rating: (row['rating'] as num).toDouble(),
        comment: row['body'] as String,
        createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
        version: (row['version'] as num).toInt(),
        isOwnedByCurrentUser: true,
        photos: await _photosFromPaths(photoPaths),
      );
    } on AppException {
      await _removeFailedUploads(uploadedPaths);
      rethrow;
    } on StorageException catch (_) {
      await _removeFailedUploads(uploadedPaths);
      throw const AppException(
        code: AppErrorCode.network,
        userMessage: 'Review photos could not be uploaded. Try again.',
      );
    } on PostgrestException catch (error) {
      await _removeFailedUploads(uploadedPaths);
      throw SupabaseErrorMapper.parseError(
        error,
        error.code == '40001'
            ? 'Your review changed. Refresh and try again.'
            : 'Your review could not be saved.',
      );
    }
  }

  Future<String> _uploadPhoto({
    required String reviewId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (bytes.isEmpty || bytes.length > 6 * 1024 * 1024) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Each review photo must be smaller than 6 MB.',
      );
    }
    final extension = switch (mimeType.toLowerCase()) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => null,
    };
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException(
        code: AppErrorCode.authentication,
        userMessage: 'Sign in to add review photos.',
      );
    }
    if (extension == null) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Use JPG, PNG, or WebP review photos.',
      );
    }
    final path = '$userId/$reviewId/${const Uuid().v4()}.$extension';
    await _client.storage.from('review-images').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: false),
        );
    return path;
  }

  Future<List<ReviewPhotoModel>> _photosFromPaths(List<String> paths) async {
    final photos = <ReviewPhotoModel>[];
    for (var index = 0; index < paths.length; index += 1) {
      photos.add(
        ReviewPhotoModel(
          path: paths[index],
          url: await _signedPhoto(paths[index]),
          sortOrder: index,
        ),
      );
    }
    return photos;
  }

  Future<String> _signedPhoto(String path) async {
    try {
      return await _client.storage
          .from('review-images')
          .createSignedUrl(path, 3600);
    } catch (_) {
      return '';
    }
  }

  Future<void> _removeFailedUploads(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from('review-images').remove(paths);
    } catch (_) {
      // The database cleanup lifecycle handles referenced objects. This path
      // is best-effort only for uploads that never reached the review RPC.
    }
  }

  @override
  Future<void> deleteReview({
    required String reviewId,
    required int expectedVersion,
  }) async {
    try {
      await _client.rpc('delete_my_review', params: {
        'p_review_id': reviewId,
        'p_expected_version': expectedVersion,
      });
    } on PostgrestException catch (error) {
      throw SupabaseErrorMapper.parseError(
        error,
        'The review could not be deleted.',
      );
    }
  }

  @override
  Future<ModerationCaseReceipt> reportReview({
    required String reviewId,
    required String reason,
    String? explanation,
    required bool hideForReporter,
  }) async {
    try {
      final response = await _client.rpc('report_content', params: {
        'p_target_type': 'review',
        'p_target_id': reviewId,
        'p_reason': reason,
        'p_explanation': explanation,
        'p_hide_for_me': hideForReporter,
      });
      final row = Map<String, dynamic>.from(response as Map);
      return ModerationCaseReceipt(
        id: row['id'] as String,
        status: row['status'] as String,
        version: (row['version'] as num).toInt(),
      );
    } on PostgrestException catch (error) {
      throw SupabaseErrorMapper.parseError(
        error,
        error.code == '23505'
            ? 'You already have an active report for this review.'
            : 'The report could not be submitted.',
      );
    }
  }
}
