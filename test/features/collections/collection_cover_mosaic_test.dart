import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/models/saved_collection_model.dart';
import 'package:live_local/shared/presentation/collection_cover_mosaic.dart';

void main() {
  for (final count in [0, 1, 2, 3, 4, 5, 10]) {
    testWidgets('$count collection items render at most four mosaic tiles', (
      tester,
    ) async {
      final items = List.generate(count, _coverItem);
      final model = _collection(items);
      await _pumpMosaic(tester, model.coverItems);

      final expected = count > 4 ? 4 : count;
      for (var index = 0; index < expected; index += 1) {
        expect(
          find.byKey(Key('collection_cover_tile_$index')),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(Key('collection_cover_tile_$expected')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('collection_cover_empty')),
        count == 0 ? findsOneWidget : findsNothing,
      );
      expect(find.byType(CachedNetworkImage), findsNWidgets(expected));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mixed item types keep a missing-image logical fallback slot', (
    tester,
  ) async {
    final items = [
      _coverItem(0, targetType: 'spot'),
      _coverItem(1, targetType: 'restaurant', missingImage: true),
      _coverItem(2, targetType: 'external'),
      _coverItem(3, targetType: 'spot'),
    ];
    await _pumpMosaic(tester, items);

    expect(find.byKey(const Key('collection_cover_tile_1')), findsOneWidget);
    expect(
      find.byKey(const Key('collection_cover_fallback_1')),
      findsOneWidget,
    );
    expect(find.byType(CachedNetworkImage), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('membership removal promotes the next stable ordered item', (
    tester,
  ) async {
    final first = List.generate(5, _coverItem);
    await _pumpMosaic(tester, _collection(first).coverItems);
    expect(
      find.byKey(const ValueKey('collection_cover_item_place-0')),
      findsOneWidget,
    );

    final afterRemoval = first.sublist(1);
    await _pumpMosaic(tester, _collection(afterRemoval).coverItems);
    expect(
      find.byKey(const ValueKey('collection_cover_item_place-0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('collection_cover_item_place-4')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('RPC model parsing preserves order and caps previews at four', () {
    final model = SavedCollectionModel.fromMap({
      'id': 'collection-1',
      'user_id': 'user-1',
      'name': 'Malaysia trip',
      'item_count': 10,
      'created_at': '2026-08-29T00:00:00Z',
      'updated_at': '2026-08-29T00:00:00Z',
      'cover_items': List.generate(
        10,
        (index) => {
          'target_type': index == 1
              ? 'restaurant'
              : index == 2
                  ? 'external'
                  : 'spot',
          'target_id': 'place-$index',
          'external_provider': index == 2 ? 'google' : null,
          'image_path': index == 1 ? null : 'images/$index.jpg',
        },
      ),
    });

    expect(model.itemCount, 10);
    expect(model.coverItems, hasLength(4));
    expect(
      model.coverItems.map((item) => item.targetId),
      ['place-0', 'place-1', 'place-2', 'place-3'],
    );
    expect(model.coverItems[1].imagePath, isNull);
    expect(model.coverItems[2].externalProvider, 'google');
  });
}

SavedCollectionModel _collection(List<CollectionCoverItem> items) =>
    SavedCollectionModel(
      id: 'collection-1',
      userId: 'user-1',
      name: 'Malaysia trip',
      itemCount: items.length,
      coverItems: items,
      createdAt: DateTime(2026, 8, 29),
      updatedAt: DateTime(2026, 8, 29),
    );

CollectionCoverItem _coverItem(
  int index, {
  String targetType = 'spot',
  bool missingImage = false,
}) =>
    CollectionCoverItem(
      targetType: targetType,
      targetId: 'place-$index',
      externalProvider: targetType == 'external' ? 'google' : null,
      imageUrl: missingImage ? null : 'https://example.test/$index.jpg',
    );

Future<void> _pumpMosaic(
  WidgetTester tester,
  List<CollectionCoverItem> items,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            height: 180,
            child: CollectionCoverMosaic(items: items),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
