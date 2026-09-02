class GoogleMapsRouteStop {
  const GoogleMapsRouteStop({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.googlePlaceId,
  });

  final String name;
  final double latitude;
  final double longitude;
  final String? googlePlaceId;

  String get coordinate => '$latitude,$longitude';
}

class GoogleMapsRouteHandoff {
  const GoogleMapsRouteHandoff._();

  /// Google Maps URLs support ordered directions without embedding an SDK.
  /// LiveLocal days are limited to five stops in presentation, safely below
  /// practical waypoint limits on mobile browsers.
  static Uri build(List<GoogleMapsRouteStop> orderedStops) {
    if (orderedStops.isEmpty) {
      throw ArgumentError.value(orderedStops, 'orderedStops', 'is empty');
    }
    if (orderedStops.length == 1) {
      final stop = orderedStops.single;
      return Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': stop.coordinate,
        if (stop.googlePlaceId != null) 'query_place_id': stop.googlePlaceId!,
      });
    }
    final origin = orderedStops.first;
    final destination = orderedStops.last;
    final waypoints = orderedStops
        .skip(1)
        .take(orderedStops.length - 2)
        .map((stop) => stop.coordinate)
        .join('|');
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': origin.coordinate,
      'destination': destination.coordinate,
      if (waypoints.isNotEmpty) 'waypoints': waypoints,
      'travelmode': 'driving',
    });
  }
}
