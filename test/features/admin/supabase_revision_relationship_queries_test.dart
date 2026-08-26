import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:live_local/features/guides/data/supabase_guide_repository.dart';
import 'package:live_local/features/restaurants/data/supabase_local_eats_repository.dart';
import 'package:live_local/features/spots/data/supabase_spot_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('admin revision relationship queries', () {
    test('Spot repository selects the revision parent through its FK',
        () async {
      late http.Request request;
      final client = _client((incoming) {
        request = incoming;
        return [
          {
            'id': 'spot-revision-1',
            'status': 'submitted',
            'name': 'Local place',
            'category': 'Nature',
            'description': 'A detailed local place.',
            'state': 'Penang',
            'city': 'George Town',
            'address': '1 Local Road',
            'price_range': r'$',
            'best_time': 'Morning',
            'things_to_do': 'Walk',
            'image_path': null,
            'author_id': 'author-1',
            'parent': {'id': 'spot-1', 'moderation_version': 4},
          },
        ];
      });
      addTearDown(client.dispose);

      final rows =
          await SupabaseSpotRepository(client).fetchPendingModeration();

      expect(
        request.url.queryParameters['select']?.replaceAll(' ', ''),
        SupabaseSpotRepository.pendingModerationSelect.replaceAll(' ', ''),
      );
      expect(request.url.queryParameters['select'], contains('parent:spots!'));
      expect(
        request.url.queryParameters['select'],
        contains('spot_revisions_spot_id_fkey'),
      );
      expect(rows.single.id, 'spot-1');
      expect(rows.single.moderationVersion, 4);
    });

    test('Restaurant repository selects the revision parent through its FK',
        () async {
      late http.Request request;
      final client = _client((incoming) {
        request = incoming;
        return [
          {
            'id': 'restaurant-revision-1',
            'status': 'under_review',
            'name': 'Local Kitchen',
            'address': '2 Food Street',
            'state': 'Selangor',
            'city': 'Petaling Jaya',
            'cuisine_type': 'Malaysian',
            'price_range': r'$$',
            'reviewed_dishes': 'Nasi lemak',
            'social_media_url': 'https://www.tiktok.com/@local/video/123',
            'cover_image_path': null,
            'ai_assisted': false,
            'parent': {
              'id': 'restaurant-1',
              'moderation_version': 2,
              'owner_id': 'creator-1',
            },
          },
        ];
      });
      addTearDown(client.dispose);

      final rows =
          await SupabaseLocalEatsRepository(client).fetchPendingRestaurants();

      expect(
        request.url.queryParameters['select']?.replaceAll(' ', ''),
        SupabaseLocalEatsRepository.pendingModerationSelect.replaceAll(' ', ''),
      );
      expect(
        request.url.queryParameters['select'],
        contains('restaurant_revisions_restaurant_id_fkey'),
      );
      expect(rows.single.id, 'restaurant-1');
      expect(rows.single.influencerId, 'creator-1');
    });

    test('Guide repository selects the revision parent through its FK',
        () async {
      late http.Request request;
      final client = _client((incoming) {
        request = incoming;
        return [
          {
            'id': 'guide-revision-1',
            'status': 'submitted',
            'title': 'Neighbourhood walk',
            'location_name': 'Bangsar',
            'state': 'Kuala Lumpur',
            'route_overview': 'A compact local route.',
            'stops': ['Market', 'Park'],
            'walking_sequence': ['Market', 'Park'],
            'stop_details': <Object>[],
            'estimated_duration': '2 hours',
            'parent': {'id': 'guide-1', 'version': 3},
          },
        ];
      });
      addTearDown(client.dispose);

      final rows = await SupabaseGuideRepository(client).fetchAdminDrafts();

      expect(
        request.url.queryParameters['select']?.replaceAll(' ', ''),
        SupabaseGuideRepository.adminDraftsSelect.replaceAll(' ', ''),
      );
      expect(
        request.url.queryParameters['select'],
        contains('guide_revisions_guide_id_fkey'),
      );
      expect(rows.single.id, 'guide-1');
      expect(rows.single.version, 3);
    });
  });
}

SupabaseClient _client(
  List<Map<String, Object?>> Function(http.Request request) response,
) {
  return SupabaseClient(
    'https://example.supabase.co',
    'test-publishable-key',
    httpClient: MockClient((request) async {
      return http.Response(
        jsonEncode(response(request)),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
}
