import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/guides/data/demo_guide_repository.dart';
import 'package:live_local/features/guides/domain/guide_repository.dart';
import 'package:live_local/features/guides/presentation/guide_controller.dart';
import 'package:live_local/services/seed_data_service.dart';
import 'package:live_local/models/guide_model.dart';

void main() {
  const draftInput = GuideDraftInput(
    title: 'Brickfields morning walk',
    locationName: 'Brickfields',
    state: 'Kuala Lumpur',
    routeOverview:
        'A calm, accessible morning route through food and heritage stops.',
    stops: ['Breakfast stop', 'Heritage street'],
    walkingSequence: ['Start at breakfast', 'Continue to heritage street'],
    stopDetails: [
      GuideStopModel(
        kind: GuideStopKind.custom,
        name: 'Breakfast stop',
        instruction: 'Start at breakfast',
      ),
      GuideStopModel(
        kind: GuideStopKind.custom,
        name: 'Heritage street',
        instruction: 'Continue to heritage street',
      ),
    ],
    estimatedDuration: '2 hours',
  );

  group('GuideController administration and moderation', () {
    test('only an active admin can create and publish a guide revision',
        () async {
      final authRepository = DemoAuthRepository();
      final repository = DemoGuideRepository(authRepository);
      final controller = GuideController(repository: repository);

      await authRepository.signIn(
        email: 'tourist@livelocal.com',
        password: SeedDataService.demoPassword,
      );
      expect(await controller.createDraft(draftInput), isFalse);
      expect(controller.errorMessage, contains('Administrator'));

      await authRepository.signIn(
        email: 'admin@livelocal.com',
        password: SeedDataService.demoPassword,
      );
      expect(await controller.createDraft(draftInput), isTrue);
      final draft = controller.adminDrafts.singleWhere(
        (guide) => guide.title == draftInput.title,
      );
      expect(draft.status, 'draft');

      expect(await controller.publishDraft(draft, 'Editorial review complete'),
          isTrue);
      expect(
        controller.guides.any(
          (guide) =>
              guide.id == draft.id &&
              guide.status == 'approved' &&
              guide.version == 2,
        ),
        isTrue,
      );

      expect(
        await controller.publishDraft(draft, 'Attempt duplicate publication'),
        isFalse,
      );
      expect(controller.errorMessage, contains('changed'));

      final published = controller.guides.singleWhere(
        (guide) => guide.id == draft.id,
      );
      expect(
        await controller.createDraft(
          const GuideDraftInput(
            title: 'Brickfields accessible morning walk',
            locationName: 'Brickfields',
            state: 'Kuala Lumpur',
            routeOverview:
                'A revised accessible route through food and heritage stops.',
            stops: ['Breakfast stop', 'Accessible heritage street'],
            walkingSequence: [
              'Start at breakfast',
              'Continue along the accessible path'
            ],
            stopDetails: [
              GuideStopModel(
                kind: GuideStopKind.custom,
                name: 'Breakfast stop',
                instruction: 'Start at breakfast',
              ),
              GuideStopModel(
                kind: GuideStopKind.custom,
                name: 'Accessible heritage street',
                instruction: 'Continue along the accessible path',
              ),
            ],
            estimatedDuration: '2 hours',
          ),
          guide: published,
        ),
        isTrue,
      );
      final revision = controller.adminDrafts.singleWhere(
        (guide) => guide.id == published.id,
      );
      expect(revision.version, 3);
      expect(
        await controller.publishDraft(revision, 'Revised route verified'),
        isTrue,
      );
      final revised = controller.guides.singleWhere(
        (guide) => guide.id == published.id,
      );
      expect(revised.version, 4);
      expect(
        await controller.archiveGuide(revised, 'Route is no longer current'),
        isTrue,
      );
      expect(
          controller.guides.where((guide) => guide.id == revised.id), isEmpty);
    });

    test('tourist submission stays private until an admin decision', () async {
      final authRepository = DemoAuthRepository();
      final repository = DemoGuideRepository(authRepository);
      final controller = GuideController(repository: repository);
      await authRepository.signIn(
        email: 'tourist@livelocal.com',
        password: SeedDataService.demoPassword,
      );

      expect(await controller.submitGuide(draftInput), isTrue);
      final submitted = controller.mySubmissions.single;
      expect(submitted.status, 'submitted');
      expect(controller.guides.where((guide) => guide.id == submitted.id),
          isEmpty);

      await authRepository.signIn(
        email: 'admin@livelocal.com',
        password: SeedDataService.demoPassword,
      );
      await controller.loadAdminDrafts();
      expect(
          await controller.moderateSubmission(
            submitted,
            'approved',
            'Stops and route verified',
          ),
          isTrue);
      expect(
          controller.guides
              .singleWhere((guide) => guide.id == submitted.id)
              .status,
          'approved');
    });
  });

  group('GuideController neighbourhood and search filtering', () {
    late DemoAuthRepository authRepository;
    late DemoGuideRepository repository;
    late GuideController controller;

    setUp(() async {
      authRepository = DemoAuthRepository();
      repository = DemoGuideRepository(authRepository);
      controller = GuideController(repository: repository);
      await controller.loadGuides();
    });

    test('1. default filters show all published guides', () {
      expect(controller.selectedState, 'All');
      expect(controller.selectedNeighbourhood, 'All');
      expect(controller.searchQuery, '');
      expect(controller.hasActiveFilters, isFalse);
      expect(controller.approvedGuides.length, controller.guides.length);
      expect(controller.approvedGuides.length, greaterThanOrEqualTo(2));
    });

    test('2. State filter restricts visible guides', () {
      controller.setStateFilter('Perak');
      expect(controller.selectedState, 'Perak');
      expect(controller.hasActiveFilters, isTrue);
      for (final guide in controller.approvedGuides) {
        expect(guide.state, 'Perak');
      }
      expect(controller.approvedGuides, isNotEmpty);
    });

    test('3. Neighbourhood filter restricts visible guides', () {
      controller.setNeighbourhoodFilter('Ipoh Old Town');
      expect(controller.selectedNeighbourhood, 'Ipoh Old Town');
      expect(controller.hasActiveFilters, isTrue);
      for (final guide in controller.approvedGuides) {
        expect(guide.locationName, 'Ipoh Old Town');
      }
    });

    test('4. neighbourhood options are derived correctly and sorted', () {
      final neighbourhoods = controller.availableNeighbourhoods;
      expect(neighbourhoods.first, 'All');
      expect(neighbourhoods, contains('Ipoh Old Town'));
      expect(neighbourhoods, contains('Taman Tun Dr Ismail'));
    });

    test('5. neighbourhood options respect selected State', () {
      controller.setStateFilter('Perak');
      final perakNeighbourhoods = controller.availableNeighbourhoods;
      expect(perakNeighbourhoods, contains('All'));
      expect(perakNeighbourhoods, contains('Ipoh Old Town'));
      expect(perakNeighbourhoods.contains('Taman Tun Dr Ismail'), isFalse);

      controller.setStateFilter('Kuala Lumpur');
      final klNeighbourhoods = controller.availableNeighbourhoods;
      expect(klNeighbourhoods, contains('All'));
      expect(klNeighbourhoods, contains('Taman Tun Dr Ismail'));
      expect(klNeighbourhoods.contains('Ipoh Old Town'), isFalse);
    });

    test('6. changing State resets invalid Neighbourhood to All', () {
      controller.setStateFilter('Kuala Lumpur');
      controller.setNeighbourhoodFilter('Taman Tun Dr Ismail');
      expect(controller.selectedNeighbourhood, 'Taman Tun Dr Ismail');

      // Change state to Perak where TTDI does not exist
      controller.setStateFilter('Perak');
      expect(controller.selectedNeighbourhood, 'All');
    });

    test('7. search by guide title', () {
      controller.setSearchQuery('Sunday Morning');
      expect(controller.approvedGuides.length, 1);
      expect(controller.approvedGuides.first.title, contains('Sunday Morning'));
    });

    test('8. search by locationName', () {
      controller.setSearchQuery('Ipoh Old Town');
      expect(controller.approvedGuides.length, 1);
      expect(controller.approvedGuides.first.locationName, 'Ipoh Old Town');
    });

    test('9. search is case-insensitive', () {
      controller.setSearchQuery('heritage');
      expect(controller.approvedGuides, isNotEmpty);
      for (final guide in controller.approvedGuides) {
        final text =
            '${guide.title} ${guide.locationName} ${guide.state} ${guide.routeOverview}'
                .toLowerCase();
        expect(text, contains('heritage'));
      }
    });

    test('10. State + Neighbourhood + Search combine correctly', () {
      controller.setStateFilter('Perak');
      controller.setNeighbourhoodFilter('Ipoh Old Town');
      controller.setSearchQuery('heritage');

      expect(controller.approvedGuides.length, 1);
      final guide = controller.approvedGuides.first;
      expect(guide.state, 'Perak');
      expect(guide.locationName, 'Ipoh Old Town');
      expect(guide.title.toLowerCase(), contains('heritage'));

      // If search doesn't match, return empty
      controller.setSearchQuery('nonexistent query xyz');
      expect(controller.approvedGuides, isEmpty);
    });

    test('11. resetFilters restores all guides', () {
      controller.setStateFilter('Perak');
      controller.setNeighbourhoodFilter('Ipoh Old Town');
      controller.setSearchQuery('heritage');
      expect(controller.hasActiveFilters, isTrue);

      controller.resetFilters();
      expect(controller.selectedState, 'All');
      expect(controller.selectedNeighbourhood, 'All');
      expect(controller.searchQuery, '');
      expect(controller.hasActiveFilters, isFalse);
      expect(controller.approvedGuides.length, controller.guides.length);
    });
  });
}
