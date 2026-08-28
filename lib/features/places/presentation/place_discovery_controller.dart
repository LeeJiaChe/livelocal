import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../services/location_service.dart';
import '../domain/external_place.dart';
import '../domain/place_provider.dart';

class PlaceDiscoveryController with ChangeNotifier {
  PlaceDiscoveryController({
    required PlaceProvider provider,
    CurrentLocationService? locationService,
  })  : _provider = provider,
        _locationService = locationService ?? LocationService();

  final PlaceProvider _provider;
  final CurrentLocationService _locationService;
  final List<ExternalPlace> _places = [];
  Timer? _debounce;
  int _requestId = 0;
  String _query = '';
  String? _category;
  String? _nextPageToken;
  String? _errorMessage;
  LocationRequestFailure? _locationFailure;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isNearby = false;

  List<ExternalPlace> get places => List.unmodifiable(_places);
  String get query => _query;
  String? get category => _category;
  String? get errorMessage => _errorMessage;
  LocationRequestFailure? get locationFailure => _locationFailure;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isNearby => _isNearby;
  bool get canLoadMore => !_isNearby && _nextPageToken != null;

  void updateQuery(String value) {
    _query = value.trim();
    _isNearby = false;
    _locationFailure = null;
    _debounce?.cancel();
    // Invalidate an in-flight response as soon as the text changes, rather
    // than allowing the previous query to paint during the debounce window.
    _requestId += 1;
    _places.clear();
    _nextPageToken = null;
    _errorMessage = null;
    _isLoadingMore = false;
    if (_query.length < 2) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _debounce = Timer(const Duration(milliseconds: 450), search);
    notifyListeners();
  }

  Future<void> selectCategory(String? value) async {
    _category = value;
    if (_isNearby) {
      await nearby();
    } else if (_query.length >= 2) {
      await search();
    } else {
      notifyListeners();
    }
  }

  Future<void> search([String? submittedQuery]) async {
    _debounce?.cancel();
    if (submittedQuery != null) _query = submittedQuery.trim();
    if (_query.length < 2) return;
    final requestId = ++_requestId;
    _isLoading = true;
    _isNearby = false;
    _errorMessage = null;
    _locationFailure = null;
    _nextPageToken = null;
    notifyListeners();
    try {
      final page = await _provider.search(query: _query, category: _category);
      if (requestId != _requestId) return;
      _places
        ..clear()
        ..addAll(page.places);
      _nextPageToken = page.nextPageToken;
    } catch (error) {
      if (requestId != _requestId) return;
      _places.clear();
      _errorMessage = _message(error, 'Places could not be loaded.');
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    final token = _nextPageToken;
    if (_isLoadingMore || token == null || _query.length < 2) return;
    final requestId = _requestId;
    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final page = await _provider.search(
        query: _query,
        category: _category,
        pageToken: token,
      );
      if (requestId != _requestId) return;
      final identities = _places.map((place) => place.providerIdentity).toSet();
      _places.addAll(
        page.places.where((place) => identities.add(place.providerIdentity)),
      );
      _nextPageToken = page.nextPageToken;
    } catch (error) {
      if (requestId == _requestId) {
        _errorMessage = _message(error, 'More places could not be loaded.');
      }
    } finally {
      if (requestId == _requestId) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> nearby() async {
    _debounce?.cancel();
    final requestId = ++_requestId;
    _isLoading = true;
    _isNearby = true;
    _errorMessage = null;
    _locationFailure = null;
    _nextPageToken = null;
    notifyListeners();
    final location = await _locationService.requestCurrentLocation();
    if (requestId != _requestId) return;
    if (!location.isSuccess) {
      _places.clear();
      _locationFailure = location.failure;
      _errorMessage = location.message;
      _isLoading = false;
      notifyListeners();
      return;
    }
    try {
      final values = await _provider.nearby(
        latitude: location.latitude!,
        longitude: location.longitude!,
        category: _category,
        rankByDistance: true,
      );
      if (requestId != _requestId) return;
      _places
        ..clear()
        ..addAll(values);
    } catch (error) {
      if (requestId != _requestId) return;
      _places.clear();
      _errorMessage = _message(error, 'Nearby places could not be loaded.');
    } finally {
      if (requestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> openRelevantSettings() async {
    if (_locationFailure == LocationRequestFailure.serviceDisabled) {
      await _locationService.openLocationSettings();
    } else if (_locationFailure == LocationRequestFailure.deniedForever) {
      await _locationService.openAppSettings();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _requestId += 1;
    super.dispose();
  }

  String _message(Object error, String fallback) =>
      error is AppException ? error.userMessage : fallback;
}
