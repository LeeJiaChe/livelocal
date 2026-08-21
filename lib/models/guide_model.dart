class GuideModel {
  final String id;
  final String title;
  final String locationName;
  final String state;
  final String routeOverview;
  final List<String> stops;
  final List<String> walkingSequence;
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
    required this.estimatedDuration,
    this.status = 'approved',
    this.rejectionReason,
    this.revisionId,
    this.version = 1,
    this.decisionReason,
    this.authorDisplayName,
    this.authorIsCreator = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'location_name': locationName,
        'state': state,
        'route_overview': routeOverview,
        'stops': stops,
        'walking_sequence': walkingSequence,
        'estimated_duration': estimatedDuration,
        'status': status,
        'rejection_reason': rejectionReason,
        'revision_id': revisionId,
        'version': version,
        'decision_reason': decisionReason,
        'author_display_name': authorDisplayName,
        'author_is_creator': authorIsCreator,
      };

  factory GuideModel.fromMap(Map<String, dynamic> map) => GuideModel(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        locationName: map['location_name'] ?? '',
        state: map['state'] ?? '',
        routeOverview: map['route_overview'] ?? '',
        stops: List<String>.from(map['stops'] ?? []),
        walkingSequence: List<String>.from(map['walking_sequence'] ?? []),
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
