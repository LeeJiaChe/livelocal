enum GuideStopKind { listing, provider, custom }

class GuideStopModel {
  const GuideStopModel({
    required this.kind,
    required this.name,
    required this.instruction,
    this.listingType,
    this.listingId,
    this.placeProvider,
    this.googlePlaceId,
  });

  final GuideStopKind kind;
  final String name;
  final String instruction;
  final String? listingType;
  final String? listingId;
  final String? placeProvider;
  final String? googlePlaceId;

  bool get isCustom => kind == GuideStopKind.custom;

  Map<String, dynamic> toMap() => {
        'kind': kind.name,
        'name': name,
        'instruction': instruction,
        if (listingType != null) 'listing_type': listingType,
        if (listingId != null) 'listing_id': listingId,
        if (placeProvider != null) 'place_provider': placeProvider,
        if (googlePlaceId != null) 'google_place_id': googlePlaceId,
      };

  factory GuideStopModel.fromMap(Map<String, dynamic> map) => GuideStopModel(
        kind: switch (map['kind']) {
          'listing' => GuideStopKind.listing,
          'provider' => GuideStopKind.provider,
          _ => GuideStopKind.custom,
        },
        name: map['name'] as String? ?? '',
        instruction: map['instruction'] as String? ?? '',
        listingType: map['listing_type'] as String?,
        listingId: map['listing_id'] as String?,
        placeProvider: map['place_provider'] as String?,
        googlePlaceId: map['google_place_id'] as String?,
      );
}

class GuideModel {
  final String id;
  final String title;
  final String locationName;
  final String state;
  final String routeOverview;
  final List<String> stops;
  final List<String> walkingSequence;
  final List<GuideStopModel> stopDetails;
  final String estimatedDuration;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final String? revisionId;
  final int version;
  final String? decisionReason;
  final String? authorDisplayName;
  final bool authorIsCreator;

  GuideModel({
    required this.id,
    required this.title,
    required this.locationName,
    required this.state,
    required this.routeOverview,
    required this.stops,
    required this.walkingSequence,
    List<GuideStopModel>? stopDetails,
    required this.estimatedDuration,
    this.status = 'approved',
    this.rejectionReason,
    this.revisionId,
    this.version = 1,
    this.decisionReason,
    this.authorDisplayName,
    this.authorIsCreator = false,
  }) : stopDetails = stopDetails ??
            List.generate(
              stops.length,
              (index) => GuideStopModel(
                kind: GuideStopKind.custom,
                name: stops[index],
                instruction: index < walkingSequence.length
                    ? walkingSequence[index]
                    : '',
              ),
            );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'location_name': locationName,
        'state': state,
        'route_overview': routeOverview,
        'stops': stops,
        'walking_sequence': walkingSequence,
        'stop_details': stopDetails.map((stop) => stop.toMap()).toList(),
        'estimated_duration': estimatedDuration,
        'status': status,
        'rejection_reason': rejectionReason,
        'revision_id': revisionId,
        'version': version,
        'decision_reason': decisionReason,
        'author_display_name': authorDisplayName,
        'author_is_creator': authorIsCreator,
      };

  factory GuideModel.fromMap(Map<String, dynamic> map) {
    final stops = List<String>.from(map['stops'] ?? []);
    final walkingSequence = List<String>.from(map['walking_sequence'] ?? []);
    final rawDetails = map['stop_details'];
    return GuideModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      locationName: map['location_name'] ?? '',
      state: map['state'] ?? '',
      routeOverview: map['route_overview'] ?? '',
      stops: stops,
      walkingSequence: walkingSequence,
      stopDetails: rawDetails is List && rawDetails.isNotEmpty
          ? rawDetails
              .map((item) => GuideStopModel.fromMap(
                  Map<String, dynamic>.from(item as Map)))
              .toList()
          : null,
      estimatedDuration: map['estimated_duration'] ?? '',
      status: map['status'] ?? 'approved',
      rejectionReason: map['rejection_reason'],
      revisionId: map['revision_id'],
      version: (map['version'] as num?)?.toInt() ?? 1,
      decisionReason: map['decision_reason'],
      authorDisplayName: map['author_display_name'] as String?,
      authorIsCreator: map['author_is_creator'] == true,
    );
  }
}
