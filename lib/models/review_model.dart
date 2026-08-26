import 'dart:typed_data';

class ReviewPhotoModel {
  const ReviewPhotoModel({
    required this.path,
    required this.url,
    required this.sortOrder,
    this.bytes,
  });

  final String path;
  final String url;
  final int sortOrder;
  final Uint8List? bytes;
}

class ReviewModel {
  final String id;
  final String? spotId;
  final String? restaurantId;
  final String userId;
  final String userName;
  final double rating;
  final String comment;
  final List<ReviewPhotoModel> photos;
  final bool isFlagged;
  final String? flagReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int version;
  final bool isOwnedByCurrentUser;
  final int likesCount;
  final int dislikesCount;
  final int? userVote;

  ReviewModel({
    required this.id,
    this.spotId,
    this.restaurantId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.photos = const [],
    this.isFlagged = false,
    this.flagReason,
    required this.createdAt,
    this.updatedAt,
    this.version = 1,
    this.isOwnedByCurrentUser = false,
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.userVote,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'spot_id': spotId,
        'restaurant_id': restaurantId,
        'user_id': userId,
        'user_name': userName,
        'rating': rating,
        'comment': comment,
        'photo_paths': photos.map((photo) => photo.path).toList(),
        'is_flagged': isFlagged,
        'flag_reason': flagReason,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'version': version,
        'likes_count': likesCount,
        'dislikes_count': dislikesCount,
        'user_vote': userVote,
      };

  factory ReviewModel.fromMap(Map<String, dynamic> map) => ReviewModel(
        id: map['id'] ?? '',
        spotId: map['spot_id'],
        restaurantId: map['restaurant_id'],
        userId: map['user_id'] ?? '',
        userName: map['user_name'] ?? 'Anonymous',
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        comment: map['comment'] ?? '',
        photos: (map['photos'] as List<dynamic>? ?? const [])
            .map(
              (raw) => ReviewPhotoModel(
                path: (raw as Map)['path'] as String,
                url: raw['url'] as String? ?? '',
                sortOrder: (raw['sort_order'] as num?)?.toInt() ?? 0,
              ),
            )
            .toList(growable: false),
        isFlagged: map['is_flagged'] ?? false,
        flagReason: map['flag_reason'],
        createdAt: DateTime.parse(
            map['created_at'] ?? DateTime.now().toIso8601String()),
        updatedAt: map['updated_at'] == null
            ? null
            : DateTime.parse(map['updated_at'] as String),
        version: (map['version'] as num?)?.toInt() ?? 1,
        isOwnedByCurrentUser: map['is_owned_by_current_user'] ?? false,
        likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
        dislikesCount: (map['dislikes_count'] as num?)?.toInt() ?? 0,
        userVote: (map['user_vote'] as num?)?.toInt(),
      );

  ReviewModel copyWithReaction({
    required int likesCount,
    required int dislikesCount,
    required int? userVote,
  }) =>
      ReviewModel(
        id: id,
        spotId: spotId,
        restaurantId: restaurantId,
        userId: userId,
        userName: userName,
        rating: rating,
        comment: comment,
        photos: photos,
        isFlagged: isFlagged,
        flagReason: flagReason,
        createdAt: createdAt,
        updatedAt: updatedAt,
        version: version,
        isOwnedByCurrentUser: isOwnedByCurrentUser,
        likesCount: likesCount,
        dislikesCount: dislikesCount,
        userVote: userVote,
      );
}
