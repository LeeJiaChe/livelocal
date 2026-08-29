import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../controllers/guide_controller.dart';
import '../../../controllers/localeats_controller.dart';
import '../../../controllers/spot_controller.dart';
import '../../../models/guide_model.dart';
import '../../../models/restaurant_model.dart';
import '../../../models/spot_model.dart';
import '../../../screens/guide_detail_screen.dart';
import '../../../screens/localeats_screen.dart';
import '../../../screens/neighbourhood_explorer_screen.dart';
import '../../../screens/restaurant_detail_screen.dart';
import '../../../screens/spot_detail_screen.dart';
import '../../../screens/spots_discovery_screen.dart';
import '../../places/data/supabase_google_places_provider.dart';
import '../../places/domain/place_provider.dart';
import '../../places/presentation/external_places_screen.dart';
import '../../places/presentation/place_discovery_controller.dart';

class ExploreHubScreen extends StatelessWidget {
  const ExploreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final existingController =
        Provider.of<PlaceDiscoveryController?>(context, listen: false);
    if (existingController != null) return const _ExploreTabs();

    final existingProvider = Provider.of<PlaceProvider?>(
      context,
      listen: false,
    );
    final provider = existingProvider ?? const UnavailablePlaceProvider();
    return MultiProvider(
      providers: [
        if (existingProvider == null)
          Provider<PlaceProvider>.value(value: provider),
        ChangeNotifierProvider(
          create: (_) => PlaceDiscoveryController(provider: provider),
        ),
      ],
      child: const _ExploreTabs(),
    );
  }
}

class _ExploreTabs extends StatelessWidget {
  const _ExploreTabs();

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 5,
        child: Scaffold(
          body: Builder(
            builder: (tabContext) => Column(
              children: [
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: const TabBar(
                    key: Key('explore_section_tabs'),
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelPadding: EdgeInsets.symmetric(horizontal: 18),
                    tabs: [
                      Tab(child: Text('All', maxLines: 1)),
                      Tab(child: Text('Places', maxLines: 1)),
                      Tab(child: Text('Spots', maxLines: 1)),
                      Tab(child: Text('Eats', maxLines: 1)),
                      Tab(child: Text('Guides', maxLines: 1)),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _ExploreAllScreen(
                        onSelectTab: (index) =>
                            DefaultTabController.of(tabContext)
                                .animateTo(index),
                      ),
                      const ExternalPlacesScreen(),
                      const SpotsDiscoveryScreen(),
                      const LocalEatsScreen(),
                      const NeighbourhoodExplorerScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ExploreAllScreen extends StatefulWidget {
  const _ExploreAllScreen({required this.onSelectTab});

  final ValueChanged<int> onSelectTab;

  @override
  State<_ExploreAllScreen> createState() => _ExploreAllScreenState();
}

class _ExploreAllScreenState extends State<_ExploreAllScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: context.read<PlaceDiscoveryController>().query,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final places = context.read<PlaceDiscoveryController>();
    await Future.wait([
      if (places.query.trim().length >= 2)
        places.isNearby ? places.nearby() : places.search(),
      context.read<SpotController>().loadSpots(),
      context.read<LocalEatsController>().loadData(),
      context.read<GuideController>().loadGuides(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final places = context.watch<PlaceDiscoveryController>();
    final spots =
        context.watch<SpotController>().approvedSpots.take(3).toList();
    final eats = context
        .watch<LocalEatsController>()
        .filteredRestaurants
        .take(3)
        .toList();
    final guides =
        context.watch<GuideController>().approvedGuides.take(3).toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        key: const Key('explore_all_tab'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x2,
          AppSpacing.x2,
          AppSpacing.x2,
          112,
        ),
        children: [
          Text(
            'Explore all of Malaysia',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            'Discover real places, community favourites, local food and ready-made guides in one place.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.x2),
          SearchBar(
            key: const Key('explore_all_search'),
            controller: _search,
            hintText: context.tr('e.g. cafe in Penang'),
            leading: const Icon(Icons.search),
            trailing: [
              if (_search.text.isNotEmpty)
                IconButton(
                  tooltip: context.tr('Clear search'),
                  onPressed: () {
                    _search.clear();
                    places.updateQuery('');
                    setState(() {});
                  },
                  icon: const Icon(Icons.close),
                ),
            ],
            onChanged: (value) {
              places.updateQuery(value);
              setState(() {});
            },
            onSubmitted: places.search,
          ),
          const SizedBox(height: AppSpacing.x1),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              key: const Key('explore_all_near_me'),
              onPressed: places.isLoading ? null : places.nearby,
              icon: const Icon(Icons.near_me_outlined),
              label: const Text('Near me'),
            ),
          ),
          if (places.isLoading) ...[
            const SizedBox(height: AppSpacing.x2),
            const LinearProgressIndicator(),
          ],
          if (places.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.x2),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off_outlined),
                title: const Text('Real places could not be loaded'),
                subtitle: Text(places.errorMessage!),
                trailing: TextButton(
                  onPressed: places.isNearby ? places.nearby : places.search,
                  child: const Text('Retry'),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.x3),
          _DiscoverySection(
            icon: Icons.travel_explore_outlined,
            title:
                places.isNearby ? 'Real places near you' : 'Explore Malaysia',
            subtitle:
                'Broad real-world discovery for food, attractions and everyday places.',
            onSeeAll: () => widget.onSelectTab(1),
            emptyMessage: places.query.trim().length < 2
                ? 'Search above or use Near me to discover thousands of real places.'
                : 'No matching real places yet. Try a broader search.',
            children: places.places
                .take(4)
                .map((place) => ExternalPlaceCard(place: place))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.x3),
          _DiscoverySection(
            icon: Icons.place_outlined,
            title: 'Community Spots',
            subtitle:
                'Things to do and places recommended by the LiveLocal community.',
            onSeeAll: () => widget.onSelectTab(2),
            emptyMessage: 'Community Spots are being prepared.',
            children: spots.map(_spotPreview).toList(),
          ),
          const SizedBox(height: AppSpacing.x3),
          _DiscoverySection(
            icon: Icons.restaurant_outlined,
            title: 'Local Eats',
            subtitle:
                'Approved restaurant recommendations with richer Creator insight.',
            onSeeAll: () => widget.onSelectTab(3),
            emptyMessage:
                'Local restaurant recommendations are being prepared.',
            children: eats.map(_restaurantPreview).toList(),
          ),
          const SizedBox(height: AppSpacing.x3),
          _DiscoverySection(
            icon: Icons.route_outlined,
            title: 'Guides',
            subtitle: 'Community routes and recommendations ready to follow.',
            onSeeAll: () => widget.onSelectTab(4),
            emptyMessage: 'Travel guides are being prepared.',
            children: guides.map(_guidePreview).toList(),
          ),
        ],
      ),
    );
  }

  Widget _spotPreview(SpotModel spot) => _DiscoveryPreviewTile(
        title: spot.name,
        subtitle: '${spot.category} · ${spot.city}',
        imageUrl: spot.imageUrl,
        fallbackIcon: Icons.place_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => SpotDetailScreen(spot: spot),
          ),
        ),
      );

  Widget _restaurantPreview(RestaurantModel restaurant) =>
      _DiscoveryPreviewTile(
        title: restaurant.name,
        subtitle: '${restaurant.cuisineType} · ${restaurant.city}',
        imageUrl: restaurant.coverPhotoUrl,
        fallbackIcon: Icons.restaurant_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
          ),
        ),
      );

  Widget _guidePreview(GuideModel guide) => _DiscoveryPreviewTile(
        title: guide.title,
        subtitle: '${guide.locationName} · ${guide.estimatedDuration}',
        fallbackIcon: Icons.route_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => GuideDetailScreen(guide: guide),
          ),
        ),
      );
}

class _DiscoverySection extends StatelessWidget {
  const _DiscoverySection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onSeeAll,
    required this.emptyMessage,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onSeeAll;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                child: const Text('See all'),
              ),
            ],
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.x1),
          if (children.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.x2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(emptyMessage),
            )
          else
            ...children.expand(
              (child) => [
                child,
                const SizedBox(height: AppSpacing.x1),
              ],
            ),
        ],
      );
}

class _DiscoveryPreviewTile extends StatelessWidget {
  const _DiscoveryPreviewTile({
    required this.title,
    required this.subtitle,
    required this.fallbackIcon,
    required this.onTap,
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final validImage = imageUrl?.trim().isNotEmpty == true;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: SizedBox.square(
          dimension: 52,
          child: validImage
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _fallback(context),
                  placeholder: (_, __) => _fallback(context),
                )
              : _fallback(context),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _fallback(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          fallbackIcon,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
}
