import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/core/validation/social_url_validator.dart';

void main() {
  group('SocialUrlValidator source detection', () {
    test('recognises TikTok videos and short links as posts', () {
      expect(
        SocialUrlValidator.detectSourceType(
          'https://www.tiktok.com/@creator/video/123456789',
        ),
        SocialSourceType.post,
      );
      expect(
        SocialUrlValidator.detectSourceType('https://vm.tiktok.com/ZM123/'),
        SocialSourceType.post,
      );
    });

    test('recognises a normal TikTok creator profile', () {
      expect(
        SocialUrlValidator.detectSourceType(
          'https://www.tiktok.com/@localfoodie/',
        ),
        SocialSourceType.profile,
      );
    });

    test('recognises Instagram posts and Reels', () {
      expect(
        SocialUrlValidator.detectSourceType(
          'https://www.instagram.com/p/ABC123/',
        ),
        SocialSourceType.post,
      );
      expect(
        SocialUrlValidator.detectSourceType(
          'https://instagram.com/reel/REEL123/',
        ),
        SocialSourceType.post,
      );
    });

    test('recognises a normal Instagram creator profile', () {
      expect(
        SocialUrlValidator.detectSourceType(
          'https://www.instagram.com/klfoodie/',
        ),
        SocialSourceType.profile,
      );
    });

    test('rejects unsupported and deceptive domains', () {
      for (final value in [
        'not a url',
        'https://example.com/@creator',
        'https://instagram.com.evil.test/p/ABC',
        'http://www.tiktok.com/@creator/video/123',
        'https://instagram.com/reel/ABC/extra',
        'https://www.tiktok.com/@creator/video/123/extra',
      ]) {
        expect(
          SocialUrlValidator.detectSourceType(value),
          SocialSourceType.unsupported,
          reason: value,
        );
      }
    });

    test('profile URLs cannot be stored as final review URLs', () {
      expect(
        SocialUrlValidator.isReviewPost(
          'https://www.instagram.com/klfoodie/',
        ),
        isFalse,
      );
      expect(
        SocialUrlValidator.isReviewPost(
          'https://www.tiktok.com/@localfoodie/',
        ),
        isFalse,
      );
    });
  });
}
