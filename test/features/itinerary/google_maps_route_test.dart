import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/itinerary/domain/google_maps_route.dart';
import 'package:live_local/models/saved_collection_model.dart';

void main() {
  test('ordered mixed stops build a supported Google Maps directions URL', () {
    final uri = GoogleMapsRouteHandoff.build(const [
      GoogleMapsRouteStop(
        name: 'Eat stop',
        latitude: 5.414,
        longitude: 100.329,
        googlePlaceId: 'ChIJEatPlace123',
      ),
      GoogleMapsRouteStop(
        name: 'Custom stop',
        latitude: 5.418,
        longitude: 100.335,
      ),
      GoogleMapsRouteStop(
        name: 'Things to do',
        latitude: 5.421,
        longitude: 100.342,
        googlePlaceId: 'ChIJSpotPlace123',
      ),
    ]);

    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['origin'], '5.414,100.329');
    expect(uri.queryParameters['waypoints'], '5.418,100.335');
    expect(uri.queryParameters['destination'], '5.421,100.342');
  });

  test('route candidate keeps full address and both local contexts', () {
    final candidate = SavedRouteCandidate.fromMap({
      'saved_place_id': 'saved-1',
      'target_type': 'external',
      'target_id': 'ChIJMixedPlace123',
      'external_provider': 'google',
      'name': 'Mixed destination',
      'address': '12 Lebuh Example, 10200 George Town, Pulau Pinang',
      'state': 'Pulau Pinang',
      'city': 'George Town',
      'latitude': 5.42,
      'longitude': 100.33,
      'category_or_cuisine': 'Market',
      'best_time': 'Morning',
      'things_to_do': 'Browse the wet market',
      'reviewed_dishes': 'Char koay teow',
      'spot_id': 'spot-1',
      'restaurant_id': 'eat-1',
    });

    expect(
        candidate.address, '12 Lebuh Example, 10200 George Town, Pulau Pinang');
    expect(candidate.spotId, 'spot-1');
    expect(candidate.restaurantId, 'eat-1');
    expect(candidate.thingsToDo, 'Browse the wet market');
    expect(candidate.reviewedDishes, 'Char koay teow');
  });
}
