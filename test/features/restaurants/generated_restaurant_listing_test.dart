import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/restaurants/domain/generated_restaurant_listing.dart';

void main() {
  test('parses a generated candidate and joins reviewed dishes', () {
    final result = SocialSourceAnalysisResult.fromJson({
      'sourceType': 'post',
      'platform': 'instagram',
      'candidates': [
        {
          'restaurantName': 'Village Park Restaurant',
          'address': null,
          'state': 'Selangor',
          'city': 'Petaling Jaya',
          'cuisineType': 'Malay',
          'priceRange': null,
          'reviewedDishes': ['Nasi Lemak', 'Ayam Goreng'],
          'sourcePlatform': 'instagram',
          'sourcePostUrl': 'https://instagram.com/reel/ABC/',
          'influencerUsername': 'localfoodie',
          'sourceCaption': 'Lunch at Village Park',
          'confidence': 0.88,
          'missingFields': ['address', 'priceRange'],
        },
      ],
    });

    final candidate = result.candidates.single;
    expect(candidate.restaurantName, 'Village Park Restaurant');
    expect(candidate.reviewedDishes, 'Nasi Lemak, Ayam Goreng');
    expect(candidate.missingFields, ['address', 'priceRange']);
  });

  test('keeps unknown fields null instead of inventing defaults', () {
    final candidate = GeneratedRestaurantListing.fromJson({
      'restaurantName': null,
      'address': '',
      'state': null,
      'city': null,
      'cuisineType': null,
      'priceRange': null,
      'reviewedDishes': <String>[],
      'sourcePlatform': 'tiktok',
      'sourcePostUrl': 'https://tiktok.com/@creator/video/123',
      'influencerUsername': null,
      'sourceCaption': null,
      'confidence': 0,
      'missingFields': [
        'restaurantName',
        'address',
        'priceRange',
      ],
    });

    expect(candidate.restaurantName, isNull);
    expect(candidate.address, isNull);
    expect(candidate.priceRange, isNull);
    expect(candidate.reviewedDishes, isNull);
    expect(
      candidate.missingFields,
      containsAll([
        'restaurantName',
        'address',
        'state',
        'city',
        'cuisineType',
        'priceRange',
        'reviewedDishes',
      ]),
    );
  });

  test('rejects a profile URL supplied as a candidate review URL', () {
    expect(
      () => GeneratedRestaurantListing.fromJson({
        'restaurantName': null,
        'address': null,
        'state': null,
        'city': null,
        'cuisineType': null,
        'priceRange': null,
        'reviewedDishes': <String>[],
        'sourcePlatform': 'instagram',
        'sourcePostUrl': 'https://instagram.com/creator/',
        'confidence': 0,
        'missingFields': GeneratedRestaurantListing.listingFields,
      }),
      throwsFormatException,
    );
  });

  test('parses Google Maps and website partial drafts', () {
    final maps = SocialSourceAnalysisResult.fromJson({
      'sourceType': 'place',
      'platform': 'google_maps',
      'candidates': [
        {
          'restaurantName': 'Line Clear Nasi Kandar',
          'address': '177 Jalan Penang, George Town, Pulau Pinang',
          'state': 'Pulau Pinang',
          'city': 'George Town',
          'cuisineType': 'Restaurant',
          'priceRange': r'$$',
          'reviewedDishes': <String>[],
          'sourcePlatform': 'google_maps',
          'sourcePostUrl': 'https://maps.app.goo.gl/AbCdEf123456',
          'confidence': 1,
          'missingFields': ['reviewedDishes'],
        },
      ],
    });
    final website = GeneratedRestaurantListing.fromJson({
      'restaurantName': 'Public Cafe',
      'address': null,
      'state': null,
      'city': null,
      'cuisineType': null,
      'priceRange': null,
      'reviewedDishes': <String>[],
      'sourcePlatform': 'website',
      'sourcePostUrl': 'https://public-cafe.example/about',
      'confidence': 0.3,
      'missingFields': GeneratedRestaurantListing.listingFields,
    });

    expect(maps.candidates.single.city, 'George Town');
    expect(website.restaurantName, 'Public Cafe');
    expect(website.missingFields, contains('address'));
  });
}
