import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/restaurant_model.dart';
import '../models/saved_collection_model.dart';
import '../models/spot_model.dart';

enum LocationRequestFailure {
  serviceDisabled,
  denied,
  deniedForever,
  unavailable,
}

class LocationRequestResult {
  const LocationRequestResult._({
    this.latitude,
    this.longitude,
    this.failure,
    this.message,
    this.position,
  });

  factory LocationRequestResult.success(Position position) =>
      LocationRequestResult._(
        latitude: position.latitude,
        longitude: position.longitude,
        position: position,
      );

  const LocationRequestResult.coordinates(double latitude, double longitude)
      : this._(latitude: latitude, longitude: longitude);

  const LocationRequestResult.failed(
    LocationRequestFailure failure,
    String message,
  ) : this._(failure: failure, message: message);

  final double? latitude;
  final double? longitude;
  final LocationRequestFailure? failure;
  final String? message;
  final Position? position;

  bool get isSuccess => latitude != null && longitude != null;
}

abstract interface class CurrentLocationService {
  Future<LocationRequestResult> requestCurrentLocation();
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

/// Abstract strategy for calculating proximity-based itineraries.
abstract class RoutingStrategy {
  List<Map<String, dynamic>> calculateRoute(
    double startLat,
    double startLng,
    List<SpotModel> spots,
    List<RestaurantModel> restaurants,
  );

  List<SavedRouteCandidate> calculateRouteFromCandidates(
    double startLat,
    double startLng,
    List<SavedRouteCandidate> candidates,
  );
}

/// A basic implementation that visits the next geographically closest point.
class NearestNeighborRouting implements RoutingStrategy {
  @override
  List<SavedRouteCandidate> calculateRouteFromCandidates(
    double startLat,
    double startLng,
    List<SavedRouteCandidate> candidates,
  ) {
    final unvisited = candidates
        .where((c) => c.latitude != 0.0 && c.longitude != 0.0)
        .toList();

    if (unvisited.isEmpty) return [];

    final route = <SavedRouteCandidate>[];
    double currentLat = startLat;
    double currentLng = startLng;

    while (unvisited.isNotEmpty) {
      int closestIndex = 0;
      double minDistance = double.maxFinite;

      for (int i = 0; i < unvisited.length; i++) {
        final dist = _calculateHaversineDistance(
          currentLat,
          currentLng,
          unvisited[i].latitude,
          unvisited[i].longitude,
        );
        if (dist < minDistance) {
          minDistance = dist;
          closestIndex = i;
        }
      }

      final nextStop = unvisited.removeAt(closestIndex);
      route.add(nextStop);
      currentLat = nextStop.latitude;
      currentLng = nextStop.longitude;
    }

    return route;
  }

  @override
  List<Map<String, dynamic>> calculateRoute(
    double startLat,
    double startLng,
    List<SpotModel> spots,
    List<RestaurantModel> restaurants,
  ) {
    final List<Map<String, dynamic>> unvisited = [];

    for (var s in spots) {
      if (s.latitude != null && s.longitude != null) {
        unvisited.add({
          'type': 'Spot',
          'item': s,
          'lat': s.latitude!,
          'lng': s.longitude!
        });
      }
    }
    for (var r in restaurants) {
      if (r.latitude != null && r.longitude != null) {
        unvisited.add({
          'type': 'Restaurant',
          'item': r,
          'lat': r.latitude!,
          'lng': r.longitude!
        });
      }
    }

    if (unvisited.isEmpty) return [];

    final List<Map<String, dynamic>> route = [];
    double currentLat = startLat;
    double currentLng = startLng;

    while (unvisited.isNotEmpty) {
      int closestIndex = 0;
      double minDistance = double.maxFinite;

      for (int i = 0; i < unvisited.length; i++) {
        final dist = _calculateHaversineDistance(
            currentLat, currentLng, unvisited[i]['lat'], unvisited[i]['lng']);
        if (dist < minDistance) {
          minDistance = dist;
          closestIndex = i;
        }
      }

      final nextStop = unvisited.removeAt(closestIndex);
      route.add(nextStop);
      currentLat = nextStop['lat'];
      currentLng = nextStop['lng'];
    }

    return route;
  }

  double _calculateHaversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}

class LocationService implements CurrentLocationService {
  final RoutingStrategy _routingStrategy;

  // Injection allows easy swapping of routing logic in the future
  LocationService({RoutingStrategy? routingStrategy})
      : _routingStrategy = routingStrategy ?? NearestNeighborRouting();

  /// Fetches the user's current GPS location, handling permissions gracefully.
  Future<Position?> getCurrentLocation() async {
    final result = await requestCurrentLocation();
    return result.position;
  }

  @override
  Future<LocationRequestResult> requestCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationRequestResult.failed(
          LocationRequestFailure.serviceDisabled,
          'Location services are off. Turn them on, or search by city or state.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationRequestResult.failed(
          LocationRequestFailure.denied,
          'Location permission was denied. You can still search anywhere in Malaysia by text.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationRequestResult.failed(
          LocationRequestFailure.deniedForever,
          'Location permission is blocked in system settings. Enable it there, or search by city or state.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationRequestResult.success(position);
    } catch (_) {
      return const LocationRequestResult.failed(
        LocationRequestFailure.unavailable,
        'Your current location could not be read. Retry, or search by city or state.',
      );
    }
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Calculates the optimized route using the injected RoutingStrategy.
  List<Map<String, dynamic>> sortLocationsByProximity(
    double startLat,
    double startLng,
    List<SpotModel> spots,
    List<RestaurantModel> restaurants,
  ) {
    return _routingStrategy.calculateRoute(
        startLat, startLng, spots, restaurants);
  }

  List<SavedRouteCandidate> sortCandidatesByProximity(
    double startLat,
    double startLng,
    List<SavedRouteCandidate> candidates,
  ) {
    return _routingStrategy.calculateRouteFromCandidates(
      startLat,
      startLng,
      candidates,
    );
  }
}
