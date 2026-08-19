import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/admin/data/demo_admin_repository.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/guides/data/demo_guide_repository.dart';
import 'package:live_local/features/influencer_applications/data/demo_influencer_application_repository.dart';
import 'package:live_local/features/profile/data/demo_account_repository.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/services/seed_data_service.dart';

void main() {
  group('Demo Repositories & Admin Fixtures Tests', () {
    late DemoAuthRepository authRepository;
    late DemoAccountRepository accountRepository;
    late DemoAdminRepository adminRepository;
    late DemoSpotRepository spotRepository;
    late DemoLocalEatsRepository localEatsRepository;
    late DemoGuideRepository guideRepository;
    late DemoInfluencerApplicationRepository influencerRepository;

    setUp(() async {
      authRepository = DemoAuthRepository();
      accountRepository = DemoAccountRepository(authRepository);
      adminRepository = DemoAdminRepository(authRepository, accountRepository);
      spotRepository =
          DemoSpotRepository(authRepository, seedAdminWorkload: true);
      localEatsRepository =
          DemoLocalEatsRepository(authRepository, seedAdminWorkload: true);
      guideRepository =
          DemoGuideRepository(authRepository, seedAdminWorkload: true);
      influencerRepository = DemoInfluencerApplicationRepository(
        authRepository,
        seedAdminWorkload: true,
      );

      await authRepository.signIn(
        email: 'admin@livelocal.com',
        password: SeedDataService.demoPassword,
      );
    });

    test('57. demo pending Spot is admin-visible but public-hidden', () async {
      final publicSpots = await spotRepository.fetchPublicSpots(
        offset: 0,
        limit: 50,
      );
      final pendingSpots = await spotRepository.fetchPendingModeration();

      expect(pendingSpots.any((s) => s.id == 'demo-spot-pending-1'), isTrue);
      expect(publicSpots.any((s) => s.id == 'demo-spot-pending-1'), isFalse);
    });

    test('58. demo pending Restaurant is admin-visible but public-hidden',
        () async {
      final publicRestaurants =
          await localEatsRepository.fetchPublicRestaurants();
      final pendingRestaurants =
          await localEatsRepository.fetchPendingRestaurants();

      expect(
        pendingRestaurants.any((r) => r.id == 'demo-restaurant-pending-1'),
        isTrue,
      );
      expect(
        publicRestaurants.any((r) => r.id == 'demo-restaurant-pending-1'),
        isFalse,
      );
    });

    test(
        '59-60. demo submitted and draft Guides are admin-visible but public-hidden',
        () async {
      final publishedGuides = await guideRepository.fetchPublishedGuides();
      final adminDrafts = await guideRepository.fetchAdminDrafts();

      // Submitted guide
      expect(
        adminDrafts.any((g) => g.id == 'demo-guide-submitted-1'),
        isTrue,
      );
      expect(
        publishedGuides.any((g) => g.id == 'demo-guide-submitted-1'),
        isFalse,
      );

      // Draft guide
      expect(
        adminDrafts
            .any((g) => g.id == 'demo-guide-draft-1' && g.status == 'draft'),
        isTrue,
      );
      expect(
        publishedGuides.any((g) => g.id == 'demo-guide-draft-1'),
        isFalse,
      );
    });

    test('61. demo Creator application is pending for admin', () async {
      final pendingApps = await influencerRepository.fetchPendingForAdmin();
      expect(pendingApps.any((a) => a.id == 'demo-app-1'), isTrue);
    });

    test(
        '62-64. demo Content report is pending and deciding it updates status and audit',
        () async {
      final reports = await adminRepository.fetchModerationCases();
      expect(reports.any((r) => r.id == 'demo-case-1'), isTrue);

      final report = reports.firstWhere((r) => r.id == 'demo-case-1');
      await adminRepository.decideModerationCase(
        moderationCase: report,
        decision: 'upheld',
        reason: 'Report verified on site',
      );

      final updatedReports = await adminRepository.fetchModerationCases();
      expect(updatedReports.any((r) => r.id == 'demo-case-1'), isFalse);

      final audit = await adminRepository.fetchAuditEvents();
      expect(
        audit.any((a) => a.action == 'admin.moderation_case_upheld'),
        isTrue,
      );
    });

    test('65. default demo repositories are clean without admin workload',
        () async {
      final cleanSpotRepo = DemoSpotRepository(authRepository);
      final cleanEatsRepo = DemoLocalEatsRepository(authRepository);
      final cleanGuideRepo = DemoGuideRepository(authRepository);
      final cleanInfluencerRepo =
          DemoInfluencerApplicationRepository(authRepository);

      expect(await cleanSpotRepo.fetchPendingModeration(), isEmpty);
      expect(await cleanEatsRepo.fetchPendingRestaurants(), isEmpty);
      expect(await cleanGuideRepo.fetchAdminDrafts(), isEmpty);
      expect(await cleanInfluencerRepo.fetchPendingForAdmin(), isEmpty);
    });
  });
}
