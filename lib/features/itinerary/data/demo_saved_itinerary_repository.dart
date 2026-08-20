import '../../../core/errors/app_exception.dart';
import '../../../models/saved_collection_model.dart';
import '../../../models/saved_place_model.dart';
import '../../auth/data/demo_auth_repository.dart';
import '../../auth/domain/account_identity.dart';
import '../domain/saved_itinerary_repository.dart';

class DemoSavedItineraryRepository implements SavedItineraryRepository {
  DemoSavedItineraryRepository(this._authRepository);

  final DemoAuthRepository _authRepository;
  final List<SavedCollectionModel> _collections = [];
  final List<SavedCollectionItemModel> _collectionItems = [];
  final List<SavedPlaceModel> _savedPlaces = [];
  final List<SavedItinerary> _itineraries = [];
  RouteOrigin? _preference;

  RouteOrigin? get locationPreferenceForDemo => _preference;

  void _ensureDefaultCollection(String userId) {
    if (!_collections.any((c) => c.userId == userId)) {
      _collections.add(
        SavedCollectionModel(
          id: 'demo-col-default-$userId',
          userId: userId,
          name: 'Saved places',
          description: 'Default collection for your saved places',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<List<SavedCollectionModel>> fetchCollections() async {
    final userId = _requireUser();
    _ensureDefaultCollection(userId);
    final userCollections =
        _collections.where((item) => item.userId == userId).toList();

    // Compute item counts
    return userCollections.map((col) {
      final items = _collectionItems
          .where((item) => item.collectionId == col.id)
          .toList();
      final spotCount = items.where((i) => i.spotId != null).length;
      final restaurantCount = items.where((i) => i.restaurantId != null).length;
      return col.copyWith(
        itemCount: items.length,
        spotCount: spotCount,
        restaurantCount: restaurantCount,
      );
    }).toList();
  }

  @override
  Future<SavedCollectionModel> createCollection({
    required String name,
    String? description,
  }) async {
    final userId = _requireUser();
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trimmedName.length > 80) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Collection name must be between 1 and 80 characters.',
      );
    }
    if (_collections.any((c) =>
        c.userId == userId &&
        c.name.trim().toLowerCase() == trimmedName.toLowerCase())) {
      throw const AppException(
        code: AppErrorCode.conflict,
        userMessage: 'A collection with this name already exists.',
      );
    }
    final created = SavedCollectionModel(
      id: 'demo-col-${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      name: trimmedName,
      description: description?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _collections.insert(0, created);
    return created;
  }

  @override
  Future<SavedCollectionModel> renameCollection({
    required String collectionId,
    required String name,
    String? description,
  }) async {
    final userId = _requireUser();
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trimmedName.length > 80) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Collection name must be between 1 and 80 characters.',
      );
    }
    final index = _collections
        .indexWhere((c) => c.id == collectionId && c.userId == userId);
    if (index == -1) {
      throw const AppException(
        code: AppErrorCode.notFound,
        userMessage: 'Collection not found.',
      );
    }
    if (_collections.any((c) =>
        c.id != collectionId &&
        c.userId == userId &&
        c.name.trim().toLowerCase() == trimmedName.toLowerCase())) {
      throw const AppException(
        code: AppErrorCode.conflict,
        userMessage: 'A collection with this name already exists.',
      );
    }
    final updated = _collections[index].copyWith(
      name: trimmedName,
      description: description?.trim() ?? _collections[index].description,
      updatedAt: DateTime.now(),
    );
    _collections[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    final userId = _requireUser();
    final index = _collections
        .indexWhere((c) => c.id == collectionId && c.userId == userId);
    if (index == -1) {
      throw const AppException(
        code: AppErrorCode.notFound,
        userMessage: 'Collection not found.',
      );
    }
    _collections.removeAt(index);

    // Remove collection items for this collection
    final removedItems = _collectionItems
        .where((item) => item.collectionId == collectionId)
        .toList();
    _collectionItems.removeWhere((item) => item.collectionId == collectionId);

    // Check if any saved_places became orphaned (0 collection memberships)
    for (final item in removedItems) {
      final hasOtherMemberships =
          _collectionItems.any((ci) => ci.savedPlaceId == item.savedPlaceId);
      if (!hasOtherMemberships) {
        _savedPlaces.removeWhere((sp) => sp.id == item.savedPlaceId);
      }
    }
  }

  @override
  Future<List<SavedCollectionItemModel>> fetchCollectionItems(
    String collectionId,
  ) async {
    _requireUser();
    return _collectionItems
        .where((item) => item.collectionId == collectionId)
        .toList();
  }

  @override
  Future<List<String>> fetchPlaceCollectionIds({
    required String targetType,
    required String targetId,
  }) async {
    final userId = _requireUser();
    final savedPlace = _savedPlaces.firstWhere(
      (sp) =>
          sp.userId == userId &&
          ((targetType == 'spot' && sp.spotId == targetId) ||
              (targetType == 'restaurant' && sp.restaurantId == targetId)),
      orElse: () => SavedPlaceModel(
        id: '',
        userId: '',
        savedAt: DateTime.now(),
      ),
    );
    if (savedPlace.id.isEmpty) return const [];
    return _collectionItems
        .where((item) => item.savedPlaceId == savedPlace.id)
        .map((item) => item.collectionId)
        .toList();
  }

  @override
  Future<bool> setPlaceCollections({
    required String targetType,
    required String targetId,
    required List<String> collectionIds,
  }) async {
    final userId = _requireUser();
    _validateTarget(targetType, targetId);

    var placeIndex = _savedPlaces.indexWhere(
      (sp) =>
          sp.userId == userId &&
          ((targetType == 'spot' && sp.spotId == targetId) ||
              (targetType == 'restaurant' && sp.restaurantId == targetId)),
    );

    if (collectionIds.isEmpty) {
      if (placeIndex != -1) {
        final placeId = _savedPlaces[placeIndex].id;
        _collectionItems.removeWhere((item) => item.savedPlaceId == placeId);
        _savedPlaces.removeAt(placeIndex);
      }
      return false;
    }

    String placeId;
    if (placeIndex == -1) {
      placeId = 'demo-save-${DateTime.now().microsecondsSinceEpoch}';
      _savedPlaces.add(
        SavedPlaceModel(
          id: placeId,
          userId: userId,
          spotId: targetType == 'spot' ? targetId : null,
          restaurantId: targetType == 'restaurant' ? targetId : null,
          savedAt: DateTime.now(),
        ),
      );
    } else {
      placeId = _savedPlaces[placeIndex].id;
    }

    // Remove memberships not in collectionIds
    _collectionItems.removeWhere((item) =>
        item.savedPlaceId == placeId &&
        !collectionIds.contains(item.collectionId));

    // Add new memberships
    for (final cid in collectionIds) {
      if (!_collectionItems.any(
          (item) => item.savedPlaceId == placeId && item.collectionId == cid)) {
        _collectionItems.add(
          SavedCollectionItemModel(
            id: 'demo-ci-${DateTime.now().microsecondsSinceEpoch}',
            collectionId: cid,
            savedPlaceId: placeId,
            spotId: targetType == 'spot' ? targetId : null,
            restaurantId: targetType == 'restaurant' ? targetId : null,
            addedAt: DateTime.now(),
          ),
        );
      }
    }

    return true;
  }

  @override
  Future<List<SavedPlaceModel>> fetchSavedPlaces() async {
    final userId = _requireUser();
    return _savedPlaces.where((item) => item.userId == userId).toList();
  }

  @override
  Future<bool> setSaved({
    required String targetType,
    required String targetId,
    required bool saved,
  }) async {
    final userId = _requireUser();
    _validateTarget(targetType, targetId);
    _ensureDefaultCollection(userId);
    final defaultCollId = _collections.firstWhere((c) => c.userId == userId).id;

    if (saved) {
      return await setPlaceCollections(
        targetType: targetType,
        targetId: targetId,
        collectionIds: [defaultCollId],
      );
    } else {
      return await setPlaceCollections(
        targetType: targetType,
        targetId: targetId,
        collectionIds: const [],
      );
    }
  }

  @override
  Future<List<SavedItinerary>> fetchItineraries() async {
    _requireUser();
    return List.unmodifiable(_itineraries);
  }

  @override
  Future<SavedItinerary> createItinerary({
    required String title,
    required RouteOrigin origin,
    required List<ItineraryTarget> orderedTargets,
  }) async {
    final userId = _requireUser();
    if (title.trim().length < 2 || orderedTargets.isEmpty) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Add at least one saved place and a plan title.',
      );
    }
    final owned = _savedPlaces.where((item) => item.userId == userId).toList();
    for (final target in orderedTargets) {
      _validateTarget(target.type, target.id);
      if (!owned.any(
        (item) => item.spotId == target.id || item.restaurantId == target.id,
      )) {
        throw const AppException(
          code: AppErrorCode.forbidden,
          userMessage: 'An itinerary can contain only your saved places.',
        );
      }
    }
    final itinerary = SavedItinerary(
      id: 'demo-itinerary-${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim(),
      originLabel: origin.label,
      version: 1,
      createdAt: DateTime.now(),
      targets: List.unmodifiable(orderedTargets),
    );
    _itineraries.add(itinerary);
    return itinerary;
  }

  @override
  Future<void> saveLocationPreference(RouteOrigin origin) async {
    _requireUser();
    _preference = origin;
  }

  String _requireUser() {
    final account = _authRepository.currentAccountForDemo;
    if (account == null || account.accessStatus != AccountAccessStatus.active) {
      throw const AppException(
        code: AppErrorCode.authentication,
        userMessage: 'Sign in with an active account to continue.',
      );
    }
    return account.id;
  }

  void _validateTarget(String type, String id) {
    if (!{'spot', 'restaurant'}.contains(type) || id.isEmpty) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Choose a valid place.',
      );
    }
  }
}
