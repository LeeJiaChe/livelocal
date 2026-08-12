class SocialUrlValidator {
  static const supportedPlatforms = {
    'tiktok',
    'instagram',
  };

  static bool isSupported(
    String value, {
    String? platform,
  }) {
    final uri = Uri.tryParse(value.trim());

    if (uri == null) {
      return false;
    }

    if (uri.scheme.toLowerCase() != 'https') {
      return false;
    }

    if (uri.hasPort) {
      return false;
    }

    final detectedPlatform = detectPlatform(value);

    if (detectedPlatform == null) {
      return false;
    }

    if (platform != null &&
        detectedPlatform != platform.trim().toLowerCase()) {
      return false;
    }

    return true;
  }

  static String? detectPlatform(String value) {
    final uri = Uri.tryParse(value.trim());

    if (uri == null) {
      return null;
    }

    final host = uri.host.toLowerCase();

    if (host == 'instagram.com' || host == 'www.instagram.com') {
      return 'instagram';
    }

    if (host == 'tiktok.com' ||
        host == 'www.tiktok.com' ||
        host == 'vm.tiktok.com' ||
        host == 'vt.tiktok.com') {
      return 'tiktok';
    }

    return null;
  }

  static bool isReviewPost(String value) {
    if (!isSupported(value)) {
      return false;
    }

    final uri = Uri.tryParse(value.trim());

    if (uri == null) {
      return false;
    }

    final platform = detectPlatform(value);
    final segments = uri.pathSegments
        .where((segment) => segment.trim().isNotEmpty)
        .toList();

    if (platform == 'instagram') {
      if (segments.length < 2) {
        return false;
      }

      return segments.first == 'p' ||
          segments.first == 'reel' ||
          segments.first == 'reels' ||
          segments.first == 'tv';
    }

    if (platform == 'tiktok') {
      final host = uri.host.toLowerCase();

      if (host == 'vm.tiktok.com' || host == 'vt.tiktok.com') {
        return segments.isNotEmpty;
      }

      return segments.length >= 3 &&
          segments[0].startsWith('@') &&
          segments[1] == 'video' &&
          segments[2].isNotEmpty;
    }

    return false;
  }

  static String platformLabel(String value) {
    switch (detectPlatform(value)) {
      case 'tiktok':
        return 'TikTok';
      case 'instagram':
        return 'Instagram';
      default:
        return 'Social Media';
    }
  }
}
