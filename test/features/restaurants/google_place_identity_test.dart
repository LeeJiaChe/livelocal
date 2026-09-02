import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/restaurants/domain/generated_restaurant_listing.dart';
import 'package:live_local/models/restaurant_model.dart';
import 'package:live_local/models/spot_model.dart';

void main() {
  test('Google Maps AI candidate keeps stable place identity and coordinates',
      () {
    final listing = GeneratedRestaurantListing.fromJson({
      'restaurantName': 'Pak Yuu Kopitiam',
      'address': '1 Jalan Example, Ipoh, Perak',
      'state': 'Perak',
      'city': 'Ipoh',
      'cuisineType': 'Malaysian',
      'priceRange': r'$',
      'reviewedDishes': ['Kaya toast'],
      'placeProvider': 'google',
      'googlePlaceId': 'ChIJPakYuuPlace123',
      'latitude': 4.5975,
      'longitude': 101.0901,
      'sourcePlatform': 'google_maps',
      'sourcePostUrl': 'https://maps.app.goo.gl/AbCdEf123456',
      'confidence': 1,
      'missingFields': <String>[],
    });

    expect(listing.googlePlaceId, 'ChIJPakYuuPlace123');
    expect(listing.placeProvider, 'google');
    expect(listing.latitude, 4.5975);
  });

  test('legacy Spot and Eat records remain valid without provider identity',
      () {
    final spot = SpotModel.fromMap({
      'id': 'legacy-spot',
      'name': 'Hidden waterfall',
      'category': 'Nature',
      'description': 'A legacy custom location with local context.',
      'state': 'Perak',
      'city': 'Ipoh',
      'address': 'Old trail address',
      'best_time': 'Morning',
      'things_to_do': 'Walk the trail',
      'submitted_by': 'tourist',
    });
    final eat = RestaurantModel.fromMap({
      'id': 'legacy-eat',
      'name': 'Hidden stall',
      'address': 'Local market lane',
      'state': 'Perak',
      'city': 'Ipoh',
      'cuisine_type': 'Malaysian',
      'price_range': r'$',
      'reviewed_dishes': 'Noodles',
      'influencer_id': 'creator',
      'influencer_name': 'Local creator',
      'social_media_url': 'https://example.com',
      'cover_photo_url': '',
    });

    expect(spot.googlePlaceId, isNull);
    expect(eat.googlePlaceId, isNull);
  });
}
