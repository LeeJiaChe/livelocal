class PlaceInsightSummary {
  const PlaceInsightSummary({
    required this.id,
    required this.kind,
    required this.name,
    this.category,
    this.description,
    this.bestTime,
    this.thingsToDo,
    this.reviewedDishes,
    this.priceRange,
    this.creatorDisplayName,
    this.rating = 0,
    this.reviewCount = 0,
    this.upvoteCount = 0,
  });

  final String id;
  final String kind;
  final String name;
  final String? category;
  final String? description;
  final String? bestTime;
  final String? thingsToDo;
  final String? reviewedDishes;
  final String? priceRange;
  final String? creatorDisplayName;
  final double rating;
  final int reviewCount;
  final int upvoteCount;

  factory PlaceInsightSummary.fromJson(
    String kind,
    Map<String, dynamic> json,
  ) {
    return PlaceInsightSummary(
      id: json['id'] as String? ?? '',
      kind: kind,
      name: json['name'] as String? ?? '',
      category: (json['category'] ?? json['cuisine_type']) as String?,
      description: json['description'] as String?,
      bestTime: json['best_time'] as String?,
      thingsToDo: json['things_to_do'] as String?,
      reviewedDishes: json['reviewed_dishes'] as String?,
      priceRange: json['price_range'] as String?,
      creatorDisplayName: json['creator_display_name'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      upvoteCount: (json['upvote_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PlaceEnrichment {
  const PlaceEnrichment({
    required this.googlePlaceId,
    this.spot,
    this.eat,
  });

  final String googlePlaceId;
  final PlaceInsightSummary? spot;
  final PlaceInsightSummary? eat;

  bool get hasInsights => spot != null || eat != null;

  factory PlaceEnrichment.fromJson(Map<String, dynamic> json) {
    final rawSpot = json['spot'];
    final rawEat = json['eat'];
    return PlaceEnrichment(
      googlePlaceId: json['google_place_id'] as String? ?? '',
      spot: rawSpot is Map
          ? PlaceInsightSummary.fromJson(
              'spot',
              Map<String, dynamic>.from(rawSpot),
            )
          : null,
      eat: rawEat is Map
          ? PlaceInsightSummary.fromJson(
              'eat',
              Map<String, dynamic>.from(rawEat),
            )
          : null,
    );
  }
}
