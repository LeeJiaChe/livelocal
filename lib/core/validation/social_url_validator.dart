enum SocialSourceType { post, profile, unsupported }

class SocialSourceDetection {
  const SocialSourceDetection({
    required this.type,
    this.platform,
  });

  final SocialSourceType type;
  final String? platform;
}

class SocialUrlValidator {
  static const supportedPlatforms = {
    'tiktok',
    'instagram',
  };

  static bool isSupported(
    String value, {
    String? platform,
  }) {
    final detected = detectSource(value);
    if (detected.type == SocialSourceType.unsupported) return false;
    return platform == null ||
        detected.platform == platform.trim().toLowerCase();
  }

  static SocialSourceType detectSourceType(String value) =>
      detectSource(value).type;

  static SocialSourceDetection detectSource(String value) {
    final uri = _safeUri(value);
    if (uri == null) {
      return const SocialSourceDetection(type: SocialSourceType.unsupported);
    }

    final platform = _platformForHost(uri.host.toLowerCase());
    if (platform == null) {
      return const SocialSourceDetection(type: SocialSourceType.unsupported);
    }

    final segments = uri.pathSegments
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);

    if (platform == 'instagram') {
      if (segments.length == 2 &&
          const {'p', 'reel', 'reels', 'tv'}.contains(segments.first)) {
        return const SocialSourceDetection(
          type: SocialSourceType.post,
          platform: 'instagram',
        );
      }
      if (segments.length == 1 &&
          !_instagramReserved.contains(segments[0].toLowerCase())) {
        return const SocialSourceDetection(
          type: SocialSourceType.profile,
          platform: 'instagram',
        );
      }
    }

    if (platform == 'tiktok') {
      final host = uri.host.toLowerCase();
      if ((host == 'vm.tiktok.com' || host == 'vt.tiktok.com') &&
          segments.length == 1) {
        return const SocialSourceDetection(
          type: SocialSourceType.post,
          platform: 'tiktok',
        );
      }
      if (segments.length == 3 &&
          segments[0].startsWith('@') &&
          segments[0].length > 1 &&
          segments[1] == 'video' &&
          segments[2].isNotEmpty) {
        return const SocialSourceDetection(
          type: SocialSourceType.post,
          platform: 'tiktok',
        );
      }
      if (segments.length == 1 &&
          segments.first.startsWith('@') &&
          segments.first.length > 1) {
        return const SocialSourceDetection(
          type: SocialSourceType.profile,
          platform: 'tiktok',
        );
      }
    }

    return const SocialSourceDetection(type: SocialSourceType.unsupported);
  }

  static String? detectPlatform(String value) {
    final uri = _safeUri(value);
    return uri == null ? null : _platformForHost(uri.host.toLowerCase());
  }

  static bool isReviewPost(String value) =>
      detectSourceType(value) == SocialSourceType.post;

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

  static Uri? _safeUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return uri;
  }

  static String? _platformForHost(String host) {
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

  static const _instagramReserved = {
    'about',
    'accounts',
    'developer',
    'directory',
    'explore',
    'legal',
    'p',
    'privacy',
    'reel',
    'reels',
    'stories',
    'terms',
    'tv',
  };
}
