import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/external_place.dart';
import '../domain/place_provider.dart';
import '../domain/place_enrichment.dart';

class SupabaseGooglePlacesProvider implements PlaceProvider {
  SupabaseGooglePlacesProvider(this._client);

  final SupabaseClient _client;
  final Map<String, ExternalPlace> _detailsCache = {};

  @override
  Future<ExternalPlacePage> search({
    required String query,
    String? category,
    String? pageToken,
  }) async {
    final data = await _invoke('search-places', {
      'query': query.trim(),
      if (category != null && category.isNotEmpty) 'category': category,
      if (pageToken != null && pageToken.isNotEmpty) 'pageToken': pageToken,
    });
    return ExternalPlacePage(
      places: _places(data['places']),
      nextPageToken: data['nextPageToken'] as String?,
    );
  }

  @override
  Future<List<ExternalPlace>> nearby({
    required double latitude,
    required double longitude,
    double radius = 5000,
    String? category,
    bool rankByDistance = false,
  }) async {
    final data = await _invoke('nearby-places', {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'ranking': rankByDistance ? 'distance' : 'popularity',
      if (category != null && category.isNotEmpty) 'category': category,
    });
    return _places(data['places']);
  }

  @override
  Future<ExternalPlace> details(String placeId) async {
    final cached = _detailsCache[placeId];
    if (cached != null) return cached;
    final data = await _invoke('place-details', {'placeId': placeId});
    final raw = data['place'];
    if (raw is! Map) throw const FormatException('Place details missing');
    final place = ExternalPlace.fromJson(Map<String, dynamic>.from(raw));
    _detailsCache[placeId] = place;
    return place;
  }

  Future<Map<String, ExternalPlace>> detailsMany(
    Iterable<String> placeIds,
  ) async {
    final requested = placeIds.toSet().toList(growable: false);
    final unresolved = requested
        .where((placeId) => !_detailsCache.containsKey(placeId))
        .toList(growable: false);
    for (var offset = 0; offset < unresolved.length; offset += 20) {
      final end =
          offset + 20 < unresolved.length ? offset + 20 : unresolved.length;
      final batch = unresolved.sublist(offset, end);
      final data = await _invoke('place-details', {'placeIds': batch});
      final rawPlaces = data['places'];
      if (rawPlaces is! List) {
        throw const FormatException('Place details list missing');
      }
      for (final raw in rawPlaces.whereType<Map>()) {
        final place = ExternalPlace.fromJson(Map<String, dynamic>.from(raw));
        _detailsCache[place.placeId] = place;
      }
    }
    final result = <String, ExternalPlace>{};
    for (final placeId in requested) {
      final place = _detailsCache[placeId];
      if (place != null) result[placeId] = place;
    }
    return result;
  }

  @override
  Future<Map<String, PlaceEnrichment>> enrichments(
    Iterable<String> placeIds,
  ) async {
    final ids = placeIds.toSet().take(20).toList(growable: false);
    if (ids.isEmpty) return const {};
    try {
      final response = await _client.rpc(
        'lookup_place_enrichments',
        params: {'p_google_place_ids': ids},
      );
      final rows = response as List<dynamic>? ?? const [];
      final result = <String, PlaceEnrichment>{};
      for (final raw in rows.whereType<Map>()) {
        final value = PlaceEnrichment.fromJson(Map<String, dynamic>.from(raw));
        if (value.googlePlaceId.isNotEmpty) {
          result[value.googlePlaceId] = value;
        }
      }
      return result;
    } on PostgrestException catch (error) {
      throw AppException(
        code: AppErrorCode.unavailable,
        userMessage: 'Local insight could not be loaded right now.',
        technicalMessage: error.message,
        cause: error,
      );
    }
  }

  List<ExternalPlace> _places(Object? raw) {
    if (raw is! List) throw const FormatException('Places list missing');
    final identities = <String>{};
    return raw
        .whereType<Map>()
        .map((value) {
          return ExternalPlace.fromJson(Map<String, dynamic>.from(value));
        })
        .where((place) => identities.add(place.providerIdentity))
        .toList();
  }

  Future<Map<String, dynamic>> _invoke(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.functions
          .invoke(functionName, body: body)
          .timeout(const Duration(seconds: 18));
      if (response.data is! Map) {
        throw const FormatException('Place response is not an object');
      }
      return Map<String, dynamic>.from(response.data as Map);
    } on FunctionException catch (error) {
      throw _functionError(error);
    } on TimeoutException catch (error) {
      throw AppException(
        code: AppErrorCode.network,
        userMessage:
            'Place discovery timed out. Check your connection and retry.',
        cause: error,
      );
    } on FormatException catch (error) {
      throw AppException(
        code: AppErrorCode.unavailable,
        userMessage:
            'Place discovery returned an unreadable response. Please retry.',
        cause: error,
      );
    } catch (error) {
      if (error is AppException) rethrow;
      throw AppException(
        code: AppErrorCode.network,
        userMessage:
            'Places could not be loaded. Check your connection and retry.',
        cause: error,
      );
    }
  }

  AppException _functionError(FunctionException error) {
    String? code;
    final details = error.details;
    if (details is Map) {
      final payload = Map<String, dynamic>.from(details);
      final nested = payload['error'];
      code = nested is Map
          ? nested['code'] as String?
          : payload['code'] as String?;
    }
    return AppException(
      code: error.status == 429
          ? AppErrorCode.conflict
          : error.status == 400
              ? AppErrorCode.validation
              : AppErrorCode.unavailable,
      userMessage: switch (code) {
        'PLACES_NOT_CONFIGURED' =>
          'Real-world place discovery is not configured yet. LiveLocal community content is still available.',
        'PLACES_RATE_LIMITED' =>
          'Place discovery is busy. Please wait a moment and retry.',
        'PLACE_NOT_FOUND' =>
          'This place is no longer available from Google Places.',
        'INVALID_QUERY' => 'Enter at least two characters to search places.',
        _ => 'Google Places is temporarily unavailable. Please retry.',
      },
      technicalMessage: code,
      cause: error,
    );
  }
}

class UnavailablePlaceProvider implements PlaceProvider {
  const UnavailablePlaceProvider();

  AppException get _error => const AppException(
        code: AppErrorCode.unavailable,
        userMessage: 'Real-world place discovery requires the staging backend.',
      );

  @override
  Future<ExternalPlace> details(String placeId) => Future.error(_error);

  @override
  Future<List<ExternalPlace>> nearby({
    required double latitude,
    required double longitude,
    double radius = 5000,
    String? category,
    bool rankByDistance = false,
  }) =>
      Future.error(_error);

  @override
  Future<ExternalPlacePage> search({
    required String query,
    String? category,
    String? pageToken,
  }) =>
      Future.error(_error);

  @override
  Future<Map<String, PlaceEnrichment>> enrichments(
    Iterable<String> placeIds,
  ) async =>
      const {};
}
