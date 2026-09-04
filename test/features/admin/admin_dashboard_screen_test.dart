import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/admin_controller.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/guide_controller.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/localization/app_localizations.dart';
import 'package:live_local/features/admin/data/demo_admin_repository.dart';
import 'package:live_local/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:live_local/features/admin/presentation/widgets/admin_section_header.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/guides/data/demo_guide_repository.dart';
import 'package:live_local/features/influencer_applications/data/demo_influencer_application_repository.dart';
import 'package:live_local/features/influencer_applications/presentation/influencer_application_controller.dart';
import 'package:live_local/features/profile/data/demo_account_repository.dart';
import 'package:live_local/features/profile/presentation/account_controller.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/models/spot_model.dart';
import 'package:live_local/screens/guide_detail_screen.dart';
import 'package:live_local/services/seed_data_service.dart';
import 'package:provider/provider.dart';

void main() {
  group('Admin Dashboard Screen & Pages Tests', () {
    late DemoAuthRepository authRepository;
    late DemoAccountRepository accountRepository;
    late DemoAdminRepository adminRepository;
    late DemoSpotRepository spotRepository;
    late DemoLocalEatsRepository localEatsRepository;
    late DemoGuideRepository guideRepository;
    late DemoInfluencerApplicationRepository influencerRepository;

    late AuthController authController;
    late AccountController accountController;
    late AdminController adminController;
    late SpotController spotController;
    late LocalEatsController localEatsController;
    late GuideController guideController;
    late InfluencerApplicationController influencerController;

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

      authController = AuthController(repository: authRepository);
      accountController = AccountController(
        repository: accountRepository,
        authController: authController,
      );
      adminController = AdminController(repository: adminRepository);
      spotController = SpotController(repository: spotRepository);
      localEatsController =
          LocalEatsController(repository: localEatsRepository);
      guideController = GuideController(repository: guideRepository);
      influencerController = InfluencerApplicationController(
        repository: influencerRepository,
      );

      await authController.initialize();
      await authController.login(
        'admin@livelocal.com',
        SeedDataService.demoPassword,
      );
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppLocaleController()),
          ChangeNotifierProvider.value(value: authController),
          ChangeNotifierProvider.value(value: accountController),
          ChangeNotifierProvider.value(value: adminController),
          ChangeNotifierProvider.value(value: spotController),
          ChangeNotifierProvider.value(value: localEatsController),
          ChangeNotifierProvider.value(value: guideController),
          ChangeNotifierProvider.value(value: influencerController),
        ],
        child: MaterialApp(
          theme: ThemeData(
            splashFactory: InkRipple.splashFactory,
          ),
          home: const AdminDashboardScreen(),
        ),
      );
    }

    Widget createMobileWidgetUnderTest({required Size size}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppLocaleController()),
          ChangeNotifierProvider.value(value: authController),
          ChangeNotifierProvider.value(value: accountController),
          ChangeNotifierProvider.value(value: adminController),
          ChangeNotifierProvider.value(value: spotController),
          ChangeNotifierProvider.value(value: localEatsController),
          ChangeNotifierProvider.value(value: guideController),
          ChangeNotifierProvider.value(value: influencerController),
        ],
        child: MaterialApp(
          theme: ThemeData(
            splashFactory: InkRipple.splashFactory,
          ),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: MediaQuery(
                data: MediaQueryData(size: size),
                child: const AdminDashboardScreen(),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('15-21. Shell navigation and section switching',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // NavigationRail is used in wide layout
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Admin Center'), findsWidgets);
      expect(find.text('Needs review'), findsOneWidget);

      // Switch to Review Queue
      await tester.tap(find.text('Queue').first);
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(AdminSectionHeader, 'Review Queue'),
        findsOneWidget,
      );

      // Switch to Content
      await tester.tap(find.text('Content').first);
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(AdminSectionHeader, 'Content'),
        findsOneWidget,
      );

      // Switch to Users
      await tester.tap(find.text('Users').first);
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(AdminSectionHeader, 'User Management'),
        findsOneWidget,
      );

      // Switch to More -> Audit History
      await tester.tap(find.text('More').first);
      await tester.pumpAndSettle();
      expect(find.text('Audit History'), findsOneWidget);
    });

    testWidgets('22. non-admin access denied safely', (tester) async {
      await authController.login(
        'tourist@livelocal.com',
        SeedDataService.demoPassword,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        find.text('Administrator permission is required.'),
        findsOneWidget,
      );
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('23-28. Overview metrics, action shortcuts, and quick actions',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Top metrics
      expect(find.text('Needs review'), findsOneWidget);
      expect(find.text('Published content'), findsOneWidget);
      expect(find.text('Total users'), findsOneWidget);
      expect(find.text('Restricted'), findsOneWidget);

      // Action shortcuts
      expect(find.text('Spot submissions'), findsOneWidget);
      expect(find.text('Restaurant submissions'), findsOneWidget);
      expect(find.text('Guide submissions'), findsOneWidget);
      expect(find.text('Creator applications'), findsOneWidget);
      expect(find.text('Content reports'), findsOneWidget);

      // Quick actions
      await tester.scrollUntilVisible(
        find.text('Create guide draft'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Create guide draft'), findsOneWidget);

      // Scroll back up and tap Spot submissions
      await tester.scrollUntilVisible(
        find.widgetWithText(ListTile, 'Spot submissions'),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(ListTile, 'Spot submissions'));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(AdminSectionHeader, 'Review Queue'),
        findsOneWidget,
      );
    });

    testWidgets(
        'an isolated spot queue failure stays in Queue and keeps Overview usable',
        (tester) async {
      spotController = SpotController(
        repository: _FailingPendingSpotRepository(authRepository),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Needs review'), findsOneWidget);
      expect(
        find.text('Pending submissions could not be loaded.'),
        findsNothing,
      );

      await tester.tap(find.text('Queue').first);
      await tester.pumpAndSettle();

      expect(
        find.text('Pending submissions could not be loaded.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
    });

    testWidgets('29-38. Review queue items, filters, and moderation decisions',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Go to Review Queue
      await tester.tap(find.text('Queue').first);
      await tester.pumpAndSettle();

      // Submissions default to one category at a time: Spots.
      expect(find.text('Penang Botanic Gardens'), findsOneWidget);
      expect(find.text('Guan Heong Biscuit Shop'), findsNothing);
      expect(find.text('Jonker Street Evening Food Trail'), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'Restaurants'));
      await tester.pumpAndSettle();
      expect(find.text('Penang Botanic Gardens'), findsNothing);
      expect(find.text('Guan Heong Biscuit Shop'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Guides'));
      await tester.pumpAndSettle();
      expect(find.text('Jonker Street Evening Food Trail'), findsOneWidget);

      // Guide draft should NOT be in review queue
      expect(find.text('George Town Heritage & Murals Draft'), findsNothing);

      // Filter by Reports
      await tester.scrollUntilVisible(
        find.text('Reports'),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();
      expect(find.text('Penang Botanic Gardens'), findsNothing);
      expect(find.textContaining('Unverified business hours'), findsOneWidget);

      // Return to spot submissions.
      await tester.tap(find.widgetWithText(FilterChip, 'Submissions'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Spots'));
      await tester.pumpAndSettle();

      // Approve Spot
      await tester.tap(find.widgetWithText(FilledButton, 'Approve').first);
      await tester.pumpAndSettle();

      // Reason dialog is shown
      expect(find.text('Approve spot?'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Verified spot location and description on site.',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();

      // Spot is now approved and removed from pending review queue
      expect(find.text('Penang Botanic Gardens'), findsNothing);
    });

    testWidgets(
        '39-45. Guide management drafts, published, publish and archive',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Go to Content tab and open Guides segment
      await tester.tap(find.text('Content').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guides').first);
      await tester.pumpAndSettle();

      // Admin Drafts section
      expect(find.text('George Town Heritage & Murals Draft'), findsOneWidget);
      expect(find.text('Jonker Street Evening Food Trail'), findsNothing);

      // Publish draft
      await tester.tap(find.widgetWithText(FilledButton, 'Publish').first);
      await tester.pumpAndSettle();

      expect(find.text('Publish this guide?'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Verified all stops and walking route accuracy.',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();

      // Switch to Published tab
      await tester.tap(find.byType(FilterChip).last);
      await tester.pumpAndSettle();

      expect(
        find.text('Sunday Morning TTDI Local Neighborhood Trail'),
        findsOneWidget,
      );

      // Tap on published guide to open detail screen
      await tester
          .tap(find.text('Sunday Morning TTDI Local Neighborhood Trail'));
      await tester.pumpAndSettle();
      expect(find.byType(GuideDetailScreen), findsOneWidget);

      // Pop back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Archive guide
      await tester.tap(find.widgetWithText(OutlinedButton, 'Archive').first);
      await tester.pumpAndSettle();
      expect(find.text('Archive this guide?'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Route is undergoing renovation and construction.',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();

      // Re-render
      expect(
        find.text('Sunday Morning TTDI Local Neighborhood Trail'),
        findsNothing,
      );
    });

    testWidgets('46-52. Users management search, filters, and account access',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Go to Users tab
      await tester.tap(find.text('Users').first);
      await tester.pumpAndSettle();

      // Search by display name
      await tester.enterText(find.byType(SearchBar), 'Alex');
      await tester.pumpAndSettle();

      expect(find.text('Alex Tan (Tourist)'), findsOneWidget);
      expect(find.text('KL Foodie (Influencer)'), findsNothing);

      // Clear search
      await tester.enterText(find.byType(SearchBar), '');
      await tester.pumpAndSettle();

      // Admin self lock icon
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      // Manage tourist account access
      final touristMenu = find.widgetWithIcon(
        PopupMenuButton<String>,
        Icons.more_vert,
      );
      if (touristMenu.evaluate().isNotEmpty) {
        await tester.tap(touristMenu.first);
        await tester.pumpAndSettle();

        expect(find.text('Temporarily restrict'), findsOneWidget);
        expect(find.text('Permanently ban'), findsOneWidget);
      }
    });

    testWidgets('53-56. Audit history renders and search works',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Go to More -> Audit History
      await tester.tap(find.text('More').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Audit History'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(AdminSectionHeader, 'Audit History'),
        findsOneWidget,
      );
      expect(
        find.textContaining('admin · platform_initialized'),
        findsOneWidget,
      );
      expect(find.textContaining('System Admin'), findsOneWidget);

      // Search
      await tester.enterText(find.byType(SearchBar), 'platform');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('admin · platform_initialized'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(SearchBar), 'nonexistent search');
      await tester.pumpAndSettle();
      expect(find.text('No audit records'), findsOneWidget);
    });

    testWidgets('J1. Mobile viewport 360x640 no overflows', (tester) async {
      await tester.pumpWidget(
        createMobileWidgetUnderTest(size: const Size(360, 640)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.tap(
        find.widgetWithText(NavigationDestination, 'Queue'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Content'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Users'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(NavigationDestination, 'More'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('J2. Mobile viewport 390x844 no overflows', (tester) async {
      await tester.pumpWidget(
        createMobileWidgetUnderTest(size: const Size(390, 844)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.tap(
        find.widgetWithText(NavigationDestination, 'Queue'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Content'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Users'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(NavigationDestination, 'More'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('J3. Mobile viewport 412x915 no overflows', (tester) async {
      await tester.pumpWidget(
        createMobileWidgetUnderTest(size: const Size(412, 915)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.tap(
        find.widgetWithText(NavigationDestination, 'Queue'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Content'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Users'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(NavigationDestination, 'More'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

class _FailingPendingSpotRepository extends DemoSpotRepository {
  _FailingPendingSpotRepository(super.authRepository);

  @override
  Future<List<SpotModel>> fetchPendingModeration() async {
    throw Exception('Simulated isolated queue failure');
  }
}
