class SavedPlaceModel {
  final String id;
  final String userId;
  final String? spotId;
  final String? restaurantId;
  final String? externalProvider;
  final String? externalPlaceId;
  final DateTime savedAt;

  SavedPlaceModel({
    required this.id,
    required this.userId,
    this.spotId,
    this.restaurantId,
    this.externalProvider,
    this.externalPlaceId,
    required this.savedAt,
  });

  factory SavedPlaceModel.fromMap(Map<String, dynamic> map) => SavedPlaceModel(
        id: map['id'] ?? '',
        userId: map['user_id'] ?? '',
        spotId: map['spot_id'],
        restaurantId: map['restaurant_id'],
        externalProvider: map['external_provider'],
        externalPlaceId: map['external_place_id'],
        savedAt:
            DateTime.parse(map['saved_at'] ?? DateTime.now().toIso8601String()),
      );
}
