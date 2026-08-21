import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/controllers/auth_controller.dart';
import 'package:live_local/controllers/itinerary_controller.dart';
import 'package:live_local/controllers/localeats_controller.dart';
import 'package:live_local/controllers/spot_controller.dart';
import 'package:live_local/core/routing/protected_navigation.dart';
import 'package:live_local/features/auth/data/demo_auth_repository.dart';
import 'package:live_local/features/itinerary/data/demo_saved_itinerary_repository.dart';
import 'package:live_local/features/restaurants/data/demo_local_eats_repository.dart';
import 'package:live_local/features/spots/data/demo_spot_repository.dart';
import 'package:live_local/shared/presentation/save_to_collection_sheet.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SaveToCollectionSheet Redesign Tests', () {
    late DemoAuthRepository authRepo;
    late DemoSavedItineraryRepository savedRepo;
    late DemoSpotRepository spotRepo;
    late DemoLocalEatsRepository eatsRepo;
    late AuthController authCtrl;
    late ItineraryController itineraryCtrl;
    late SpotController spotCtrl;
    late LocalEatsController eatsCtrl;
    late ProtectedNavigation protectedNav;

    setUp(() async {
      authRepo = DemoAuthRepository();
      savedRepo = DemoSavedItineraryRepository(authRepo);
      spotRepo = DemoSpotRepository(authRepo);
      eatsRepo = DemoLocalEatsRepository(authRepo);

      authCtrl = AuthController(repository: authRepo);
      itineraryCtrl = ItineraryController(repository: savedRepo);
      spotCtrl = SpotController(repository: spotRepo);
      eatsCtrl = LocalEatsController(repository: eatsRepo);
      protectedNav = ProtectedNavigation();

      await authCtrl.initialize();
      await authCtrl.login('tourist@livelocal.com', '123456');
      await itineraryCtrl.loadCollections();
      await spotCtrl.loadSpots();
    });

    Widget createSheetUnderTest({
      required String targetType,
      required String targetId,
      required String placeName,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authCtrl),
          ChangeNotifierProvider.value(value: itineraryCtrl),
          ChangeNotifierProvider.value(value: spotCtrl),
          ChangeNotifierProvider.value(value: eatsCtrl),
          Provider<ProtectedNavigation>.value(value: protectedNav),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SaveToCollectionSheet(
              targetType: targetType,
              targetId: targetId,
              placeName: placeName,
            ),
          ),
        ),
      );
    }

    testWidgets(
        '1. Unsaved place with 0 selections shows disabled "Select a collection"',
        (tester) async {
      final unsavedSpot = spotCtrl.spots.last;

      await tester.pumpWidget(createSheetUnderTest(
        targetType: 'spot',
        targetId: unsavedSpot.id,
        placeName: unsavedSpot.name,
      ));
      await tester.pumpAndSettle();

      // Verify button says "Select a collection" and is disabled
      final btnFinder =
          find.widgetWithText(FilledButton, 'Select a collection');
      expect(btnFinder, findsOneWidget);
      final FilledButton button = tester.widget(btnFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('2. Unsaved place selecting 1 collection enables "Save" button',
        (tester) async {
      final unsavedSpot = spotCtrl.spots.last;

      await tester.pumpWidget(createSheetUnderTest(
        targetType: 'spot',
        targetId: unsavedSpot.id,
        placeName: unsavedSpot.name,
      ));
      await tester.pumpAndSettle();

      // Tap first collection row
      final firstCol = itineraryCtrl.collections.first;
      final colFinder = find.text(firstCol.name);
      expect(colFinder, findsOneWidget);
      await tester.tap(colFinder);
      await tester.pumpAndSettle();

      // Verify button says "Save" and is enabled
      final btnFinder = find.widgetWithText(FilledButton, 'Save');
      expect(btnFinder, findsOneWidget);
      final FilledButton button = tester.widget(btnFinder);
      expect(button.onPressed, isNotNull);

      // Tap Save
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      // Place should now be saved
      expect(itineraryCtrl.isSaved(spotId: unsavedSpot.id), isTrue);
    });

    testWidgets('3. Saved place with no changes shows disabled "No changes"',
        (tester) async {
      // First save a spot
      final spot = spotCtrl.spots.first;
      final defaultCol = itineraryCtrl.collections.first;
      await itineraryCtrl.setPlaceCollections(
        targetType: 'spot',
        targetId: spot.id,
        collectionIds: [defaultCol.id],
      );

      await tester.pumpWidget(createSheetUnderTest(
        targetType: 'spot',
        targetId: spot.id,
        placeName: spot.name,
      ));
      await tester.pumpAndSettle();

      // Button should say "No changes" and be disabled
      final btnFinder = find.widgetWithText(FilledButton, 'No changes');
      expect(btnFinder, findsOneWidget);
      final FilledButton button = tester.widget(btnFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets(
        '4. Saved place deselecting all collections shows "Remove from Saved"',
        (tester) async {
      final spot = spotCtrl.spots.first;
      final defaultCol = itineraryCtrl.collections.first;
      await itineraryCtrl.setPlaceCollections(
        targetType: 'spot',
        targetId: spot.id,
        collectionIds: [defaultCol.id],
      );

      await tester.pumpWidget(createSheetUnderTest(
        targetType: 'spot',
        targetId: spot.id,
        placeName: spot.name,
      ));
      await tester.pumpAndSettle();

      // Deselect the collection
      final colFinder = find.text(defaultCol.name);
      expect(colFinder, findsOneWidget);
      await tester.tap(colFinder);
      await tester.pumpAndSettle();

      // Button should say "Remove from Saved" and be enabled
      final btnFinder = find.widgetWithText(FilledButton, 'Remove from Saved');
      expect(btnFinder, findsOneWidget);
      final FilledButton button = tester.widget(btnFinder);
      expect(button.onPressed, isNotNull);

      // Tap Remove from Saved
      await tester.tap(btnFinder);
      await tester.pumpAndSettle();

      expect(itineraryCtrl.isSaved(spotId: spot.id), isFalse);
    });

    testWidgets(
        '5. Create Collection dialog opens, types name, cancels safely without error',
        (tester) async {
      final spot = spotCtrl.spots.first;

      await tester.pumpWidget(createSheetUnderTest(
        targetType: 'spot',
        targetId: spot.id,
        placeName: spot.name,
      ));
      await tester.pumpAndSettle();

      // Tap "New collection"
      final newColFinder = find.byTooltip('New collection');
      expect(newColFinder, findsOneWidget);
      await tester.tap(newColFinder);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('New collection'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Penang Food Trip');
      await tester.pumpAndSettle();

      // Cancel dialog
      final dialogCancelFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Cancel'),
      );
      await tester.tap(dialogCancelFinder);
      await tester.pumpAndSettle();

      // Verify dialog is dismissed and sheet is intact without exception
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Save to a collection'), findsOneWidget);
    });

    testWidgets(
        '6. Create Collection dialog creates collection, adds it, and selects it',
        (tester) async {
      final spot = spotCtrl.spots.first;

      await tester.pumpWidget(createSheetUnderTest(
        targetType: 'spot',
        targetId: spot.id,
        placeName: spot.name,
      ));
      await tester.pumpAndSettle();

      // Tap "New collection"
      await tester.tap(find.byTooltip('New collection'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Unique Cafes');
      await tester.pumpAndSettle();

      // Tap Create
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // New collection should appear and be selected
      expect(find.text('Unique Cafes'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });
  });
}
