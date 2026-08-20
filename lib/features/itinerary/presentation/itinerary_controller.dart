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
    _activeCollection = collection;
    notifyListeners();
    if (collection != null) {
      loadActiveCollectionPlaces(collection.id);
      loadActiveCollectionItems(collection.id);
    } else {
      _activeCollectionItems = [];
      _activeCollectionPlaces = [];
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
  }) async {
    try {
      return await _repository.fetchPlaceCollectionIds(
        targetType: targetType,
        targetId: targetId,
      );
    } catch (_) {
      return const [];
    }
  }

  Future<bool> setPlaceCollections({
    required String targetType,
    required String targetId,
    required List<String> collectionIds,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      final saved = await _repository.setPlaceCollections(
        targetType: targetType,
        targetId: targetId,
        collectionIds: collectionIds,
      );
      await Future.wait([
        loadSavedPlaces(),
        loadCollections(),
      ]);
      if (_activeCollection != null) {
        await Future.wait([
          loadActiveCollectionItems(_activeCollection!.id),
          loadActiveCollectionPlaces(_activeCollection!.id),
        ]);
      }
      return saved;
    } catch (error) {
      _errorMessage =
          _message(error, 'Could not update collection memberships.');
      notifyListeners();
      return false;
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

  bool isSaved({String? spotId, String? restaurantId}) {
    return _savedPlaces.any(
      (place) =>
          (spotId != null && place.spotId == spotId) ||
          (restaurantId != null && place.restaurantId == restaurantId),
    );
  }

  Future<bool> toggleSave({String? spotId, String? restaurantId}) async {
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
    required List<SpotModel> allSpots,
    required List<RestaurantModel> allRestaurants,
    String? cityFilter,
    String? collectionId,
  }) async {
    _isGeneratingItinerary = true;
    _errorMessage = null;
    notifyListeners();
    try {
      List<SavedPlaceModel> candidatePlaces = _savedPlaces;

      if (collectionId != null && collectionId.isNotEmpty) {
        final items = await _repository.fetchCollectionItems(collectionId);
        final placeIds = items.map((i) => i.savedPlaceId).toSet();
        candidatePlaces =
            _savedPlaces.where((sp) => placeIds.contains(sp.id)).toList();
      }

      final savedSpots = candidatePlaces
          .where((saved) => saved.spotId != null)
          .map(
            (saved) => allSpots.where((spot) => spot.id == saved.spotId),
          )
          .where((matches) => matches.isNotEmpty)
          .map((matches) => matches.first)
          .where((spot) {
        if (spot.latitude == null || spot.longitude == null) return false;
        if (cityFilter != null && cityFilter != 'All') {
          return spot.city.trim().toLowerCase() ==
              cityFilter.trim().toLowerCase();
        }
        return true;
      }).toList();

      final savedRestaurants = candidatePlaces
          .where((saved) => saved.restaurantId != null)
          .map(
            (saved) => allRestaurants
                .where((restaurant) => restaurant.id == saved.restaurantId),
          )
          .where((matches) => matches.isNotEmpty)
          .map((matches) => matches.first)
          .where((restaurant) {
        if (restaurant.latitude == null || restaurant.longitude == null) {
          return false;
        }
        if (cityFilter != null && cityFilter != 'All') {
          return restaurant.city.trim().toLowerCase() ==
              cityFilter.trim().toLowerCase();
        }
        return true;
      }).toList();

      final candidateCount = candidatePlaces.length;
      if (savedSpots.isEmpty && savedRestaurants.isEmpty) {
        throw const AppException(
          code: AppErrorCode.validation,
          userMessage:
              'None of the saved places in this plan currently has verified coordinates.',
        );
      }

      final sorted = _locationService.sortLocationsByProximity(
        origin.latitude,
        origin.longitude,
        savedSpots,
        savedRestaurants,
      );
      final targets = sorted.map((stop) {
        final isSpot = stop['type'] == 'Spot';
        final id = isSpot
            ? (stop['item'] as SpotModel).id
            : (stop['item'] as RestaurantModel).id;
        return ItineraryTarget(type: isSpot ? 'spot' : 'restaurant', id: id);
      }).toList();

      await _repository.saveLocationPreference(origin);
      await _repository.createItinerary(
        title: title,
        origin: origin,
        orderedTargets: targets,
      );
      _itinerarySteps = _buildSteps(sorted);
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

  List<Map<String, Object>> _buildSteps(
    List<Map<String, dynamic>> sorted,
  ) {
    return List.generate(sorted.length, (index) {
      final stop = sorted[index];
      final isSpot = stop['type'] == 'Spot';
      final item = stop['item'];
      if (isSpot) {
        final spot = item as SpotModel;
        return {
          'title': spot.name,
          'location': '${spot.city}, ${spot.state}',
          'best_time': spot.bestTime,
          'activity': spot.thingsToDo,
          'type': 'Spot (${spot.category})',
          'step': 'Stop ${index + 1}',
          'lat': stop['lat'] as double,
          'lng': stop['lng'] as double,
          'area': spot.city,
          if (index == 0) 'day_label': 'Route overview',
        };
      }
      final restaurant = item as RestaurantModel;
      return {
        'title': restaurant.name,
        'location': '${restaurant.city}, ${restaurant.state}',
        'best_time': 'Meal stop',
        'activity': 'Try: ${restaurant.reviewedDishes}',
        'type': 'Restaurant (${restaurant.cuisineType})',
        'step': 'Stop ${index + 1}',
        'lat': stop['lat'] as double,
        'lng': stop['lng'] as double,
        'area': restaurant.city,
        if (index == 0) 'day_label': 'Route overview',
      };
    });
  }

  String _message(Object error, String fallback) {
    return error is AppException ? error.userMessage : fallback;
  }
}
