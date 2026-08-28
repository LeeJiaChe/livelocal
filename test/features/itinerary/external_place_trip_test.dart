import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/itinerary/presentation/itinerary_controller.dart';
import 'package:live_local/models/saved_collection_model.dart';
import 'package:live_local/models/saved_place_model.dart';
import 'package:live_local/services/seed_data_service.dart';

void main() {
  test('saved external Google identity survives database map reload', () {
    final saved = SavedPlaceModel.fromMap({
      'id': 'saved-1',
      'user_id': 'tourist-1',
      'spot_id': null,
      'restaurant_id': null,
      'external_provider': 'google',
      'external_place_id': 'ChIJExternalPlace123',
      'saved_at': '2026-08-29T00:00:00Z',
    });

    expect(saved.externalProvider, 'google');
    expect(saved.externalPlaceId, 'ChIJExternalPlace123');
  });

  test('external Google identity is saved before opening Trip workflow',
      () async {
    final auth = DemoAuthRepository();
    await auth.signIn(
      email: 'tourist@livelocal.com',
      password: SeedDataService.demoPassword,
    );
    final repository = _ExternalCaptureRepository(auth);
    final controller = ItineraryController(repository: repository);

    final result = await controller.saveExternalToDefaultCollection(
      provider: 'google',
      placeId: 'ChIJExternalPlace123',
    );

    expect(result, isTrue);
    expect(repository.targetType, 'external');
    expect(repository.targetId, 'ChIJExternalPlace123');
    expect(repository.externalProvider, 'google');
    expect(repository.collectionIds, isNotEmpty);
  });
}

class _ExternalCaptureRepository extends DemoSavedItineraryRepository {
  _ExternalCaptureRepository(super.authRepository);

  String? targetType;
  String? targetId;
  String? externalProvider;
  List<String> collectionIds = [];

  @override
  Future<SetPlaceCollectionsResult> setPlaceCollections({
    required String targetType,
    required String targetId,
    required List<String> collectionIds,
    String? externalProvider,
  }) async {
    this.targetType = targetType;
    this.targetId = targetId;
    this.collectionIds = collectionIds;
    this.externalProvider = externalProvider;
    return SetPlaceCollectionsResult(
      saved: true,
      collectionIds: collectionIds,
      targetType: targetType,
      targetId: targetId,
    );
  }
}
