import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/admin/data/demo_admin_repository.dart';
import 'package:live_local/features/admin/presentation/admin_controller.dart';
import 'package:live_local/features/admin/domain/admin_repository.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/profile/data/demo_account_repository.dart';
import 'package:live_local/services/seed_data_service.dart';

void main() {
  group('AdminController tests', () {
    late DemoAuthRepository authRepository;
    late DemoAccountRepository accountRepository;
    late DemoAdminRepository adminRepository;
    late AdminController controller;

    setUp(() async {
      authRepository = DemoAuthRepository();
      accountRepository = DemoAccountRepository(authRepository);
      adminRepository = DemoAdminRepository(authRepository, accountRepository);
      controller = AdminController(repository: adminRepository);

      await authRepository.signIn(
        email: 'admin@livelocal.com',
        password: SeedDataService.demoPassword,
      );
    });

    test('6. loadDashboard loads repository-backed Admin state', () async {
      expect(controller.accounts, isEmpty);
      expect(controller.moderationCases, isEmpty);
      expect(controller.auditEvents, isEmpty);
      expect(controller.lastUpdatedAt, isNull);

      await controller.loadDashboard();

      expect(controller.accounts, isNotEmpty);
      expect(controller.moderationCases, isNotEmpty);
      expect(controller.auditEvents, isNotEmpty);
      expect(controller.statistics, isNotNull);
      expect(controller.totalUsers, greaterThan(0));
      expect(controller.lastUpdatedAt, isNotNull);
      expect(controller.errorMessage, isNull);
    });

    test('7. loading state transitions correctly during refresh and mutation',
        () async {
      expect(controller.isLoading, isFalse);
      expect(controller.isRefreshing, isFalse);
      expect(controller.isMutating, isFalse);

      final loadFuture = controller.loadDashboard();
      expect(controller.isRefreshing, isTrue);
      expect(controller.isLoading, isTrue);

      await loadFuture;
      expect(controller.isRefreshing, isFalse);
      expect(controller.isLoading, isFalse);
    });

    test('8. repository failure produces error without crashing', () async {
      final unauthenticatedAuth = DemoAuthRepository();
      final failingRepo = DemoAdminRepository(unauthenticatedAuth);
      final failingController = AdminController(repository: failingRepo);

      await failingController.loadDashboard();
      expect(failingController.errorMessage, isNotNull);
      expect(failingController.isLoading, isFalse);
    });

    test('one failing queue source preserves successful dashboard data',
        () async {
      final partialController = AdminController(
        repository: _ReportsFailingAdminRepository(
          authRepository,
          accountRepository,
        ),
      );

      await partialController.loadDashboard();

      expect(partialController.statistics, isNotNull);
      expect(partialController.accounts, isNotEmpty);
      expect(partialController.moderationCases, isEmpty);
      expect(partialController.moderationCasesErrorMessage, isNotNull);
      expect(partialController.statisticsErrorMessage, isNull);
      expect(partialController.accountsErrorMessage, isNull);
    });

    test('9. account mutation updates access and refreshes data', () async {
      await controller.loadDashboard();
      final target = controller.accounts.firstWhere(
        (acc) => acc.email == 'tourist@livelocal.com',
      );
      expect(target.accessStatus, 'active');

      final success = await controller.setAccountAccess(
        account: target,
        status: 'restricted',
        publicMessage: 'Policy violation',
        internalReason: 'Spamming comments',
        endsAt: DateTime.now().add(const Duration(days: 7)),
      );

      expect(success, isTrue);
      final updated = controller.accounts.firstWhere(
        (acc) => acc.id == target.id,
      );
      expect(updated.accessStatus, 'restricted');
      expect(
          controller.auditEvents.first.action, 'admin.account_access_changed');
    });

    test('10. moderation decision refreshes data and records audit', () async {
      await controller.loadDashboard();
      final report = controller.moderationCases.first;
      expect(report.status, 'pending');

      final success = await controller.decideModerationCase(
        moderationCase: report,
        decision: 'upheld',
        reason: 'Confirmed inaccurate listing',
      );

      expect(success, isTrue);
      expect(controller.moderationCases.any((c) => c.id == report.id), isFalse);
      expect(
          controller.auditEvents
              .any((a) => a.action == 'admin.moderation_case_upheld'),
          isTrue);
    });

    test('11. appeal decision refreshes data', () async {
      // Seed an appeal in DemoAccountRepository
      await authRepository.signIn(
        email: 'tourist@livelocal.com',
        password: SeedDataService.demoPassword,
      );
      await accountRepository.submitAppeal(
        decisionId: 'dec-1',
        reason: 'mistake',
        explanation: 'I did not violate the rules',
      );

      // Sign back in as admin
      await authRepository.signIn(
        email: 'admin@livelocal.com',
        password: SeedDataService.demoPassword,
      );
      await controller.loadDashboard();
      expect(controller.appeals, isNotEmpty);
      final appeal = controller.appeals.first;

      final success = await controller.decideAppeal(
        appeal: appeal,
        decision: 'upheld',
        reason: 'Account restored after verification',
      );

      expect(success, isTrue);
      await controller.loadDashboard();
      expect(controller.appeals.any((a) => a.id == appeal.id), isFalse);
    });

    test('12. self-account access modification fails safely', () async {
      await controller.loadDashboard();
      final self = controller.accounts.singleWhere(
        (account) => account.email == 'admin@livelocal.com',
      );

      final saved = await controller.setAccountAccess(
        account: self,
        status: 'restricted',
        publicMessage: 'Temporary restriction',
        internalReason: 'Self restriction test',
        endsAt: DateTime.now().add(const Duration(days: 1)),
      );

      expect(saved, isFalse);
      expect(controller.errorMessage, contains('own access'));
    });

    test('13. mutation state returns to idle after error', () async {
      await controller.loadDashboard();
      final self = controller.accounts.singleWhere(
        (account) => account.email == 'admin@livelocal.com',
      );

      await controller.setAccountAccess(
        account: self,
        status: 'restricted',
        publicMessage: 'Temporary restriction',
        internalReason: 'Self restriction test',
      );

      expect(controller.isMutating, isFalse);
      expect(controller.isLoading, isFalse);
    });

    test('14. lastUpdatedAt updates after successful load', () async {
      expect(controller.lastUpdatedAt, isNull);
      await controller.loadDashboard();
      expect(controller.lastUpdatedAt, isNotNull);
      final firstUpdate = controller.lastUpdatedAt!;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await controller.loadDashboard();
      expect(
          controller.lastUpdatedAt!.isAfter(firstUpdate) ||
              controller.lastUpdatedAt == firstUpdate,
          isTrue);
    });
  });
}

class _ReportsFailingAdminRepository extends DemoAdminRepository {
  _ReportsFailingAdminRepository(
    super.authRepository,
    super.accountRepository,
  );

  @override
  Future<List<AdminModerationCase>> fetchModerationCases() async {
    throw Exception('Simulated reports failure');
  }
}
