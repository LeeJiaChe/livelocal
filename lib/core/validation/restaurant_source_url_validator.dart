import 'social_url_validator.dart';

enum RestaurantSourceType { socialPost, googleMaps, website, unsupported }

class RestaurantSourceDetection {
  const RestaurantSourceDetection({required this.type, this.platform});

  final RestaurantSourceType type;
  final String? platform;
}

class RestaurantSourceUrlValidator {
  static const supportedPlatforms = {
    'tiktok',
    'instagram',
    'google_maps',
    'website',
  };

  static RestaurantSourceDetection detect(String value) {
    final uri = _safeUri(value);
    if (uri == null) {
      return const RestaurantSourceDetection(
        type: RestaurantSourceType.unsupported,
      );
    }
    final social = SocialUrlValidator.detectSource(value);
    if (social.type == SocialSourceType.post) {
      return RestaurantSourceDetection(
        type: RestaurantSourceType.socialPost,
        platform: social.platform,
      );
    }
    if (social.type == SocialSourceType.profile) {
      return const RestaurantSourceDetection(
        type: RestaurantSourceType.unsupported,
      );
    }
    if (_isGoogleMaps(uri)) {
      return const RestaurantSourceDetection(
        type: RestaurantSourceType.googleMaps,
        platform: 'google_maps',
      );
    }
    if (_isPublicWebsiteHost(uri.host)) {
      return const RestaurantSourceDetection(
        type: RestaurantSourceType.website,
        platform: 'website',
      );
    }
    return const RestaurantSourceDetection(
      type: RestaurantSourceType.unsupported,
    );
  }

  static bool isSupported(String value) =>
      detect(value).type != RestaurantSourceType.unsupported;

  static String? detectPlatform(String value) => detect(value).platform;

  static String platformLabel(String value) => switch (detectPlatform(value)) {
        'tiktok' => 'TikTok',
        'instagram' => 'Instagram',
        'google_maps' => 'Google Maps',
        'website' => 'Website',
        _ => 'Source',
      };

  static Uri? _safeUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        value.trim().length > 2048) {
      return null;
    }
    return uri;
  }

  static bool _isGoogleMaps(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host == 'maps.app.goo.gl' || host == 'maps.google.com') return true;
    return (host == 'google.com' || host == 'www.google.com') &&
        (uri.path == '/maps' || uri.path.startsWith('/maps/'));
  }

  static bool _isPublicWebsiteHost(String value) {
    final host = value.toLowerCase();
    if (host.contains('instagram.com.') ||
        host.contains('tiktok.com.') ||
        host.contains('google.com.')) {
      return false;
    }
    if (host == 'localhost' ||
        host.endsWith('.localhost') ||
        host.endsWith('.local') ||
        host == '0.0.0.0' ||
        host == '127.0.0.1' ||
        host == '::1') {
      return false;
    }
    final ipv4 = host.split('.').map(int.tryParse).toList();
    if (ipv4.length == 4 && ipv4.every((part) => part != null)) {
      final first = ipv4[0]!;
      final second = ipv4[1]!;
      if (first == 10 ||
          first == 127 ||
          first == 0 ||
          (first == 169 && second == 254) ||
          (first == 172 && second >= 16 && second <= 31) ||
          (first == 192 && second == 168)) {
        return false;
      }
    }
    return host.contains('.');
  }
}
