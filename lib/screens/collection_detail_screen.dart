import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_spacing.dart';
import '../controllers/itinerary_controller.dart';
import '../controllers/localeats_controller.dart';
import '../controllers/spot_controller.dart';
import '../models/saved_collection_model.dart';
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
    await Future.wait([
      controller.loadActiveCollectionPlaces(_currentCollection.id),
      controller.loadActiveCollectionItems(_currentCollection.id),
    ]);
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
              decoration: InputDecoration(
                labelText: context.tr('Collection name'),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.x2),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: context.tr('Description (optional)'),
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

  Future<void> _removeFromCollection(SavedCollectionPlace place) async {
    final controller = context.read<ItineraryController>();
    List<String> currentMemberships;
    try {
      currentMemberships = await controller.fetchPlaceCollectionIds(
        targetType: place.targetType,
        targetId: place.targetId,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ??
                'Could not load memberships to remove place.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final newMemberships =
        currentMemberships.where((id) => id != _currentCollection.id).toList();

    try {
      await controller.setPlaceCollections(
        targetType: place.targetType,
        targetId: place.targetId,
        collectionIds: newMemberships,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Removed "${place.name}" from ${_currentCollection.name}'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ??
                'Could not remove place from collection.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _planRouteFromCollection() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ItineraryScreen(initialCollectionId: _currentCollection.id),
      ),
    );
  }

  Future<void> _openPlaceDetail(SavedCollectionPlace place) async {
    if (place.isSpot) {
      final spotCtrl = context.read<SpotController>();
      final spot = await spotCtrl.fetchSpotById(place.targetId);
      if (!mounted) return;
      if (spot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This place is no longer publicly available.'),
          ),
        );
        return;
      }
      Navigator.pushNamed(
        context,
        '/spot-detail',
        arguments: SpotDetailArguments(spot: spot),
      );
    } else {
      final eatsCtrl = context.read<LocalEatsController>();
      final restaurant = await eatsCtrl.fetchRestaurantById(place.targetId);
      if (!mounted) return;
      if (restaurant == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This place is no longer publicly available.'),
          ),
        );
        return;
      }
      Navigator.pushNamed(
        context,
        '/restaurant-detail',
        arguments: RestaurantDetailArguments(restaurant: restaurant),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final itineraryCtrl = context.watch<ItineraryController>();
    final places = itineraryCtrl.activeCollectionPlaces;
    final totalCount = places.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCollection.name),
        actions: [
          IconButton(
            tooltip: context.tr('Rename'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showRenameDialog,
          ),
          IconButton(
            tooltip: context.tr('Delete'),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$totalCount ${totalCount == 1 ? 'place' : 'places'} saved',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            if (totalCount > 0)
                              FilledButton.tonalIcon(
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
                if (places.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppStateView(
                      icon: Icons.bookmark_border_rounded,
                      title: 'No places in this collection',
                      message:
                          'Explore spots and restaurants and save them to "${_currentCollection.name}".',
                      actionLabel: context.tr('Discover places'),
                      onAction: () => Navigator.pop(context),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x2,
                      0,
                      AppSpacing.x2,
                      AppSpacing.x4,
                    ),
                    sliver: SliverList.separated(
                      itemCount: places.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.x2),
                      itemBuilder: (context, index) {
                        final place = places[index];
                        return _buildCollectionPlaceCard(place);
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildCollectionPlaceCard(SavedCollectionPlace place) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () => _openPlaceDetail(place),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: place.imageUrl != null && place.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: place.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              place.isSpot
                                  ? Icons.place_outlined
                                  : Icons.restaurant_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            place.isSpot
                                ? Icons.place_outlined
                                : Icons.restaurant_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              // Place info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: place.isSpot
                                ? colorScheme.primaryContainer
                                : colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            place.categoryOrCuisine,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: place.isSpot
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (place.priceRange != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            place.priceRange!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${place.city}, ${place.state}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (place.rating > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFE5A93C),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            place.rating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (place.reviewCount > 0)
                            Text(
                              ' (${place.reviewCount})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_remove_outlined, size: 20),
                tooltip: context.tr('Remove from collection'),
                color: colorScheme.onSurfaceVariant,
                onPressed: () => _removeFromCollection(place),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
