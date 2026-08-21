import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/discount_code_model.dart';
import '../../../models/restaurant_model.dart';
import '../domain/generated_restaurant_listing.dart';
import '../domain/local_eats_repository.dart';

class LocalEatsController with ChangeNotifier {
  LocalEatsController({required LocalEatsRepository repository})
      : _repository = repository {
    unawaited(loadData());
  }

  final LocalEatsRepository _repository;
  List<RestaurantModel> _restaurants = [];
  List<RestaurantModel> _pendingRestaurants = [];
  List<RestaurantModel> _ownedRestaurantSubmissions = [];
  List<DiscountCodeModel> _discountCodes = [];
  List<DiscountCodeModel> _ownedDiscounts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedState = 'All';
  String _selectedCuisine = 'All';
  String _selectedBudget = 'All';
  String _searchQuery = '';
  bool _isGeneratingListing = false;
  String? _generationError;
  List<GeneratedRestaurantListing> _generatedCandidates = [];
  GeneratedRestaurantListing? _selectedGeneratedCandidate;
  bool _isConnectingSocialAccount = false;
  String? _socialConnectionError;
  int _generationRequestId = 0;

  List<RestaurantModel> get restaurants => List.unmodifiable(_restaurants);
  List<RestaurantModel> get pendingRestaurants =>
      List.unmodifiable(_pendingRestaurants);
  List<RestaurantModel> get ownedRestaurantSubmissions =>
      List.unmodifiable(_ownedRestaurantSubmissions);
  List<DiscountCodeModel> get discountCodes =>
      List.unmodifiable(_discountCodes);
  List<DiscountCodeModel> get ownedDiscounts =>
      List.unmodifiable(_ownedDiscounts);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedState => _selectedState;
  String get selectedCuisine => _selectedCuisine;
  String get selectedFoodType => 'All';
  String get selectedBudget => _selectedBudget;
  String get searchQuery => _searchQuery;
  bool get hasActiveFilters =>
      _selectedState != 'All' ||
      _selectedCuisine != 'All' ||
      _selectedBudget != 'All' ||
      _searchQuery.isNotEmpty;

  Future<RestaurantModel?> fetchRestaurantById(String restaurantId) async {
    final cached = _restaurants.where((r) => r.id == restaurantId).firstOrNull;
    if (cached != null) return cached;
    return await _repository.fetchPublicRestaurantById(restaurantId);
  }

  List<String> get availableStates {
    final set = <String>{};
    for (final r in _restaurants) {
      if (r.state.trim().isNotEmpty) set.add(r.state.trim());
    }
    final sorted = set.toList()..sort();
    return ['All', ...sorted];
  }

  List<String> get availableCuisines {
    final set = <String>{};
    for (final r in _restaurants) {
      if (r.cuisineType.trim().isNotEmpty) {
        set.add(r.cuisineType.trim());
      }
    }
    final sorted = set.toList()..sort();
    return ['All', ...sorted];
  }

  List<String> get availablePriceRanges {
    final present = <String>{};
    for (final r in _restaurants) {
      if (r.priceRange.trim().isNotEmpty) {
        present.add(r.priceRange.trim());
      }
    }
    const order = [r'$', r'$$', r'$$$', r'$$$$'];
    final sorted = order.where((p) => present.contains(p)).toList();
    return ['All', ...sorted];
  }

  String get selectedStateDisplayName {
    if (_selectedState == 'All') return 'All Malaysia';
    if (_selectedState == 'Pulau Pinang') return 'Penang';
    return _selectedState;
  }

  bool get isGeneratingListing => _isGeneratingListing;
  String? get generationError => _generationError;
  List<GeneratedRestaurantListing> get generatedCandidates =>
      List.unmodifiable(_generatedCandidates);
  GeneratedRestaurantListing? get selectedGeneratedCandidate =>
      _selectedGeneratedCandidate;
  bool get isConnectingSocialAccount => _isConnectingSocialAccount;
  String? get socialConnectionError => _socialConnectionError;

  Future<bool> generateRestaurantListingFromSource(String sourceUrl) async {
    final requestId = ++_generationRequestId;
    _isGeneratingListing = true;
    _generationError = null;
    _socialConnectionError = null;
    _generatedCandidates = [];
    _selectedGeneratedCandidate = null;
    notifyListeners();
    try {
      final result = await _repository.generateRestaurantListingFromSource(
        sourceUrl,
      );
      if (requestId != _generationRequestId) return false;
      _generatedCandidates = result.candidates;
      if (_generatedCandidates.isEmpty) {
        _generationError =
            'No likely restaurant-review posts were found in this source.';
        return false;
      }
      if (_generatedCandidates.length == 1) {
        _selectedGeneratedCandidate = _generatedCandidates.single;
      }
      return true;
    } catch (error) {
      if (requestId != _generationRequestId) return false;
      _generationError = _message(
        error,
        'The social source could not be analysed. Please try again.',
      );
      return false;
    } finally {
      if (requestId == _generationRequestId) {
        _isGeneratingListing = false;
        notifyListeners();
      }
    }
  }

  void selectGeneratedCandidate(GeneratedRestaurantListing candidate) {
    if (!_generatedCandidates.contains(candidate)) return;
    _selectedGeneratedCandidate = candidate;
    _generationError = null;
    notifyListeners();
  }

  void clearGeneratedResult() {
    _generationRequestId += 1;
    _isGeneratingListing = false;
    _generationError = null;
    _socialConnectionError = null;
    _generatedCandidates = [];
    _selectedGeneratedCandidate = null;
    notifyListeners();
  }

  Future<Uri?> startSocialAccountConnection(String platform) async {
    _isConnectingSocialAccount = true;
    _socialConnectionError = null;
    notifyListeners();
    try {
      return await _repository.startSocialAccountConnection(platform);
    } catch (error) {
      _socialConnectionError = _message(
        error,
        'The social account connection could not be started.',
      );
      return null;
    } finally {
      _isConnectingSocialAccount = false;
      notifyListeners();
    }
  }

  List<RestaurantModel> get filteredRestaurants =>
      _restaurants.where((restaurant) {
        final searchable = [
          restaurant.name,
          restaurant.cuisineType,
          restaurant.city,
          restaurant.state,
          restaurant.reviewedDishes,
        ].join(' ').toLowerCase();
        if (_searchQuery.isNotEmpty && !searchable.contains(_searchQuery)) {
          return false;
        }
        if (_selectedState != 'All' &&
            restaurant.state != _selectedState &&
            !(_selectedState == 'Penang' &&
                restaurant.state == 'Pulau Pinang')) {
          return false;
        }
        if (_selectedCuisine != 'All' &&
            !restaurant.cuisineType
                .toLowerCase()
                .contains(_selectedCuisine.toLowerCase())) {
          return false;
        }
        return _selectedBudget == 'All' ||
            restaurant.priceRange == _selectedBudget;
      }).toList();

  List<RestaurantModel> get trendingRestaurants =>
      _restaurants.take(3).toList();
  List<RestaurantModel> get ownedApprovedRestaurants => _restaurants
      .where((restaurant) => restaurant.isOwnedByCurrentUser)
      .toList();

  List<DiscountCodeModel> getActiveDiscountsForRestaurant(
    String restaurantId,
  ) {
    return _discountCodes
        .where(
          (discount) =>
              discount.restaurantId == restaurantId &&
              discount.isCurrentlyActive,
        )
        .toList();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final values = await Future.wait([
        _repository.fetchPublicRestaurants(),
        _repository.fetchActiveDiscounts(),
      ]);
      _restaurants = values[0] as List<RestaurantModel>;
      _discountCodes = values[1] as List<DiscountCodeModel>;
      if (_selectedBudget != 'All' &&
          !availablePriceRanges.contains(_selectedBudget)) {
        _selectedBudget = 'All';
      }
      if (_selectedCuisine != 'All' &&
          !availableCuisines.contains(_selectedCuisine)) {
        _selectedCuisine = 'All';
      }
      if (_selectedState != 'All' &&
          !availableStates.contains(_selectedState)) {
        _selectedState = 'All';
      }
    } catch (error) {
      _errorMessage = _message(error, 'LocalEats could not be loaded.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingRestaurants() async {
    try {
      _pendingRestaurants = await _repository.fetchPendingRestaurants();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _message(
        error,
        'Restaurant submissions could not be loaded.',
      );
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadOwnedRestaurantSubmissions() async {
    try {
      _ownedRestaurantSubmissions =
          await _repository.fetchOwnedRestaurantSubmissions();
      _errorMessage = null;
    } catch (error) {
      _errorMessage =
          _message(error, 'Your restaurant submissions could not be loaded.');
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadOwnedDiscounts() async {
    try {
      _ownedDiscounts = await _repository.fetchOwnedDiscounts();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _message(error, 'Your discounts could not be loaded.');
    } finally {
      notifyListeners();
    }
  }

  void setFilter({
    String? state,
    String? cuisine,
    String? foodType,
    String? budget,
  }) {
    if (state != null) _selectedState = state;
    if (cuisine != null) _selectedCuisine = cuisine;
    if (budget != null) _selectedBudget = budget;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim().toLowerCase();
    notifyListeners();
  }

  void resetFilters() {
    _selectedState = 'All';
    _selectedCuisine = 'All';
    _selectedBudget = 'All';
    _searchQuery = '';
    notifyListeners();
  }

  Future<RestaurantDraftResult?> createRestaurantDraft({
    required RestaurantDraftInput input,
    required Uint8List imageBytes,
    required String imageMimeType,
  }) async {
    try {
      final draft = await _repository.createRestaurantDraft(
        input: input,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
      );
      if (draft.probableDuplicates.isEmpty) {
        await _repository.submitRestaurant(revisionId: draft.revisionId);
      }
      _errorMessage = null;
      notifyListeners();
      return draft;
    } catch (error) {
      _errorMessage = _message(error, 'The restaurant could not be saved.');
      notifyListeners();
      return null;
    }
  }

  Future<RestaurantDraftResult?> reviseRestaurant({
    required RestaurantModel source,
    required RestaurantDraftInput input,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    try {
      final draft = await _repository.saveRestaurantRevisionDraft(
        source: source,
        input: input,
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
      );
      if (draft.probableDuplicates.isEmpty) {
        await _repository.submitRestaurant(revisionId: draft.revisionId);
      }
      await loadOwnedRestaurantSubmissions();
      _errorMessage = null;
      notifyListeners();
      return draft;
    } catch (error) {
      _errorMessage =
          _message(error, 'The restaurant revision could not be saved.');
      notifyListeners();
      return null;
    }
  }

  Future<bool> withdrawRestaurantSubmission(
    RestaurantModel restaurant,
  ) async {
    final revisionId = restaurant.revisionId;
    if (revisionId == null) return false;
    try {
      await _repository.withdrawRestaurantRevision(revisionId);
      await Future.wait([loadOwnedRestaurantSubmissions(), loadData()]);
      return true;
    } catch (error) {
      _errorMessage =
          _message(error, 'The restaurant submission could not be withdrawn.');
      notifyListeners();
      return false;
    }
  }

  Future<bool> resolveRestaurantDuplicate(
    RestaurantDraftResult draft, {
    String? overrideReason,
    bool discard = false,
  }) async {
    try {
      if (discard) {
        await _repository.deleteRestaurantDraft(draft);
      } else {
        await _repository.submitRestaurant(
          revisionId: draft.revisionId,
          duplicateOverrideReason: overrideReason,
        );
      }
      await loadOwnedRestaurantSubmissions();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _message(
        error,
        'The restaurant draft could not be updated.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> moderateRestaurant(
    RestaurantModel restaurant,
    String decision,
    String reason,
  ) async {
    try {
      await _repository.moderateRestaurant(
        restaurant: restaurant,
        decision: decision,
        reason: reason,
      );
      await Future.wait([loadPendingRestaurants(), loadData()]);
      return true;
    } catch (error) {
      _errorMessage = _message(error, 'The restaurant decision failed.');
      notifyListeners();
      return false;
    }
  }

  Future<bool> createDiscount(DiscountDraftInput input) async {
    try {
      await _repository.createAndPublishDiscount(input);
      await loadData();
      await loadOwnedDiscounts();
      return true;
    } catch (error) {
      _errorMessage = _message(error, 'The discount could not be created.');
      notifyListeners();
      return false;
    }
  }

  Future<bool> transitionDiscount(
    DiscountCodeModel discount,
    String action,
  ) async {
    try {
      await _repository.transitionDiscount(
        discount: discount,
        action: action,
      );
      await Future.wait([loadOwnedDiscounts(), loadData()]);
      return true;
    } catch (error) {
      _errorMessage = _message(
        error,
        'The discount status could not be updated.',
      );
      notifyListeners();
      return false;
    }
  }

  void filterByState(String state) => setFilter(state: state);
  void filterByCuisine(String cuisine) => setFilter(cuisine: cuisine);
  void filterByBudget(String budget) => setFilter(budget: budget);

  String _message(Object error, String fallback) {
    return error is AppException ? error.userMessage : fallback;
  }
}
