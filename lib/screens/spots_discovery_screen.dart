import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_spacing.dart';
import '../controllers/itinerary_controller.dart';
import '../controllers/spot_controller.dart';
import '../core/routing/protected_navigation.dart';
import '../models/spot_model.dart';
import '../shared/presentation/app_state_view.dart';
import '../shared/presentation/save_to_collection_sheet.dart';
import 'spot_detail_screen.dart';

class SpotsDiscoveryScreen extends StatefulWidget {
  const SpotsDiscoveryScreen({super.key});

  @override
  State<SpotsDiscoveryScreen> createState() => _SpotsDiscoveryScreenState();
}

class _SpotsDiscoveryScreenState extends State<SpotsDiscoveryScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showStateSelector(BuildContext context, SpotController controller) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x2,
            0,
            AppSpacing.x2,
            AppSpacing.x2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x2,
                  vertical: AppSpacing.x1,
                ),
                child: Text(
                  'Select state or territory',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: controller.filterOptions.states.map((opt) {
                    final isSelected = controller.selectedState == opt.rawValue;
                    return ListTile(
                      title: Text(
                        opt.displayName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        controller.filter(state: opt.rawValue);
                        Navigator.pop(sheetCtx);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SpotController>();
    final spots = controller.approvedSpots;
    final categories = controller.filterOptions.categories;
    final hasActiveFilters = controller.hasActiveFilters;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.loadSpots,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x2,
                  AppSpacing.x2,
                  AppSpacing.x2,
                  AppSpacing.x1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover Malaysia like a local',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Explore authentic heritage, nature, and cultural places recommended by local communities.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    SearchBar(
                      controller: _search,
                      hintText: context.tr('Search places, heritage, or towns'),
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (_search.text.isNotEmpty)
                          IconButton(
                            tooltip: context.tr('Clear search'),
                            onPressed: () {
                              setState(_search.clear);
                              controller.filter(query: '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {});
                        controller.filter(query: value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    // Filter bar: State filter button + Category horizontal chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ActionChip(
                            avatar: Icon(
                              Icons.location_on_outlined,
                              size: 18,
                              color: controller.selectedState != 'All'
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                            ),
                            label: Text(controller.selectedStateDisplayName),
                            backgroundColor: controller.selectedState != 'All'
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            labelStyle: TextStyle(
                              color: controller.selectedState != 'All'
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                              fontWeight: controller.selectedState != 'All'
                                  ? FontWeight.w600
                                  : null,
                            ),
                            onPressed: () =>
                                _showStateSelector(context, controller),
                          ),
                          const SizedBox(width: AppSpacing.x1),
                          ...categories.map((cat) {
                            final isSelected =
                                controller.selectedCategory == cat;
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.x1),
                              child: FilterChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (_) =>
                                    controller.filter(category: cat),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${spots.length} ${spots.length == 1 ? 'place' : 'places'} found',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        if (hasActiveFilters)
                          TextButton.icon(
                            icon: const Icon(Icons.filter_alt_off_outlined,
                                size: 16),
                            label: const Text('Clear filters'),
                            onPressed: () {
                              setState(_search.clear);
                              controller.resetFilters();
                            },
                          ),
                      ],
                    ),
                    if (controller.errorMessage != null && spots.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.x1),
                        child: Text(
                          controller.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (controller.isLoading && spots.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.all(AppSpacing.x2),
                sliver: _SpotLoadingSliver(),
              )
            else if (controller.errorMessage != null && spots.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppStateView(
                  icon: Icons.cloud_off_outlined,
                  title: 'Places could not be loaded',
                  message: controller.errorMessage!,
                  actionLabel: context.tr('Try again'),
                  onAction: controller.loadSpots,
                ),
              )
            else if (spots.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppStateView(
                  icon: Icons.travel_explore_outlined,
                  title: 'No matching places',
                  message: 'Try another search, category, or state filter.',
                  actionLabel: context.tr('Clear filters'),
                  onAction: () {
                    setState(_search.clear);
                    controller.resetFilters();
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x2,
                  AppSpacing.x1,
                  AppSpacing.x2,
                  112,
                ),
                sliver: SliverList.separated(
                  itemCount: spots.length + 1,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.x2),
                  itemBuilder: (context, index) {
                    if (index == spots.length) {
                      return Center(
                        child: controller.isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(AppSpacing.x2),
                                child: CircularProgressIndicator(),
                              )
                            : OutlinedButton(
                                onPressed: controller.hasMore
                                    ? controller.loadMore
                                    : null,
                                child: Text(
                                  controller.hasMore
                                      ? 'Load more places'
                                      : 'All places loaded',
                                ),
                              ),
                      );
                    }
                    return _SpotCard(spot: spots[index]);
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'spots_discovery_fab',
        onPressed: () =>
            context.read<ProtectedNavigation>().open(context, '/submit-spot'),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Share a local place'),
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  const _SpotCard({required this.spot});

  final SpotModel spot;

  @override
  Widget build(BuildContext context) {
    final itineraryCtrl = context.watch<ItineraryController>();
    final isSaved = itineraryCtrl.isSaved(spotId: spot.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => SpotDetailScreen(spot: spot)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: spot.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => ColoredBox(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (_, __, ___) => ColoredBox(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Center(
                        child:
                            Icon(Icons.image_not_supported_outlined, size: 48),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        color: isSaved
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      tooltip: context.tr(
                        isSaved ? 'Saved to collections' : 'Save to collection',
                      ),
                      onPressed: () => SaveToCollectionSheet.show(
                        context,
                        targetType: 'spot',
                        targetId: spot.id,
                        placeName: spot.name,
                        spot: spot,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      spot.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          spot.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      if (spot.reviewCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                size: 16, color: Color(0xFFFFD700)),
                            const SizedBox(width: 2),
                            Text(
                              spot.rating.toStringAsFixed(1),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${spot.city}, ${spot.state} · ${spot.priceRange}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    spot.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotLoadingSliver extends StatelessWidget {
  const _SpotLoadingSliver();

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x2),
      itemBuilder: (_, __) => Container(
        height: 280,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
