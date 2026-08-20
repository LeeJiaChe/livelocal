class SavedCollectionModel {
  const SavedCollectionModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.itemCount = 0,
    this.spotCount = 0,
    this.restaurantCount = 0,
    this.coverImageUrl,
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
  final String? coverImageUrl;
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
      coverImageUrl: map['cover_image_url'] as String?,
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
        'cover_image_url': coverImageUrl,
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
    String? coverImageUrl,
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
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
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
