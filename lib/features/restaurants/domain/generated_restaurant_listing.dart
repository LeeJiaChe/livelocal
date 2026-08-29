import '../../../core/validation/restaurant_source_url_validator.dart';

class GeneratedRestaurantListing {
  const GeneratedRestaurantListing({
    this.restaurantName,
    this.address,
    this.state,
    this.city,
    this.cuisineType,
    this.priceRange,
    this.reviewedDishes,
    this.placeProvider,
    this.googlePlaceId,
    this.latitude,
    this.longitude,
    required this.sourcePlatform,
    required this.sourcePostUrl,
    this.influencerUsername,
    this.sourceCaption,
    required this.confidence,
    required this.missingFields,
  });

  final String? restaurantName;
  final String? address;
  final String? state;
  final String? city;
  final String? cuisineType;
  final String? priceRange;
  final String? reviewedDishes;
  final String? placeProvider;
  final String? googlePlaceId;
  final double? latitude;
  final double? longitude;
  final String sourcePlatform;
  final String sourcePostUrl;
  final String? influencerUsername;
  final String? sourceCaption;
  final double confidence;
  final List<String> missingFields;

  static const listingFields = <String>[
    'restaurantName',
    'address',
    'state',
    'city',
    'cuisineType',
    'priceRange',
    'reviewedDishes',
  ];

  factory GeneratedRestaurantListing.fromJson(Map<String, dynamic> json) {
    final restaurantName = _optionalString(json['restaurantName']);
    final address = _optionalString(json['address']);
    final state = _optionalString(json['state']);
    final city = _optionalString(json['city']);
    final cuisineType = _optionalString(json['cuisineType']);
    final priceRange = _optionalString(json['priceRange']);
    if (priceRange != null &&
        !const [r'$', r'$$', r'$$$', r'$$$$'].contains(priceRange)) {
      throw const FormatException('Invalid priceRange');
    }
    final reviewedDishes = _dishes(json['reviewedDishes']);
    final sourcePlatform = _requiredString(
      json['sourcePlatform'],
      'sourcePlatform',
    );
    if (!RestaurantSourceUrlValidator.supportedPlatforms
        .contains(sourcePlatform)) {
      throw const FormatException('Invalid sourcePlatform');
    }
    final sourcePostUrl = _requiredString(
      json['sourcePostUrl'],
      'sourcePostUrl',
    );
    if (!RestaurantSourceUrlValidator.isSupported(sourcePostUrl) ||
        RestaurantSourceUrlValidator.detectPlatform(sourcePostUrl) !=
            sourcePlatform) {
      throw const FormatException('Invalid sourcePostUrl');
    }
    final rawConfidence = json['confidence'];
    if (rawConfidence is! num || !rawConfidence.toDouble().isFinite) {
      throw const FormatException('Invalid confidence');
    }
    final rawMissingFields = json['missingFields'];
    if (rawMissingFields is! List ||
        rawMissingFields.any((value) => value is! String)) {
      throw const FormatException('Missing missingFields');
    }
    final values = <String, String?>{
      'restaurantName': restaurantName,
      'address': address,
      'state': state,
      'city': city,
      'cuisineType': cuisineType,
      'priceRange': priceRange,
      'reviewedDishes': reviewedDishes,
    };
    return GeneratedRestaurantListing(
      restaurantName: restaurantName,
      address: address,
      state: state,
      city: city,
      cuisineType: cuisineType,
      priceRange: priceRange,
      reviewedDishes: reviewedDishes,
      placeProvider: _optionalString(json['placeProvider']),
      googlePlaceId: _optionalString(json['googlePlaceId']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      sourcePlatform: sourcePlatform,
      sourcePostUrl: sourcePostUrl,
      influencerUsername: _optionalString(json['influencerUsername']),
      sourceCaption: _optionalString(json['sourceCaption']),
      confidence: rawConfidence.toDouble().clamp(0, 1).toDouble(),
      missingFields: listingFields
          .where((field) => values[field] == null)
          .toList(growable: false),
    );
  }

  static String? _optionalString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  static String _requiredString(Object? value, String field) {
    final parsed = _optionalString(value);
    if (parsed == null) throw FormatException('Missing $field');
    return parsed;
  }

  static String? _dishes(Object? value) {
    if (value is List) {
      final dishes = value
          .whereType<String>()
          .map((dish) => dish.trim())
          .where((dish) => dish.isNotEmpty)
          .toList(growable: false);
      return dishes.isEmpty ? null : dishes.join(', ');
    }
    return _optionalString(value);
  }
}

class SocialSourceAnalysisResult {
  const SocialSourceAnalysisResult({
    required this.sourceType,
    required this.platform,
    required this.candidates,
  });

  final String sourceType;
  final String platform;
  final List<GeneratedRestaurantListing> candidates;

  factory SocialSourceAnalysisResult.fromJson(Map<String, dynamic> json) {
    final sourceType = _requiredString(json['sourceType'], 'sourceType');
    if (!const {'post', 'place', 'website'}.contains(sourceType)) {
      throw const FormatException('Invalid sourceType');
    }
    final platform = _requiredString(json['platform'], 'platform');
    if (!RestaurantSourceUrlValidator.supportedPlatforms.contains(platform)) {
      throw const FormatException('Invalid platform');
    }
    final rawCandidates = json['candidates'];
    if (rawCandidates is! List || rawCandidates.length > 5) {
      throw const FormatException('Missing candidates');
    }
    final candidates = rawCandidates.map((value) {
      if (value is! Map) throw const FormatException('Invalid candidate');
      final candidate = GeneratedRestaurantListing.fromJson(
        Map<String, dynamic>.from(value),
      );
      if (candidate.sourcePlatform != platform) {
        throw const FormatException('Candidate platform mismatch');
      }
      return candidate;
    }).toList(growable: false);
    if (candidates.length != 1) {
      throw const FormatException('A post must return one candidate');
    }
    return SocialSourceAnalysisResult(
      sourceType: sourceType,
      platform: platform,
      candidates: candidates,
    );
  }

  static String _requiredString(Object? value, String field) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing $field');
    }
    return value.trim();
  }
}
