class SavedCollectionModel {
  const SavedCollectionModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.itemCount = 0,
    this.spotCount = 0,
    this.restaurantCount = 0,
    this.coverTargetType,
    this.coverImageUrl,
    this.coverImagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final int itemCount;
  final int spotCount;
  final int restaurantCount;
  final String? coverTargetType;
  final String? coverImageUrl;
  final String? coverImagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SavedCollectionModel.fromMap(Map<String, dynamic> map) {
    return SavedCollectionModel(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      itemCount: (map['item_count'] as num?)?.toInt() ?? 0,
      spotCount: (map['spot_count'] as num?)?.toInt() ?? 0,
      restaurantCount: (map['restaurant_count'] as num?)?.toInt() ?? 0,
      coverTargetType: map['cover_target_type'] as String?,
      coverImageUrl: map['cover_image_url'] as String?,
      coverImagePath: map['cover_image_path'] as String? ??
          map['cover_image_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'description': description,
        'item_count': itemCount,
        'spot_count': spotCount,
        'restaurant_count': restaurantCount,
        'cover_target_type': coverTargetType,
        'cover_image_url': coverImageUrl,
        'cover_image_path': coverImagePath,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  SavedCollectionModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    int? itemCount,
    int? spotCount,
    int? restaurantCount,
    String? coverTargetType,
    String? coverImageUrl,
    String? coverImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedCollectionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      itemCount: itemCount ?? this.itemCount,
      spotCount: spotCount ?? this.spotCount,
      restaurantCount: restaurantCount ?? this.restaurantCount,
      coverTargetType: coverTargetType ?? this.coverTargetType,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SavedCollectionItemModel {
  const SavedCollectionItemModel({
    required this.id,
    required this.collectionId,
    required this.savedPlaceId,
    required this.addedAt,
    this.spotId,
    this.restaurantId,
  });

  final String id;
  final String collectionId;
  final String savedPlaceId;
  final DateTime addedAt;
  final String? spotId;
  final String? restaurantId;

  factory SavedCollectionItemModel.fromMap(Map<String, dynamic> map) {
    return SavedCollectionItemModel(
      id: map['id'] as String? ?? '',
      collectionId: map['collection_id'] as String? ?? '',
      savedPlaceId: map['saved_place_id'] as String? ?? '',
      addedAt: map['added_at'] != null
          ? DateTime.parse(map['added_at'] as String)
          : DateTime.now(),
      spotId: map['spot_id'] as String?,
      restaurantId: map['restaurant_id'] as String?,
    );
  }
}

/// Resolved metadata for a place saved within a collection, independent of discovery pagination caches.
class SavedCollectionPlace {
  const SavedCollectionPlace({
    required this.savedPlaceId,
    required this.targetType,
    required this.targetId,
    required this.name,
    required this.state,
    required this.city,
    required this.categoryOrCuisine,
    this.priceRange,
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.addedAt,
  });

  final String savedPlaceId;
  final String targetType; // 'spot' | 'restaurant'
  final String targetId;
  final String name;
  final String state;
  final String city;
  final String categoryOrCuisine;
  final String? priceRange;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final DateTime addedAt;

  bool get isSpot => targetType == 'spot';
  bool get isRestaurant => targetType == 'restaurant';

  factory SavedCollectionPlace.fromMap(Map<String, dynamic> map) {
    return SavedCollectionPlace(
      savedPlaceId: map['saved_place_id'] as String? ?? '',
      targetType: map['target_type'] as String? ?? 'spot',
      targetId: map['target_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unavailable place',
      state: map['state'] as String? ?? '',
      city: map['city'] as String? ?? '',
      categoryOrCuisine: map['category_or_cuisine'] as String? ?? '',
      priceRange: map['price_range'] as String?,
      imageUrl: map['image_url'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      addedAt: map['added_at'] != null
          ? DateTime.parse(map['added_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'saved_place_id': savedPlaceId,
        'target_type': targetType,
        'target_id': targetId,
        'name': name,
        'state': state,
        'city': city,
        'category_or_cuisine': categoryOrCuisine,
        'price_range': priceRange,
        'image_url': imageUrl,
        'rating': rating,
        'review_count': reviewCount,
        'added_at': addedAt.toIso8601String(),
      };
}
