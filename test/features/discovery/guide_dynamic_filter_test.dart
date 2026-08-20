import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/guide_controller.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/guides/domain/guide_repository.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/spots/domain/spot_repository.dart';
import 'package:live_local/models/guide_model.dart';
import 'package:live_local/models/spot_filter_options.dart';
import 'package:live_local/models/spot_model.dart';

class _MockGuideRepo implements GuideRepository {
  _MockGuideRepo(this._guides);
  final List<GuideModel> _guides;

  @override
  Future<List<GuideModel>> fetchPublishedGuides() async => _guides;

  @override
  Future<List<GuideModel>> fetchAdminDrafts() async => [];

  @override
  Future<List<GuideModel>> fetchMySubmissions() async => [];

  @override
  Future<GuideModel> submitGuide(GuideDraftInput input) async =>
      throw UnimplementedError();

  @override
  Future<GuideModel> saveAdminDraft(
    GuideDraftInput input, {
    GuideModel? guide,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> publishAdminDraft(GuideModel draft, String reason) async {}

  @override
  Future<void> archiveGuide(GuideModel guide, String reason) async {}

  @override
  Future<void> moderateSubmission(
    GuideModel guide,
    String decision,
    String reason,
  ) async {}
}

class _MockSpotRepo implements SpotRepository {
  _MockSpotRepo({required this.options, required this.spots});
  SpotFilterOptions options;
  List<SpotModel> spots;
  String lastQueriedCategory = '';
  String lastQueriedState = '';

  @override
  Future<SpotFilterOptions> fetchFilterOptions() async => options;

  @override
  Future<SpotModel?> fetchPublicSpotById(String spotId) async =>
      spots.where((s) => s.id == spotId).firstOrNull;

  @override
  Future<List<SpotModel>> fetchPublicSpots({
    String? query,
    String? state,
    String? category,
    required int offset,
    required int limit,
  }) async {
    lastQueriedCategory = category ?? 'All';
    lastQueriedState = state ?? 'All';
    return spots.where((s) {
      if (category != null && category != 'All' && s.category != category) {
        return false;
      }
      if (state != null && state != 'All' && s.state != state) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<SpotModel>> fetchPendingModeration() async => [];

  @override
  Future<List<SpotModel>> fetchOwnedSubmissions() async => [];

  @override
  Future<SpotDraftResult> createDraft({
    required SpotDraftInput input,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> submitRevision({
    required String revisionId,
    String? duplicateOverrideReason,
  }) async {}

  @override
  Future<void> confirmImageRights(String revisionId) async {}

  @override
  Future<SpotDraftResult> saveRevisionDraft({
    required SpotModel source,
    required SpotDraftInput input,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> withdrawRevision(String revisionId) async {}

  @override
  Future<void> deleteDraft({
    required String revisionId,
    String? imagePath,
  }) async {}

  @override
  Future<void> moderateRevision({
    required String revisionId,
    required String decision,
    required String reason,
    required int expectedVersion,
  }) async {}

  @override
  Future<SpotUpvoteResult> toggleUpvote(String spotId) async =>
      throw UnimplementedError();
}

void main() {
  group('Guide Dynamic Filters & Penang Aliasing', () {
    test('Guide available states are derived dynamically from published guides',
        () async {
      final mockGuides = [
        GuideModel(
          id: 'g1',
          title: 'Heritage Walk',
          locationName: 'George Town',
          state: 'Pulau Pinang',
          routeOverview: 'Walk historical streets',
          estimatedDuration: '2 hours',
          stops: const ['Street 1', 'Street 2'],
          walkingSequence: const ['Street 1', 'Street 2'],
        ),
        GuideModel(
          id: 'g2',
          title: 'KL Cafe Trail',
          locationName: 'Bukit Bintang',
          state: 'Kuala Lumpur',
          routeOverview: 'Coffee and brunch',
          estimatedDuration: '3 hours',
          stops: const ['Cafe 1', 'Cafe 2'],
          walkingSequence: const ['Cafe 1', 'Cafe 2'],
        ),
      ];

      final controller =
          GuideController(repository: _MockGuideRepo(mockGuides));
      await controller.loadGuides();

      // Available states include All, Kuala Lumpur, and Pulau Pinang with Penang display
      final stateOptions = controller.availableStates;
      expect(stateOptions.map((s) => s.rawValue),
          containsAll(['All', 'Kuala Lumpur', 'Pulau Pinang']));

      final penangOpt =
          stateOptions.firstWhere((s) => s.rawValue == 'Pulau Pinang');
      expect(penangOpt.displayName, equals('Penang'));

      // Zero-result states like Kedah, Terengganu are NOT in availableStates
      expect(stateOptions.any((s) => s.rawValue == 'Kedah'), isFalse);
      expect(stateOptions.any((s) => s.rawValue == 'Terengganu'), isFalse);

      // Filter by Penang raw value
      controller.setStateFilter('Pulau Pinang');
      expect(controller.approvedGuides, hasLength(1));
      expect(controller.approvedGuides.first.title, equals('Heritage Walk'));

      // Neighbourhoods are constrained to George Town
      expect(controller.availableNeighbourhoods,
          containsAll(['All', 'George Town']));
      expect(controller.availableNeighbourhoods.contains('Bukit Bintang'),
          isFalse);
    });
  });

  group('Local Eats Price Filter Dynamic Derivation', () {
    test('availablePriceRanges only includes ranges present in loaded data',
        () async {
      final authRepo = DemoAuthRepository();
      final mockEatsRepo = DemoLocalEatsRepository(authRepo);
      final controller = LocalEatsController(repository: mockEatsRepo);
      await controller.loadData();

      // Check available price ranges
      final priceRanges = controller.availablePriceRanges;
      expect(priceRanges.first, equals('All'));
      expect(priceRanges, contains(r'$'));
      expect(priceRanges, contains(r'$$'));
    });
  });

  group('Spot Filter Invalidation Stale Query Edge Case', () {
    test(
        'When active category disappears from filter options, controller resets to All and refetches using All',
        () async {
      final initialSpots = [
        SpotModel(
          id: 's1',
          name: 'Scenic Lookout',
          category: 'Nature',
          description: '',
          state: 'Penang',
          city: 'George Town',
          address: '',
          priceRange: r'$',
          bestTime: '',
          thingsToDo: '',
          imageUrl: '',
          submittedBy: '',
        ),
        SpotModel(
          id: 's2',
          name: 'Old Temple',
          category: 'Culture',
          description: '',
          state: 'Penang',
          city: 'George Town',
          address: '',
          priceRange: r'$',
          bestTime: '',
          thingsToDo: '',
          imageUrl: '',
          submittedBy: '',
        ),
      ];

      final mockRepo = _MockSpotRepo(
        options: const SpotFilterOptions(
          states: [
            SpotStateOption(rawValue: 'All', displayName: 'All Malaysia')
          ],
          categories: ['All', 'Nature', 'Culture'],
        ),
        spots: initialSpots,
      );

      final controller = SpotController(repository: mockRepo);
      await controller.loadSpots();

      // Select 'Culture'
      controller.filterByCategory('Culture');
      await controller.loadSpots();
      expect(controller.selectedCategory, equals('Culture'));
      expect(mockRepo.lastQueriedCategory, equals('Culture'));

      // Now server removes 'Culture' from valid options
      mockRepo.options = const SpotFilterOptions(
        states: [SpotStateOption(rawValue: 'All', displayName: 'All Malaysia')],
        categories: ['All', 'Nature'],
      );

      // Trigger loadSpots()
      await controller.loadSpots();

      // Invalidation: selectedCategory is reset to 'All' AND query sent to backend is 'All'
      expect(controller.selectedCategory, equals('All'));
      expect(mockRepo.lastQueriedCategory, equals('All'));
      expect(controller.spots, hasLength(2));
    });
  });
}
