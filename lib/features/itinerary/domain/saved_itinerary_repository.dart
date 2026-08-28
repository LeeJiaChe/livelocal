import '../../../models/saved_collection_model.dart';
import '../../../models/saved_place_model.dart';

class RouteOrigin {
  const RouteOrigin({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.mode,
    this.state,
    this.city,
  });

  final String label;
  final double latitude;
  final double longitude;
  final String mode;
  final String? state;
  final String? city;
}

class ItineraryTarget {
  const ItineraryTarget({required this.type, required this.id, this.provider});

  final String type;
  final String id;
  final String? provider;

  Map<String, String> toMap() => {
        'type': type,
        'id': id,
        if (provider != null) 'provider': provider!,
      };
}

class SavedItinerary {
  const SavedItinerary({
    required this.id,
    required this.title,
    required this.originLabel,
    required this.version,
    required this.createdAt,
    required this.targets,
  });

  final String id;
  final String title;
  final String originLabel;
  final int version;
  final DateTime createdAt;
  final List<ItineraryTarget> targets;
}

abstract interface class SavedItineraryRepository {
  // Collections
  Future<List<SavedCollectionModel>> fetchCollections();
  Future<SavedCollectionModel> createCollection({
    required String name,
    String? description,
  });
  Future<SavedCollectionModel> renameCollection({
    required String collectionId,
    required String name,
    String? description,
  });
  Future<void> deleteCollection(String collectionId);
  Future<List<SavedCollectionItemModel>> fetchCollectionItems(
    String collectionId,
  );
  Future<List<SavedCollectionPlace>> fetchCollectionPlaces(
    String collectionId,
  );
  Future<List<String>> fetchPlaceCollectionIds({
    required String targetType,
    required String targetId,
    String? externalProvider,
  });
  Future<SetPlaceCollectionsResult> setPlaceCollections({
    required String targetType,
    required String targetId,
    required List<String> collectionIds,
    String? externalProvider,
  });

  Future<List<SavedRouteCandidate>> fetchSavedRouteCandidates({
    String? collectionId,
  });

  // Places
  Future<List<SavedPlaceModel>> fetchSavedPlaces();
  Future<bool> setSaved({
    required String targetType,
    required String targetId,
    required bool saved,
    String? externalProvider,
  });

  // Itineraries
  Future<List<SavedItinerary>> fetchItineraries();
  Future<SavedItinerary> createItinerary({
    required String title,
    required RouteOrigin origin,
    required List<ItineraryTarget> orderedTargets,
  });

  Future<void> saveLocationPreference(RouteOrigin origin);
}
