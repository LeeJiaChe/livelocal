import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/saved_collection_model.dart';
import '../../../models/saved_place_model.dart';
import '../domain/saved_itinerary_repository.dart';

class SupabaseSavedItineraryRepository implements SavedItineraryRepository {
  SupabaseSavedItineraryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<SavedCollectionModel>> fetchCollections() async {
    try {
      final response = await _client.rpc('list_my_saved_collections');
      final list = (response as List<dynamic>?) ?? [];
      final results = <SavedCollectionModel>[];
      for (final raw in list) {
        final row = Map<String, dynamic>.from(raw as Map);
        final model = SavedCollectionModel.fromMap(row);
        final signedCover = await _resolveImage(
          model.coverImagePath,
          model.coverTargetType,
        );
        results.add(model.copyWith(
            coverImageUrl:
                signedCover.isNotEmpty ? signedCover : model.coverImageUrl));
      }
      return results;
    } on PostgrestException catch (error) {
      throw _error(error, 'Saved collections could not be loaded.');
    }
  }

  @override
  Future<SavedCollectionModel> createCollection({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _client.rpc(
        'create_saved_collection',
        params: {
          'p_name': name.trim(),
          'p_description': description?.trim(),
        },
      );
      final row = Map<String, dynamic>.from(response as Map);
      return SavedCollectionModel.fromMap(row);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const AppException(
          code: AppErrorCode.conflict,
          userMessage: 'A collection with this name already exists.',
        );
      }
      throw _error(error, 'The collection could not be created.');
    }
  }

  @override
  Future<SavedCollectionModel> renameCollection({
    required String collectionId,
    required String name,
    String? description,
  }) async {
    try {
      final response = await _client.rpc(
        'rename_saved_collection',
        params: {
          'p_collection_id': collectionId,
          'p_name': name.trim(),
          'p_description': description?.trim(),
        },
      );
      final row = Map<String, dynamic>.from(response as Map);
      return SavedCollectionModel.fromMap(row);
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const AppException(
          code: AppErrorCode.conflict,
          userMessage: 'A collection with this name already exists.',
        );
      }
      throw _error(error, 'The collection could not be updated.');
    }
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    try {
      await _client.rpc(
        'delete_saved_collection',
        params: {
          'p_collection_id': collectionId,
        },
      );
    } on PostgrestException catch (error) {
      throw _error(error, 'The collection could not be deleted.');
    }
  }

  @override
  Future<List<SavedCollectionItemModel>> fetchCollectionItems(
    String collectionId,
  ) async {
    try {
      final rows = await _client
          .from('saved_collection_items')
          .select('*, saved_places(spot_id, restaurant_id)')
          .eq('collection_id', collectionId)
          .order('added_at', ascending: false);

      return (rows as List<dynamic>).map((raw) {
        final row = Map<String, dynamic>.from(raw as Map);
        final sp = row['saved_places'] != null
            ? Map<String, dynamic>.from(row['saved_places'] as Map)
            : <String, dynamic>{};
        row['spot_id'] = sp['spot_id'];
        row['restaurant_id'] = sp['restaurant_id'];
        return SavedCollectionItemModel.fromMap(row);
      }).toList();
    } on PostgrestException catch (error) {
      throw _error(error, 'Collection items could not be loaded.');
    }
  }

  @override
  Future<List<SavedCollectionPlace>> fetchCollectionPlaces(
    String collectionId,
  ) async {
    try {
      final response = await _client.rpc(
        'fetch_collection_places',
        params: {'p_collection_id': collectionId},
      );
      final list = (response as List<dynamic>?) ?? [];
      final results = <SavedCollectionPlace>[];
      for (final raw in list) {
        final row = Map<String, dynamic>.from(raw as Map);
        final place = SavedCollectionPlace.fromMap(row);
        final signedUrl = await _resolveImage(
          place.imageUrl,
          place.targetType,
        );
        results.add(
          SavedCollectionPlace(
            savedPlaceId: place.savedPlaceId,
            targetType: place.targetType,
            targetId: place.targetId,
            name: place.name,
            state: place.state,
            city: place.city,
            categoryOrCuisine: place.categoryOrCuisine,
            priceRange: place.priceRange,
            imageUrl: signedUrl.isNotEmpty ? signedUrl : place.imageUrl,
            rating: place.rating,
            reviewCount: place.reviewCount,
            addedAt: place.addedAt,
          ),
        );
      }
      return results;
    } on PostgrestException catch (error) {
      throw _error(error, 'Collection places could not be loaded.');
    }
  }

  @override
  Future<List<String>> fetchPlaceCollectionIds({
    required String targetType,
    required String targetId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return const [];

      final spFilter = targetType == 'spot'
          ? 'spot_id.eq.$targetId'
          : 'restaurant_id.eq.$targetId';

      final rows = await _client
          .from('saved_collection_items')
          .select('collection_id, saved_places!inner(user_id)')
          .eq('saved_places.user_id', userId)
          .or(spFilter, referencedTable: 'saved_places');

      return (rows as List<dynamic>)
          .map((r) => r['collection_id'] as String)
          .toList();
    } on PostgrestException catch (error) {
      throw _error(error, 'Collection memberships could not be loaded.');
    }
  }

  @override
  Future<SetPlaceCollectionsResult> setPlaceCollections({
    required String targetType,
    required String targetId,
    required List<String> collectionIds,
  }) async {
    try {
      final response = await _client.rpc(
        'set_place_collections',
        params: {
          'p_target_type': targetType,
          'p_target_id': targetId,
          'p_collection_ids': collectionIds,
        },
      );
      final map = Map<String, dynamic>.from(response as Map);
      return SetPlaceCollectionsResult.fromMap(map);
    } on PostgrestException catch (error) {
      throw _error(error, 'The collection could not be updated.');
    }
  }

  @override
  Future<List<SavedRouteCandidate>> fetchSavedRouteCandidates({
    String? collectionId,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (collectionId != null && collectionId.isNotEmpty) {
        params['p_collection_id'] = collectionId;
      }
      final response = await _client.rpc(
        'fetch_saved_route_candidates',
        params: params,
      );
      final list = (response as List<dynamic>?) ?? [];
      final results = <SavedRouteCandidate>[];
      for (final raw in list) {
        final row = Map<String, dynamic>.from(raw as Map);
        final candidate = SavedRouteCandidate.fromMap(row);
        final signedUrl = await _resolveImage(
          candidate.imageUrl,
          candidate.targetType,
        );
        results.add(
          SavedRouteCandidate(
            savedPlaceId: candidate.savedPlaceId,
            targetType: candidate.targetType,
            targetId: candidate.targetId,
            name: candidate.name,
            state: candidate.state,
            city: candidate.city,
            latitude: candidate.latitude,
            longitude: candidate.longitude,
            categoryOrCuisine: candidate.categoryOrCuisine,
            bestTime: candidate.bestTime,
            thingsToDo: candidate.thingsToDo,
            reviewedDishes: candidate.reviewedDishes,
            priceRange: candidate.priceRange,
            imageUrl: signedUrl.isNotEmpty ? signedUrl : candidate.imageUrl,
            rating: candidate.rating,
            reviewCount: candidate.reviewCount,
          ),
        );
      }
      return results;
    } on PostgrestException catch (error) {
      throw _error(error, 'Saved route candidates could not be loaded.');
    }
  }

  @override
  Future<List<SavedPlaceModel>> fetchSavedPlaces() async {
    try {
      final rows = await _client
          .from('saved_places')
          .select()
          .order('saved_at', ascending: false);
      return rows.map(SavedPlaceModel.fromMap).toList();
    } on PostgrestException catch (error) {
      throw _error(error, 'Saved places could not be loaded.');
    }
  }

  @override
  Future<bool> setSaved({
    required String targetType,
    required String targetId,
    required bool saved,
  }) async {
    try {
      final response = await _client.rpc('set_saved_place', params: {
        'p_target_type': targetType,
        'p_target_id': targetId,
        'p_saved': saved,
      });
      return Map<String, dynamic>.from(response as Map)['saved'] as bool;
    } on PostgrestException catch (error) {
      throw _error(error, 'The saved-place change could not be completed.');
    }
  }

  @override
  Future<List<SavedItinerary>> fetchItineraries() async {
    try {
      final rows = await _client
          .from('itineraries')
          .select('*, itinerary_items(*)')
          .isFilter('archived_at', null)
          .order('updated_at', ascending: false);
      return rows.map((row) {
        final items = (row['itinerary_items'] as List<dynamic>? ?? [])
            .map((raw) => Map<String, dynamic>.from(raw as Map))
            .toList()
          ..sort(
            (left, right) =>
                (left['position'] as num).compareTo(right['position'] as num),
          );
        return SavedItinerary(
          id: row['id'] as String,
          title: row['title'] as String,
          originLabel: row['origin_label'] as String,
          version: (row['version'] as num).toInt(),
          createdAt: DateTime.parse(row['created_at'] as String),
          targets: items
              .map(
                (item) => ItineraryTarget(
                  type: item['spot_id'] == null ? 'restaurant' : 'spot',
                  id: (item['spot_id'] ?? item['restaurant_id']) as String,
                ),
              )
              .toList(),
        );
      }).toList();
    } on PostgrestException catch (error) {
      throw _error(error, 'Saved itineraries could not be loaded.');
    }
  }

  @override
  Future<SavedItinerary> createItinerary({
    required String title,
    required RouteOrigin origin,
    required List<ItineraryTarget> orderedTargets,
  }) async {
    try {
      final response = await _client.rpc(
        'create_itinerary_from_saved',
        params: {
          'p_title': title,
          'p_origin_label': origin.label,
          'p_origin_latitude': origin.latitude,
          'p_origin_longitude': origin.longitude,
          'p_ordered_targets':
              orderedTargets.map((item) => item.toMap()).toList(),
        },
      );
      final row = Map<String, dynamic>.from(response as Map);
      return SavedItinerary(
        id: row['id'] as String,
        title: row['title'] as String,
        originLabel: origin.label,
        version: (row['version'] as num).toInt(),
        createdAt: DateTime.parse(row['created_at'] as String),
        targets: List.unmodifiable(orderedTargets),
      );
    } on PostgrestException catch (error) {
      throw _error(error, 'The itinerary could not be saved.');
    }
  }

  @override
  Future<void> saveLocationPreference(RouteOrigin origin) async {
    try {
      await _client.rpc('update_my_discovery_location', params: {
        'p_location_mode': origin.mode,
        'p_state': origin.state,
        'p_city': origin.city,
        'p_latitude': origin.latitude,
        'p_longitude': origin.longitude,
        'p_expected_version': null,
      });
    } on PostgrestException catch (error) {
      throw _error(error, 'The location preference could not be saved.');
    }
  }

  Future<String> _resolveImage(String? path, String? targetType) async {
    if (path == null || path.trim().isEmpty) return '';
    final trimmed = path.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      return trimmed;
    }
    final bucket =
        targetType == 'restaurant' ? 'restaurant-images' : 'spot-images';
    try {
      return await _client.storage.from(bucket).createSignedUrl(trimmed, 3600);
    } catch (_) {
      return '';
    }
  }

  AppException _error(PostgrestException error, String message) {
    return AppException(
      code: error.code == '40001'
          ? AppErrorCode.conflict
          : error.code == '42501'
              ? AppErrorCode.forbidden
              : AppErrorCode.unexpected,
      userMessage: error.code == '40001'
          ? 'This item changed. Refresh and try again.'
          : message,
      technicalMessage: error.message,
      cause: error,
    );
  }
}
