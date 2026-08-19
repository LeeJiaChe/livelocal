import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/restaurant_model.dart';
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
  List<SavedPlaceModel> _savedPlaces = [];
  List<SavedItinerary> _savedItineraries = [];
  List<Map<String, Object>> _itinerarySteps = [];
  bool _isLoading = false;
  bool _isGeneratingItinerary = false;
  String? _errorMessage;
  String? _selectedAlbum;
  Set<String> _availableAlbums = {};

  List<SavedPlaceModel> get savedPlaces => List.unmodifiable(_savedPlaces);
  List<SavedItinerary> get savedItineraries =>
      List.unmodifiable(_savedItineraries);
  List<Map<String, Object>> get itinerarySteps =>
      List.unmodifiable(_itinerarySteps);
  bool get isLoading => _isLoading;
  bool get isGeneratingItinerary => _isGeneratingItinerary;
  String? get errorMessage => _errorMessage;
  String? get itineraryError => _errorMessage;
  String? get selectedAlbum => _selectedAlbum;
  Set<String> get availableAlbums => Set.unmodifiable(_availableAlbums);

  Future<void> loadSavedPlaces() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _savedPlaces = await _repository.fetchSavedPlaces();
      _extractAvailableAlbums();
      if (_selectedAlbum != null && !_availableAlbums.contains(_selectedAlbum)) {
        _selectedAlbum = null;
      }
    } catch (error) {
      _errorMessage = _message(error, 'Saved places could not be loaded.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _extractAvailableAlbums() {
    final albums = <String>{};
    for (final place in _savedPlaces) {
      if (place.spotId != null || place.restaurantId != null) {
        albums.add('All');
      }
    }
    _availableAlbums = albums;
  }

  void setAlbumFilter(String? album) {
    _selectedAlbum = album;
    notifyListeners();
  }

  List<SavedPlaceModel> get filteredSavedPlaces {
    if (_selectedAlbum == null || _selectedAlbum == 'All') {
      return _savedPlaces;
    }
    return _savedPlaces.where((place) {
      if (place.spotId != null) {
        return false;
      }
      if (place.restaurantId != null) {
        return false;
      }
      return true;
    }).toList();
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
    final currentlySaved = isSaved(
      spotId: spotId,
      restaurantId: restaurantId,
    );
    try {
      await _repository.setSaved(
        targetType: spotId == null ? 'restaurant' : 'spot',
        targetId: spotId ?? restaurantId!,
        saved: !currentlySaved,
      );
      await loadSavedPlaces();
      return true;
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
  }) async {
    _isGeneratingItinerary = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final placesToUse = _selectedAlbum == null || _selectedAlbum == 'All'
          ? _savedPlaces
          : filteredSavedPlaces;
      final savedSpots = placesToUse
          .where((saved) => saved.spotId != null)
          .map(
            (saved) => allSpots.where((spot) => spot.id == saved.spotId),
          )
          .where((matches) => matches.isNotEmpty)
          .map((matches) => matches.first)
          .where((spot) => spot.latitude != null && spot.longitude != null)
          .toList();
      final savedRestaurants = placesToUse
          .where((saved) => saved.restaurantId != null)
          .map(
            (saved) => allRestaurants
                .where((restaurant) => restaurant.id == saved.restaurantId),
          )
          .where((matches) => matches.isNotEmpty)
          .map((matches) => matches.first)
          .where(
            (restaurant) =>
                restaurant.latitude != null && restaurant.longitude != null,
          )
          .toList();
      final savedCount = placesToUse.length;
      if (savedSpots.isEmpty && savedRestaurants.isEmpty) {
        throw const AppException(
          code: AppErrorCode.validation,
          userMessage:
              'None of your saved places currently has verified map coordinates.',
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
      if (targets.length < savedCount) {
        _errorMessage =
            '${savedCount - targets.length} saved place(s) without verified coordinates were omitted.';
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
          'location': spot.address,
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
        'location': restaurant.address,
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
