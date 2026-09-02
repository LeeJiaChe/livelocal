import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/core/validation/restaurant_source_url_validator.dart';

void main() {
  test('accepts Google Maps short and full place URLs', () {
    expect(
      RestaurantSourceUrlValidator.isSupported(
        'https://maps.app.goo.gl/AbCdEf123456',
      ),
      isTrue,
    );
    expect(
      RestaurantSourceUrlValidator.detectPlatform(
        'https://www.google.com/maps/place/Nasi+Kandar/@5.4,100.3,17z',
      ),
      'google_maps',
    );
  });

  test('accepts public websites and supported social posts', () {
    expect(
      RestaurantSourceUrlValidator.detectPlatform(
        'https://restaurant.example/menu',
      ),
      'website',
    );
    expect(
      RestaurantSourceUrlValidator.detectPlatform(
        'https://www.tiktok.com/@creator/video/123456',
      ),
      'tiktok',
    );
  });

  test('rejects local/private and social profile URLs', () {
    expect(
      RestaurantSourceUrlValidator.isSupported('https://localhost/menu'),
      isFalse,
    );
    expect(
      RestaurantSourceUrlValidator.isSupported(
        'https://instagram.com.evil.test/reel/ABC',
      ),
      isFalse,
    );
    expect(
      RestaurantSourceUrlValidator.isSupported('https://192.168.1.20/menu'),
      isFalse,
    );
    expect(
      RestaurantSourceUrlValidator.isSupported(
        'https://instagram.com/private_creator/',
      ),
      isFalse,
    );
  });
}
