class ExternalPlace {
  const ExternalPlace({
    required this.provider,
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.primaryType,
    this.types = const [],
    this.rating,
    this.userRatingCount,
    this.priceLevel,
    this.openNow,
    this.weekdayDescriptions = const [],
    this.phoneNumber,
    this.websiteUri,
    this.googleMapsUri,
    this.imageUrl,
  });

  final String provider;
  final String placeId;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String? primaryType;
  final List<String> types;
  final double? rating;
  final int? userRatingCount;
  final String? priceLevel;
  final bool? openNow;
  final List<String> weekdayDescriptions;
  final String? phoneNumber;
  final String? websiteUri;
  final String? googleMapsUri;
  final String? imageUrl;

  String get providerIdentity => '$provider:$placeId';

  factory ExternalPlace.fromJson(Map<String, dynamic> json) {
    final provider = json['provider'];
    final placeId = json['placeId'];
    final name = json['name'];
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    if (provider is! String ||
        provider != 'google' ||
        placeId is! String ||
        placeId.isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        latitude is! num ||
        longitude is! num) {
      throw const FormatException('Invalid external place');
    }
    return ExternalPlace(
      provider: provider,
      placeId: placeId,
      name: name.trim(),
      formattedAddress: (json['formattedAddress'] as String?)?.trim() ?? '',
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      primaryType: json['primaryType'] as String?,
      types: (json['types'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .take(8)
          .toList(growable: false),
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingCount: (json['userRatingCount'] as num?)?.toInt(),
      priceLevel: json['priceLevel'] as String?,
      openNow: json['openNow'] as bool?,
      weekdayDescriptions:
          (json['weekdayDescriptions'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .take(7)
              .toList(growable: false),
      phoneNumber: json['phoneNumber'] as String?,
      websiteUri: json['websiteUri'] as String?,
      googleMapsUri: json['googleMapsUri'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class ExternalPlacePage {
  const ExternalPlacePage({required this.places, this.nextPageToken});

  final List<ExternalPlace> places;
  final String? nextPageToken;
}
