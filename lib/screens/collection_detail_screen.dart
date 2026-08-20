import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_spacing.dart';
import '../controllers/itinerary_controller.dart';
import '../controllers/localeats_controller.dart';
import '../controllers/spot_controller.dart';
import '../models/restaurant_model.dart';
import '../models/saved_collection_model.dart';
import '../models/spot_model.dart';
import '../shared/presentation/app_state_view.dart';
import 'itinerary_screen.dart';
import 'restaurant_detail_screen.dart';
import 'spot_detail_screen.dart';

class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({
    super.key,
    required this.collection,
  });

  final SavedCollectionModel collection;

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  late SavedCollectionModel _currentCollection;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentCollection = widget.collection;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadItems());
  }

  Future<void> _loadItems() async {
    final controller = context.read<ItineraryController>();
    controller.setActiveCollection(_currentCollection);
    await controller.loadActiveCollectionItems(_currentCollection.id);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _showRenameDialog() async {
    final nameCtrl = TextEditingController(text: _currentCollection.name);
    final descCtrl =
        TextEditingController(text: _currentCollection.description ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Rename collection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Collection name',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.x2),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(dialogCtx, {
                  'name': name,
                  'description': descCtrl.text.trim(),
                });
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    descCtrl.dispose();

    if (result != null && mounted) {
      final controller = context.read<ItineraryController>();
      final updated = await controller.renameCollection(
        collectionId: _currentCollection.id,
        name: result['name']!,
        description: result['description'],
      );
      if (updated != null && mounted) {
        setState(() => _currentCollection = updated);
      }
    }
  }

  Future<void> _showDeleteConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete collection?'),
        content: Text(
          'Are you sure you want to delete "${_currentCollection.name}"? Places inside will remain in any other collections.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final controller = context.read<ItineraryController>();
      final deleted = await controller.deleteCollection(_currentCollection.id);
      if (deleted && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted "${_currentCollection.name}"')),
        );
      }
    }
  }

  Future<void> _removeFromCollection(
    String targetType,
    String targetId,
    String placeName,
  ) async {
    final controller = context.read<ItineraryController>();
    final currentMemberships = await controller.fetchPlaceCollectionIds(
      targetType: targetType,
      targetId: targetId,
    );
    final newMemberships =
        currentMemberships.where((id) => id != _currentCollection.id).toList();

    final success = await controller.setPlaceCollections(
      targetType: targetType,
      targetId: targetId,
      collectionIds: newMemberships,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "$placeName" from ${_currentCollection.name}'),
        ),
      );
    }
  }

  void _planRouteFromCollection() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const ItineraryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itineraryCtrl = context.watch<ItineraryController>();
    final spotCtrl = context.watch<SpotController>();
    final eatsCtrl = context.watch<LocalEatsController>();

    final allSpots = spotCtrl.spots;
    final allRestaurants = eatsCtrl.restaurants;
    final items = itineraryCtrl.activeCollectionItems;

    // Resolve models for collection items
    final resolvedSpots = <SpotModel>[];
    final resolvedRestaurants = <RestaurantModel>[];

    for (final item in items) {
      if (item.spotId != null) {
        final matches = allSpots.where((s) => s.id == item.spotId);
        if (matches.isNotEmpty) resolvedSpots.add(matches.first);
      } else if (item.restaurantId != null) {
        final matches = allRestaurants.where((r) => r.id == item.restaurantId);
        if (matches.isNotEmpty) resolvedRestaurants.add(matches.first);
      }
    }

    final totalCount = resolvedSpots.length + resolvedRestaurants.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCollection.name),
        actions: [
          IconButton(
            tooltip: 'Rename',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showRenameDialog,
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: _showDeleteConfirm,
          ),
          const SizedBox(width: AppSpacing.x1),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x2,
                      AppSpacing.x1,
                      AppSpacing.x2,
                      AppSpacing.x2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_currentCollection.description != null &&
                            _currentCollection.description!.isNotEmpty) ...[
                          Text(
                            _currentCollection.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.x2),
                        ],
                        Row(
                          children: [
                            Chip(
                              avatar: const Icon(Icons.bookmark, size: 18),
                              label: Text(
                                '$totalCount ${totalCount == 1 ? "place" : "places"}',
                              ),
                            ),
                            const Spacer(),
                            if (totalCount > 0)
                              FilledButton.icon(
                                onPressed: _planRouteFromCollection,
                                icon:
                                    const Icon(Icons.route_outlined, size: 18),
                                label: const Text('Plan route'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (totalCount == 0)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppStateView(
                      icon: Icons.bookmark_border_outlined,
                      title: 'No places in this collection',
                      message:
                          'Explore spots and restaurants, then tap the bookmark icon to add them to "${_currentCollection.name}".',
                      actionLabel: 'Explore spots',
                      onAction: () => Navigator.pop(context),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x2,
                      0,
                      AppSpacing.x2,
                      AppSpacing.x5,
                    ),
                    sliver: SliverList.separated(
                      itemCount:
                          resolvedSpots.length + resolvedRestaurants.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.x2),
                      itemBuilder: (context, index) {
                        if (index < resolvedSpots.length) {
                          final spot = resolvedSpots[index];
                          return _CollectionSpotCard(
                            spot: spot,
                            onRemove: () => _removeFromCollection(
                              'spot',
                              spot.id,
                              spot.name,
                            ),
                          );
                        } else {
                          final restaurant =
                              resolvedRestaurants[index - resolvedSpots.length];
                          return _CollectionRestaurantCard(
                            restaurant: restaurant,
                            onRemove: () => _removeFromCollection(
                              'restaurant',
                              restaurant.id,
                              restaurant.name,
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CollectionSpotCard extends StatelessWidget {
  const _CollectionSpotCard({
    required this.spot,
    required this.onRemove,
  });

  final SpotModel spot;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => SpotDetailScreen(spot: spot),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CachedNetworkImage(
                imageUrl: spot.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.place_outlined, size: 36),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${spot.category} · ${spot.city}, ${spot.state}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spot.priceRange,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remove from collection',
              icon: const Icon(Icons.bookmark_remove_outlined),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionRestaurantCard extends StatelessWidget {
  const _CollectionRestaurantCard({
    required this.restaurant,
    required this.onRemove,
  });

  final RestaurantModel restaurant;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CachedNetworkImage(
                imageUrl: restaurant.coverPhotoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.restaurant_outlined, size: 36),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${restaurant.cuisineType} · ${restaurant.city}, ${restaurant.state}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.priceRange,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remove from collection',
              icon: const Icon(Icons.bookmark_remove_outlined),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
