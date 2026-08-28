import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/core/errors/app_exception.dart';
import 'package:live_local/features/places/domain/external_place.dart';
import 'package:live_local/features/places/domain/place_provider.dart';
import 'package:live_local/features/places/presentation/place_discovery_controller.dart';
import 'package:live_local/services/location_service.dart';

void main() {
  test('search exposes loading, results, pagination and de-duplicates IDs',
      () async {
    final provider = _FakePlaceProvider()
      ..pages.addAll([
        ExternalPlacePage(
          places: [_place('google-a', 'Penang Cafe')],
          nextPageToken: 'page-2',
        ),
        ExternalPlacePage(
          places: [
            _place('google-a', 'Penang Cafe'),
            _place('google-b', 'Heritage Cafe'),
          ],
        ),
      ]);
    final controller = PlaceDiscoveryController(provider: provider);

    final first = controller.search('cafe in Penang');
    expect(controller.isLoading, isTrue);
    await first;
    expect(controller.places.map((place) => place.placeId), ['google-a']);
    expect(controller.canLoadMore, isTrue);

    await controller.loadMore();
    expect(
      controller.places.map((place) => place.placeId),
      ['google-a', 'google-b'],
    );
    expect(provider.searchPageTokens, [null, 'page-2']);
  });

  test('search exposes a retryable sanitized error', () async {
    final provider = _FakePlaceProvider()
      ..error = const AppException(
        code: AppErrorCode.network,
        userMessage: 'Check your connection and retry.',
      );
    final controller = PlaceDiscoveryController(provider: provider);

    await controller.search('museum Kuala Lumpur');

    expect(controller.isLoading, isFalse);
    expect(controller.places, isEmpty);
    expect(controller.errorMessage, 'Check your connection and retry.');
  });

  test('debounced query immediately clears stale results and shows loading',
      () async {
    final provider = _FakePlaceProvider()
      ..pages.addAll([
        ExternalPlacePage(places: [_place('old-place', 'Old Cafe')]),
        ExternalPlacePage(places: [_place('new-place', 'New Museum')]),
      ]);
    final controller = PlaceDiscoveryController(provider: provider);
    await controller.search('cafe Penang');
    expect(controller.places.single.placeId, 'old-place');

    controller.updateQuery('museum Kuala Lumpur');

    expect(controller.isLoading, isTrue);
    expect(controller.places, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(controller.isLoading, isFalse);
    expect(controller.places.single.placeId, 'new-place');
    controller.dispose();
  });

  test('stale search response cannot overwrite a newer query', () async {
    final provider = _CompleterPlaceProvider();
    final controller = PlaceDiscoveryController(provider: provider);

    final oldRequest = controller.search('cafe in Penang');
    final newRequest = controller.search('museum Kuala Lumpur');
    provider.completers[1].complete(
      ExternalPlacePage(places: [_place('new-place', 'National Museum')]),
    );
    await newRequest;
    provider.completers[0].complete(
      ExternalPlacePage(places: [_place('old-place', 'Old Cafe')]),
    );
    await oldRequest;

    expect(controller.places.single.placeId, 'new-place');
  });

  test('Nearby denied does not call provider or break text search', () async {
    final provider = _FakePlaceProvider();
    final controller = PlaceDiscoveryController(
      provider: provider,
      locationService: const _FakeLocationService(
        LocationRequestResult.failed(
          LocationRequestFailure.denied,
          'Permission denied. Search by city.',
        ),
      ),
    );

    await controller.nearby();

    expect(provider.nearbyCalls, 0);
    expect(controller.locationFailure, LocationRequestFailure.denied);
    expect(controller.errorMessage, contains('Search by city'));
  });

  test('Nearby passes real successful coordinates to provider', () async {
    final provider = _FakePlaceProvider()
      ..nearbyResults = [_place('nearby-one', 'Nearby Cafe')];
    final controller = PlaceDiscoveryController(
      provider: provider,
      locationService: const _FakeLocationService(
        LocationRequestResult.coordinates(5.4141, 100.3288),
      ),
    );

    await controller.nearby();

    expect(provider.lastLatitude, 5.4141);
    expect(provider.lastLongitude, 100.3288);
    expect(controller.places.single.name, 'Nearby Cafe');
    expect(controller.isNearby, isTrue);
  });
}

ExternalPlace _place(String id, String name) => ExternalPlace(
      provider: 'google',
      placeId: id,
      name: name,
      formattedAddress: 'Malaysia',
      latitude: 5.4,
      longitude: 100.3,
    );

class _FakePlaceProvider implements PlaceProvider {
  final pages = <ExternalPlacePage>[];
  final searchPageTokens = <String?>[];
  Object? error;
  List<ExternalPlace> nearbyResults = [];
  int nearbyCalls = 0;
  double? lastLatitude;
  double? lastLongitude;

  @override
  Future<ExternalPlacePage> search({
    required String query,
    String? category,
    String? pageToken,
  }) async {
    searchPageTokens.add(pageToken);
    if (error != null) throw error!;
    return pages.removeAt(0);
  }

  @override
  Future<List<ExternalPlace>> nearby({
    required double latitude,
    required double longitude,
    double radius = 5000,
    String? category,
    bool rankByDistance = false,
  }) async {
    nearbyCalls += 1;
    lastLatitude = latitude;
    lastLongitude = longitude;
    return nearbyResults;
  }

  @override
  Future<ExternalPlace> details(String placeId) async =>
      nearbyResults.firstWhere((place) => place.placeId == placeId);
}

class _CompleterPlaceProvider implements PlaceProvider {
  final completers = <Completer<ExternalPlacePage>>[];

  @override
  Future<ExternalPlacePage> search({
    required String query,
    String? category,
    String? pageToken,
  }) {
    final completer = Completer<ExternalPlacePage>();
    completers.add(completer);
    return completer.future;
  }

  @override
  Future<ExternalPlace> details(String placeId) => throw UnimplementedError();

  @override
  Future<List<ExternalPlace>> nearby({
    required double latitude,
    required double longitude,
    double radius = 5000,
    String? category,
    bool rankByDistance = false,
  }) =>
      throw UnimplementedError();
}

class _FakeLocationService implements CurrentLocationService {
  const _FakeLocationService(this.result);

  final LocationRequestResult result;

  @override
  Future<LocationRequestResult> requestCurrentLocation() async => result;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}
