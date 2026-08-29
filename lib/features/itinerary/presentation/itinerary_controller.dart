import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/restaurant_model.dart';
import '../../../models/saved_collection_model.dart';
import '../../../models/saved_place_model.dart';
import '../../../models/spot_model.dart';
import '../../../services/location_service.dart';
import '../domain/saved_itinerary_repository.dart';

class ItineraryController with ChangeNotifier {
  ItineraryController({
    required SavedItineraryRepository repository,
    LocationService? locationService,
  })  : _repository = repository,
        _locationService = locationService ?? LocationService();

  final SavedItineraryRepository _repository;
  final LocationService _locationService;
  List<SavedCollectionModel> _collections = [];
  List<SavedCollectionItemModel> _activeCollectionItems = [];
  List<SavedCollectionPlace> _activeCollectionPlaces = [];
  SavedCollectionModel? _activeCollection;
  List<SavedPlaceModel> _savedPlaces = [];
  List<SavedItinerary> _savedItineraries = [];
  List<Map<String, Object>> _itinerarySteps = [];
  bool _isLoading = false;
  bool _isLoadingCollections = false;
  bool _isLoadingCollectionPlaces = false;
  bool _isGeneratingItinerary = false;
  String? _errorMessage;

  List<SavedCollectionModel> get collections => List.unmodifiable(_collections);
  List<SavedCollectionItemModel> get activeCollectionItems =>
      List.unmodifiable(_activeCollectionItems);
  List<SavedCollectionPlace> get activeCollectionPlaces =>
      List.unmodifiable(_activeCollectionPlaces);
  SavedCollectionModel? get activeCollection => _activeCollection;
  List<SavedPlaceModel> get savedPlaces => List.unmodifiable(_savedPlaces);
  List<SavedItinerary> get savedItineraries =>
      List.unmodifiable(_savedItineraries);
  List<Map<String, Object>> get itinerarySteps =>
      List.unmodifiable(_itinerarySteps);
  bool get isLoading => _isLoading;
  bool get isLoadingCollections => _isLoadingCollections;
  bool get isLoadingCollectionPlaces => _isLoadingCollectionPlaces;
  bool get isGeneratingItinerary => _isGeneratingItinerary;
  String? get errorMessage => _errorMessage;
  String? get itineraryError => _errorMessage;

  void setActiveCollection(SavedCollectionModel? collection) {
    final changedCollection = _activeCollection?.id != collection?.id;
    _activeCollection = collection;
    if (collection == null || changedCollection) {
      _activeCollectionItems = [];
      _activeCollectionPlaces = [];
    }
    notifyListeners();
  }

  Future<bool> loadActiveCollection(String collectionId) async {
    _isLoadingCollectionPlaces = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final values = await Future.wait([
        _repository.fetchCollectionPlaces(collectionId),
        _repository.fetchCollectionItems(collectionId),
      ]);
      _activeCollectionPlaces = values[0] as List<SavedCollectionPlace>;
      _activeCollectionItems = values[1] as List<SavedCollectionItemModel>;
      return true;
    } catch (error) {
      _activeCollectionPlaces = [];
      _activeCollectionItems = [];
      _errorMessage = _message(error, 'Collection places could not be loaded.');
      return false;
    } finally {
      _isLoadingCollectionPlaces = false;
      notifyListeners();
    }
  }

  Future<void> loadCollections() async {
    _isLoadingCollections = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _collections = await _repository.fetchCollections();
    } catch (error) {
      _errorMessage = _message(error, 'Collections could not be loaded.');
    } finally {
      _isLoadingCollections = false;
      notifyListeners();
    }
  }

  Future<void> loadActiveCollectionItems(String collectionId) async {
    try {
      _activeCollectionItems =
          await _repository.fetchCollectionItems(collectionId);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _message(error, 'Collection items could not be loaded.');
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadActiveCollectionPlaces(String collectionId) async {
    _isLoadingCollectionPlaces = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _activeCollectionPlaces =
          await _repository.fetchCollectionPlaces(collectionId);
    } catch (error) {
      _errorMessage = _message(error, 'Collection places could not be loaded.');
    } finally {
      _isLoadingCollectionPlaces = false;
      notifyListeners();
    }
  }

  Future<SavedCollectionModel?> createCollection({
    required String name,
    String? description,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final created = await _repository.createCollection(
        name: name,
        description: description,
      );
      await loadCollections();
      return created;
    } catch (error) {
      _errorMessage = _message(error, 'Collection could not be created.');
      notifyListeners();
      return null;
    }
  }

  Future<SavedCollectionModel?> renameCollection({
    required String collectionId,
    required String name,
    String? description,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await _repository.renameCollection(
        collectionId: collectionId,
        name: name,
        description: description,
      );
      await loadCollections();
      if (_activeCollection?.id == collectionId) {
        _activeCollection = updated;
      }
      return updated;
    } catch (error) {
      _errorMessage = _message(error, 'Collection could not be renamed.');
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteCollection(String collectionId) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteCollection(collectionId);
      if (_activeCollection?.id == collectionId) {
        _activeCollection = null;
        _activeCollectionItems = [];
        _activeCollectionPlaces = [];
      }
      await Future.wait([
        loadCollections(),
        loadSavedPlaces(),
      ]);
      return true;
    } catch (error) {
      _errorMessage = _message(error, 'Collection could not be deleted.');
      notifyListeners();
      return false;
    }
  }

  Future<List<String>> fetchPlaceCollectionIds({
    required String targetType,
    required String targetId,
    String? externalProvider,
  }) async {
    return await _repository.fetchPlaceCollectionIds(
      targetType: targetType,
      targetId: targetId,
      externalProvider: externalProvider,
    );
  }

  Future<SetPlaceCollectionsResult> setPlaceCollections({
    required String targetType,
    required String targetId,
    required List<String> collectionIds,
    String? externalProvider,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.setPlaceCollections(
        targetType: targetType,
        targetId: targetId,
        collectionIds: collectionIds,
        externalProvider: externalProvider,
      );
      await Future.wait([
        loadSavedPlaces(),
        loadCollections(),
      ]);
      if (_activeCollection != null) {
        await loadActiveCollection(_activeCollection!.id);
      }
      return result;
    } catch (error) {
      _errorMessage =
          _message(error, 'Could not update collection memberships.');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadSavedPlaces() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final values = await Future.wait([
        _repository.fetchSavedPlaces(),
        _repository.fetchCollections(),
      ]);
      _savedPlaces = values[0] as List<SavedPlaceModel>;
      _collections = values[1] as List<SavedCollectionModel>;
    } catch (error) {
      _errorMessage = _message(error, 'Saved places could not be loaded.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadItineraries() async {
    try {
      _savedItineraries = await _repository.fetchItineraries();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _message(error, 'Saved itineraries could not be loaded.');
    } finally {
      notifyListeners();
    }
  }

  bool isSaved({
    String? spotId,
    String? restaurantId,
    String? googlePlaceId,
  }) {
    return _savedPlaces.any(
      (place) =>
          (spotId != null && place.spotId == spotId) ||
          (restaurantId != null && place.restaurantId == restaurantId) ||
          (googlePlaceId != null &&
              place.externalProvider == 'google' &&
              place.externalPlaceId == googlePlaceId),
    );
  }

  Future<bool> toggleSave({
    String? spotId,
    String? restaurantId,
    String? googlePlaceId,
  }) async {
    if ((spotId == null) == (restaurantId == null)) {
      _errorMessage = 'Choose exactly one place to save.';
      notifyListeners();
      return false;
    }
    final targetType = spotId != null ? 'spot' : 'restaurant';
    final targetId = spotId ?? restaurantId!;
    final currentlySaved = isSaved(
      spotId: spotId,
      restaurantId: restaurantId,
      googlePlaceId: googlePlaceId,
    );

    try {
      if (currentlySaved) {
        // Remove from all collections
        await setPlaceCollections(
          targetType: targetType,
          targetId: targetId,
          collectionIds: const [],
        );
        return true;
      } else {
        // Save to default collection or first collection
        if (_collections.isEmpty) {
          await loadCollections();
        }
        var defaultCol = _collections.firstWhere(
          (c) => c.name.toLowerCase() == 'saved places',
          orElse: () => _collections.isNotEmpty
              ? _collections.first
              : SavedCollectionModel(
                  id: '',
                  userId: '',
                  name: 'Saved places',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
        );
        if (defaultCol.id.isEmpty) {
          final created = await _repository.createCollection(
            name: 'Saved places',
            description: 'Default collection for your saved places',
          );
          defaultCol = created;
          await loadCollections();
        }
        await setPlaceCollections(
          targetType: targetType,
          targetId: targetId,
          collectionIds: [defaultCol.id],
        );
        return true;
      }
    } catch (error) {
      _errorMessage = _message(
        error,
        'The saved-place change could not be completed.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveExternalToDefaultCollection({
    required String provider,
    required String placeId,
  }) async {
    try {
      if (_collections.isEmpty) await loadCollections();
      var defaultCollection = _collections.firstWhere(
        (collection) => collection.name.toLowerCase() == 'saved places',
        orElse: () => _collections.isNotEmpty
            ? _collections.first
            : SavedCollectionModel(
                id: '',
                userId: '',
                name: 'Saved places',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
      );
      if (defaultCollection.id.isEmpty) {
        defaultCollection = await _repository.createCollection(
          name: 'Saved places',
          description: 'Default collection for your saved places',
        );
      }
      await setPlaceCollections(
        targetType: 'external',
        targetId: placeId,
        externalProvider: provider,
        collectionIds: [defaultCollection.id],
      );
      return true;
    } catch (error) {
      _errorMessage = _message(
        error,
        'The external place could not be added to your trip.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<RouteOrigin?> requestDeviceOrigin() async {
    _errorMessage = null;
    final position = await _locationService.getCurrentLocation();
    if (position == null) {
      _errorMessage =
          'Location is unavailable. Choose a city manually or review device permission settings.';
      notifyListeners();
      return null;
    }
    return RouteOrigin(
      label: 'Current location',
      latitude: position.latitude,
      longitude: position.longitude,
      mode: 'device',
    );
  }

  Future<bool> generateAndSaveItinerary({
    required String title,
    required RouteOrigin origin,
    String? cityFilter,
    String? collectionId,
    List<SpotModel>? allSpots,
    List<RestaurantModel>? allRestaurants,
  }) async {
    _isGeneratingItinerary = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final candidates = await _repository.fetchSavedRouteCandidates(
        collectionId: collectionId,
      );

      final filteredCandidates = candidates.where((candidate) {
        if (candidate.latitude == 0.0 && candidate.longitude == 0.0) {
          return false;
        }
        if (cityFilter != null && cityFilter != 'All') {
          return candidate.city.trim().toLowerCase() ==
              cityFilter.trim().toLowerCase();
        }
        return true;
      }).toList();

      final candidateCount = candidates.length;
      if (filteredCandidates.isEmpty) {
        throw const AppException(
          code: AppErrorCode.validation,
          userMessage:
              'None of the saved places in this plan currently has verified coordinates.',
        );
      }

      final sorted = _locationService.sortCandidatesByProximity(
        origin.latitude,
        origin.longitude,
        filteredCandidates,
      );
      final targets = sorted.map((candidate) {
        return ItineraryTarget(
          type: candidate.targetType,
          id: candidate.targetId,
          provider: candidate.externalProvider,
        );
      }).toList();

      await _repository.saveLocationPreference(origin);
      await _repository.createItinerary(
        title: title,
        origin: origin,
        orderedTargets: targets,
      );
      _itinerarySteps = _buildCandidateSteps(sorted);
      await loadItineraries();
      if (targets.length < candidateCount) {
        _errorMessage =
            '${candidateCount - targets.length} place(s) without verified coordinates were omitted.';
      }
      return true;
    } catch (error) {
      _itinerarySteps = [];
      _errorMessage = _message(error, 'The itinerary could not be created.');
      return false;
    } finally {
      _isGeneratingItinerary = false;
      notifyListeners();
    }
  }

  List<Map<String, Object>> _buildCandidateSteps(
    List<SavedRouteCandidate> sorted,
  ) {
    return List.generate(sorted.length, (index) {
      final stop = sorted[index];
      if (stop.isSpot) {
        return {
          'title': stop.name,
          'location': stop.address.isNotEmpty
              ? stop.address
              : '${stop.city}, ${stop.state}',
          'best_time': stop.bestTime ?? 'Anytime',
          'activity': stop.thingsToDo ?? 'Explore spot',
          'type': 'Spot (${stop.categoryOrCuisine})',
          'step': 'Stop ${index + 1}',
          'lat': stop.latitude,
          'lng': stop.longitude,
          'area': stop.city,
          'provider': stop.externalProvider ?? '',
          'place_id': stop.targetId,
          if (index == 0) 'day_label': 'Route overview',
        };
      }
      if (stop.isExternal) {
        final localContext = <String>[
          if (stop.reviewedDishes?.trim().isNotEmpty == true)
            'Local pick: ${stop.reviewedDishes}',
          if (stop.thingsToDo?.trim().isNotEmpty == true) stop.thingsToDo!,
        ];
        final hasEat = stop.reviewedDishes?.trim().isNotEmpty == true;
        final hasSpot = stop.thingsToDo?.trim().isNotEmpty == true ||
            stop.bestTime?.trim().isNotEmpty == true;
        return {
          'title': stop.name,
          'location': stop.address,
          'best_time': stop.bestTime?.trim().isNotEmpty == true
              ? stop.bestTime!
              : 'Check current opening hours',
          'activity': localContext.isEmpty
              ? 'Basic place information'
              : localContext.join(' · '),
          'type': hasEat && hasSpot
              ? 'Eat + Things to Do (${stop.categoryOrCuisine})'
              : hasEat
                  ? 'Eat (${stop.categoryOrCuisine})'
                  : hasSpot
                      ? 'Things to Do (${stop.categoryOrCuisine})'
                      : 'Google Place (${stop.categoryOrCuisine})',
          'step': 'Stop ${index + 1}',
          'lat': stop.latitude,
          'lng': stop.longitude,
          'area': stop.city,
          'provider': stop.externalProvider ?? '',
          'place_id': stop.targetId,
          if (index == 0) 'day_label': 'Route overview',
        };
      }
      return {
        'title': stop.name,
        'location': stop.address.isNotEmpty
            ? stop.address
            : '${stop.city}, ${stop.state}',
        'best_time': 'Meal stop',
        'activity':
            stop.reviewedDishes != null && stop.reviewedDishes!.isNotEmpty
                ? 'Try: ${stop.reviewedDishes}'
                : 'Meal stop',
        'type': 'Restaurant (${stop.categoryOrCuisine})',
        'step': 'Stop ${index + 1}',
        'lat': stop.latitude,
        'lng': stop.longitude,
        'area': stop.city,
        'provider': stop.externalProvider ?? '',
        'place_id': stop.targetId,
        if (index == 0) 'day_label': 'Route overview',
      };
    });
  }

  String _message(Object error, String fallback) {
    return error is AppException ? error.userMessage : fallback;
  }
}
