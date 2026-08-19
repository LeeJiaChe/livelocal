import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/guide_controller.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/guides/data/demo_guide_repository.dart';
import 'package:live_local/features/guides/presentation/submit_guide_screen.dart';
import 'package:live_local/screens/guide_detail_screen.dart';
import 'package:live_local/screens/neighbourhood_explorer_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('NeighbourhoodExplorerScreen UI and Interactions', () {
    late DemoAuthRepository authRepository;
    late DemoGuideRepository guideRepository;
    late AuthController authController;
    late GuideController guideController;

    setUp(() async {
      authRepository = DemoAuthRepository();
      guideRepository = DemoGuideRepository(authRepository);
      authController = AuthController(repository: authRepository);
      guideController = GuideController(repository: guideRepository);
      await Future.wait([
        authController.initialize(),
        guideController.loadGuides(),
      ]);
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authController),
          ChangeNotifierProvider.value(value: guideController),
        ],
        child: const MaterialApp(
          home: NeighbourhoodExplorerScreen(),
        ),
      );
    }

    testWidgets(
        '12-14. SearchBar, State dropdown, and Neighbourhood dropdown exist',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // SearchBar
      expect(find.byType(SearchBar), findsOneWidget);
      expect(find.text('Search guides or neighbourhoods'), findsOneWidget);

      // State Dropdown
      expect(find.text('State or territory'), findsOneWidget);

      // Neighbourhood Dropdown
      expect(find.text('Neighbourhood / area'), findsOneWidget);

      // Submit Guide FAB
      expect(find.text('Submit guide'), findsOneWidget);
    });

    testWidgets('15. selecting neighbourhood changes visible guide cards',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('2 guides found'), findsOneWidget);

      // Select neighbourhood dropdown (second DropdownButtonFormField)
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      expect(dropdowns, findsNWidgets(2));

      await tester.tap(dropdowns.at(1));
      await tester.pumpAndSettle();

      // Tap 'Ipoh Old Town'
      await tester.tap(find.text('Ipoh Old Town').last);
      await tester.pumpAndSettle();

      expect(find.text('1 guide found'), findsOneWidget);
      expect(
          find.text('Ipoh Old Town Heritage & Coffee Crawl'), findsOneWidget);
      expect(find.text('Sunday Morning TTDI Local Neighborhood Trail'),
          findsNothing);
    });

    testWidgets('16. typing search query filters guide cards', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'TTDI');
      await tester.pumpAndSettle();

      expect(find.text('1 guide found'), findsOneWidget);
      expect(find.text('Sunday Morning TTDI Local Neighborhood Trail'),
          findsOneWidget);
      expect(find.text('Ipoh Old Town Heritage & Coffee Crawl'), findsNothing);
    });

    testWidgets('17. Clear filters button restores all results',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Type search
      await tester.enterText(find.byType(SearchBar), 'TTDI');
      await tester.pumpAndSettle();

      expect(find.text('Clear filters'), findsOneWidget);

      // Tap Clear filters
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('2 guides found'), findsOneWidget);
      expect(find.text('Clear filters'), findsNothing);
    });

    testWidgets('18. empty state appears when no guides match filters',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'unmatched query zzz');
      await tester.pumpAndSettle();

      expect(find.text('No matching guides'), findsOneWidget);
      expect(find.text('Try another search, state, or neighbourhood.'),
          findsOneWidget);
      expect(find.text('Clear filters'), findsWidgets);
    });

    testWidgets('19. tapping a guide opens GuideDetailScreen', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester
          .tap(find.text('Sunday Morning TTDI Local Neighborhood Trail'));
      await tester.pumpAndSettle();

      expect(find.byType(GuideDetailScreen), findsOneWidget);
    });

    testWidgets('20. tapping Submit guide FAB opens SubmitGuideScreen',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit guide'));
      await tester.pumpAndSettle();

      expect(find.byType(SubmitGuideScreen), findsOneWidget);
    });
  });
}
