import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/saved_collection_model.dart';

class CollectionCoverMosaic extends StatelessWidget {
  const CollectionCoverMosaic({
    super.key,
    required this.items,
  });

  static const double _gutter = 2;
  final List<CollectionCoverItem> items;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(4).toList(growable: false);
    if (visible.isEmpty) {
      return _empty(context);
    }
    return ColoredBox(
      key: const Key('collection_cover_mosaic'),
      color: Theme.of(context).colorScheme.surface,
      child: switch (visible.length) {
        1 => _tile(context, visible[0], 0),
        2 => Row(
            children: [
              Expanded(child: _tile(context, visible[0], 0)),
              const SizedBox(width: _gutter),
              Expanded(child: _tile(context, visible[1], 1)),
            ],
          ),
        3 => Row(
            children: [
              Expanded(child: _tile(context, visible[0], 0)),
              const SizedBox(width: _gutter),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _tile(context, visible[1], 1)),
                    const SizedBox(height: _gutter),
                    Expanded(child: _tile(context, visible[2], 2)),
                  ],
                ),
              ),
            ],
          ),
        _ => Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _tile(context, visible[0], 0)),
                    const SizedBox(width: _gutter),
                    Expanded(child: _tile(context, visible[1], 1)),
                  ],
                ),
              ),
              const SizedBox(height: _gutter),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _tile(context, visible[2], 2)),
                    const SizedBox(width: _gutter),
                    Expanded(child: _tile(context, visible[3], 3)),
                  ],
                ),
              ),
            ],
          ),
      },
    );
  }

  Widget _tile(
    BuildContext context,
    CollectionCoverItem item,
    int index,
  ) {
    final imageUrl = item.imageUrl?.trim();
    return SizedBox.expand(
      key: Key('collection_cover_tile_$index'),
      child: KeyedSubtree(
        key: ValueKey('collection_cover_item_${item.targetId}'),
        child: imageUrl?.isNotEmpty == true
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                placeholder: (_, __) => _fallback(context, item, index),
                errorWidget: (_, __, ___) => _fallback(context, item, index),
              )
            : _fallback(context, item, index),
      ),
    );
  }

  Widget _fallback(
    BuildContext context,
    CollectionCoverItem item,
    int index,
  ) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (item.targetType) {
      'restaurant' => Icons.restaurant_outlined,
      'external' => Icons.travel_explore_outlined,
      _ => Icons.place_outlined,
    };
    return ColoredBox(
      key: Key('collection_cover_fallback_$index'),
      color: colors.secondaryContainer,
      child: Center(
        child: Icon(icon, color: colors.onSecondaryContainer),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      key: const Key('collection_cover_empty'),
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.collections_bookmark_outlined,
          size: 36,
          color: colors.primary,
        ),
      ),
    );
  }
}
