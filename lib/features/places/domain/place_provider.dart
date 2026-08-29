import 'external_place.dart';
import 'place_enrichment.dart';

abstract interface class PlaceProvider {
  Future<ExternalPlacePage> search({
    required String query,
    String? category,
    String? pageToken,
  });

  Future<List<ExternalPlace>> nearby({
    required double latitude,
    required double longitude,
    double radius = 5000,
    String? category,
    bool rankByDistance = false,
  });

  Future<ExternalPlace> details(String placeId);

  Future<Map<String, PlaceEnrichment>> enrichments(
    Iterable<String> placeIds,
  );
}
