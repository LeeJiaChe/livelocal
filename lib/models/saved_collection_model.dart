class CollectionCoverItem {
  const CollectionCoverItem({
    required this.targetType,
    required this.targetId,
    this.externalProvider,
    this.imagePath,
    this.imageUrl,
  });

  final String targetType;
  final String targetId;
  final String? externalProvider;
  final String? imagePath;
  final String? imageUrl;

  bool get hasImage => imageUrl?.trim().isNotEmpty == true;
  bool get isExternal => targetType == 'external';

  factory CollectionCoverItem.fromMap(Map<String, dynamic> map) =>
      CollectionCoverItem(
        targetType: map['target_type'] as String? ?? 'spot',
        targetId: map['target_id'] as String? ?? '',
        externalProvider: map['external_provider'] as String?,
        imagePath: map['image_path'] as String?,
        imageUrl: map['image_url'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'target_type': targetType,
        'target_id': targetId,
        'external_provider': externalProvider,
        'image_path': imagePath,
        'image_url': imageUrl,
      };

  CollectionCoverItem copyWith({String? imageUrl}) => CollectionCoverItem(
        targetType: targetType,
        targetId: targetId,
        externalProvider: externalProvider,
        imagePath: imagePath,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}

class SavedCollectionModel {
  SavedCollectionModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.itemCount = 0,
    this.spotCount = 0,
    this.restaurantCount = 0,
    this.externalCount = 0,
    this.coverTargetType,
    this.coverImageUrl,
    this.coverImagePath,
    List<CollectionCoverItem> coverItems = const [],
    required this.createdAt,
    required this.updatedAt,
  }) : coverItems = List.unmodifiable(coverItems.take(4));

  final String id;
  final String userId;
  final String name;
  final String? description;
  final int itemCount;
  final int spotCount;
  final int restaurantCount;
  final int externalCount;
  final String? coverTargetType;
  final String? coverImageUrl;
  final String? coverImagePath;
  final List<CollectionCoverItem> coverItems;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SavedCollectionModel.fromMap(Map<String, dynamic> map) {
    final rawCoverItems = map['cover_items'];
    final coverItems = rawCoverItems is List
        ? rawCoverItems
            .whereType<Map>()
            .map(
              (item) => CollectionCoverItem.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .take(4)
            .toList()
        : <CollectionCoverItem>[];
    if (coverItems.isEmpty &&
        ((map['cover_target_type'] as String?)?.isNotEmpty == true ||
            (map['cover_image_path'] as String?)?.isNotEmpty == true)) {
      coverItems.add(
        CollectionCoverItem(
          targetType: map['cover_target_type'] as String? ?? 'spot',
          targetId: '',
          imagePath: map['cover_image_path'] as String? ??
              map['cover_image_url'] as String?,
          imageUrl: map['cover_image_url'] as String?,
        ),
      );
    }
    return SavedCollectionModel(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      itemCount: (map['item_count'] as num?)?.toInt() ?? 0,
      spotCount: (map['spot_count'] as num?)?.toInt() ?? 0,
      restaurantCount: (map['restaurant_count'] as num?)?.toInt() ?? 0,
      externalCount: (map['external_count'] as num?)?.toInt() ?? 0,
      coverTargetType: map['cover_target_type'] as String?,
      coverImageUrl: map['cover_image_url'] as String?,
      coverImagePath: map['cover_image_path'] as String? ??
          map['cover_image_url'] as String?,
      coverItems: coverItems,
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
        'external_count': externalCount,
        'cover_target_type': coverTargetType,
        'cover_image_url': coverImageUrl,
        'cover_image_path': coverImagePath,
        'cover_items': coverItems.map((item) => item.toMap()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  SavedCollectionModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    bool clearDescription = false,
    int? itemCount,
    int? spotCount,
    int? restaurantCount,
    int? externalCount,
    String? coverTargetType,
    String? coverImageUrl,
    String? coverImagePath,
    List<CollectionCoverItem>? coverItems,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedCollectionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      itemCount: itemCount ?? this.itemCount,
      spotCount: spotCount ?? this.spotCount,
      restaurantCount: restaurantCount ?? this.restaurantCount,
      externalCount: externalCount ?? this.externalCount,
      coverTargetType: coverTargetType ?? this.coverTargetType,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      coverItems: coverItems ?? this.coverItems,
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
    this.externalProvider,
    this.externalPlaceId,
  });

  final String id;
  final String collectionId;
  final String savedPlaceId;
  final DateTime addedAt;
  final String? spotId;
  final String? restaurantId;
  final String? externalProvider;
  final String? externalPlaceId;

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
      externalProvider: map['external_provider'] as String?,
      externalPlaceId: map['external_place_id'] as String?,
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
    this.externalProvider,
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
  final String? externalProvider;
  final String? priceRange;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final DateTime addedAt;

  bool get isSpot => targetType == 'spot';
  bool get isRestaurant => targetType == 'restaurant';
  bool get isExternal => targetType == 'external';

  factory SavedCollectionPlace.fromMap(Map<String, dynamic> map) {
    return SavedCollectionPlace(
      savedPlaceId: map['saved_place_id'] as String? ?? '',
      targetType: map['target_type'] as String? ?? 'spot',
      targetId: map['target_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unavailable place',
      state: map['state'] as String? ?? '',
      city: map['city'] as String? ?? '',
      categoryOrCuisine: map['category_or_cuisine'] as String? ?? '',
      externalProvider: map['external_provider'] as String?,
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
        'external_provider': externalProvider,
        'price_range': priceRange,
        'image_url': imageUrl,
        'rating': rating,
        'review_count': reviewCount,
        'added_at': addedAt.toIso8601String(),
      };
}

/// Result of set_place_collections mutation.
/// Represents operation success and resulting saved state explicitly.
class SetPlaceCollectionsResult {
  const SetPlaceCollectionsResult({
    required this.saved,
    required this.collectionIds,
    this.targetType,
    this.targetId,
  });

  final bool saved;
  final List<String> collectionIds;
  final String? targetType;
  final String? targetId;

  factory SetPlaceCollectionsResult.fromMap(Map<String, dynamic> map) {
    return SetPlaceCollectionsResult(
      saved: map['saved'] as bool? ?? false,
      collectionIds: (map['collection_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      targetType: map['target_type'] as String?,
      targetId: map['target_id'] as String?,
    );
  }
}

/// Resolved metadata and exact coordinates for itinerary route generation, independent of discovery pagination caches.
class SavedRouteCandidate {
  const SavedRouteCandidate({
    required this.savedPlaceId,
    required this.targetType,
    required this.targetId,
    required this.name,
    required this.state,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.categoryOrCuisine,
    this.externalProvider,
    this.bestTime,
    this.thingsToDo,
    this.reviewedDishes,
    this.priceRange,
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  final String savedPlaceId;
  final String targetType; // 'spot' | 'restaurant'
  final String targetId;
  final String name;
  final String state;
  final String city;
  final double latitude;
  final double longitude;
  final String categoryOrCuisine;
  final String? externalProvider;
  final String? bestTime;
  final String? thingsToDo;
  final String? reviewedDishes;
  final String? priceRange;
  final String? imageUrl;
  final double rating;
  final int reviewCount;

  bool get isSpot => targetType == 'spot';
  bool get isRestaurant => targetType == 'restaurant';
  bool get isExternal => targetType == 'external';

  factory SavedRouteCandidate.fromMap(Map<String, dynamic> map) {
    return SavedRouteCandidate(
      savedPlaceId: map['saved_place_id'] as String? ?? '',
      targetType: map['target_type'] as String? ?? 'spot',
      targetId: map['target_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unavailable place',
      state: map['state'] as String? ?? '',
      city: map['city'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      categoryOrCuisine: map['category_or_cuisine'] as String? ?? '',
      externalProvider: map['external_provider'] as String?,
      bestTime: map['best_time'] as String?,
      thingsToDo: map['things_to_do'] as String?,
      reviewedDishes: map['reviewed_dishes'] as String?,
      priceRange: map['price_range'] as String?,
      imageUrl: map['image_url'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
    );
  }
}
