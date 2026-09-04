import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../../../../controllers/localeats_controller.dart';
import '../../../../controllers/spot_controller.dart';
import '../../../../models/restaurant_model.dart';
import '../../../../models/spot_model.dart';
import '../../../../screens/restaurant_detail_screen.dart';
import '../../../../screens/spot_detail_screen.dart';
import '../widgets/admin_section_header.dart';
import 'admin_guides_page.dart';

/// Coherent Admin Content workspace for managing published Spots, Restaurants,
/// and Guides across LiveLocal.
class AdminContentPage extends StatefulWidget {
  const AdminContentPage({super.key});

  @override
  State<AdminContentPage> createState() => _AdminContentPageState();
}

class _AdminContentPageState extends State<AdminContentPage> {
  int _selectedSection = 0; // 0: Spots, 1: Restaurants, 2: Guides

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AdminSectionHeader(
            title: context.tr('Content'),
            subtitle: context.tr(
              'Manage published spots, restaurants, and guides across Malaysia',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment<int>(
                value: 0,
                icon: const Icon(Icons.park_outlined),
                label: Text(context.tr('Spots')),
              ),
              ButtonSegment<int>(
                value: 1,
                icon: const Icon(Icons.restaurant_outlined),
                label: Text(context.tr('Restaurants')),
              ),
              ButtonSegment<int>(
                value: 2,
                icon: const Icon(Icons.route_outlined),
                label: Text(context.tr('Guides')),
              ),
            ],
            selected: {_selectedSection},
            onSelectionChanged: (set) {
              if (set.isNotEmpty) {
                setState(() => _selectedSection = set.first);
              }
            },
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedSection,
            children: const [
              _AdminSpotsContent(),
              _AdminRestaurantsContent(),
              AdminGuidesPage(),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminSpotsContent extends StatefulWidget {
  const _AdminSpotsContent();

  @override
  State<_AdminSpotsContent> createState() => _AdminSpotsContentState();
}

class _AdminSpotsContentState extends State<_AdminSpotsContent> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spotsController = context.watch<SpotController>();
    final spots = spotsController.spots;
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = spots.where((s) {
      if (query.isEmpty) return true;
      return s.name.toLowerCase().contains(query) ||
          s.state.toLowerCase().contains(query) ||
          s.city.toLowerCase().contains(query) ||
          s.category.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SearchBar(
            controller: _searchCtrl,
            hintText: context.tr('Search published spots...'),
            leading: const Icon(Icons.search),
            trailing: [
              if (_searchCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(_searchCtrl.clear),
                ),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${filtered.length} ${context.tr('published spots')}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      spotsController.isLoading
                          ? context.tr('Loading spots...')
                          : context.tr('No published spots found.'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final spot = filtered[index];
                    return _AdminSpotCard(spot: spot);
                  },
                ),
        ),
      ],
    );
  }
}

class _AdminSpotCard extends StatelessWidget {
  const _AdminSpotCard({required this.spot});

  final SpotModel spot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: spot.imageUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              width: 56,
              height: 56,
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.place_outlined),
            ),
          ),
        ),
        title: Text(
          spot.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${spot.category} · ${spot.city}, ${spot.state}',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.thumb_up_outlined,
                    size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text('${spot.upvoteCount}', style: theme.textTheme.labelSmall),
                const SizedBox(width: 12),
                Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text(
                  spot.reviewCount > 0
                      ? '${spot.rating.toStringAsFixed(1)} (${spot.reviewCount})'
                      : context.tr('No reviews'),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => SpotDetailScreen(spot: spot)),
        ),
      ),
    );
  }
}

class _AdminRestaurantsContent extends StatefulWidget {
  const _AdminRestaurantsContent();

  @override
  State<_AdminRestaurantsContent> createState() =>
      _AdminRestaurantsContentState();
}

class _AdminRestaurantsContentState extends State<_AdminRestaurantsContent> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localEats = context.watch<LocalEatsController>();
    final restaurants = localEats.restaurants;
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = restaurants.where((r) {
      if (query.isEmpty) return true;
      return r.name.toLowerCase().contains(query) ||
          r.state.toLowerCase().contains(query) ||
          r.cuisineType.toLowerCase().contains(query) ||
          r.influencerName.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SearchBar(
            controller: _searchCtrl,
            hintText: context.tr('Search published restaurants...'),
            leading: const Icon(Icons.search),
            trailing: [
              if (_searchCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(_searchCtrl.clear),
                ),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${filtered.length} ${context.tr('published restaurants')}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      localEats.isLoading
                          ? context.tr('Loading restaurants...')
                          : context.tr('No published restaurants found.'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final restaurant = filtered[index];
                    return _AdminRestaurantCard(restaurant: restaurant);
                  },
                ),
        ),
      ],
    );
  }
}

class _AdminRestaurantCard extends StatelessWidget {
  const _AdminRestaurantCard({required this.restaurant});

  final RestaurantModel restaurant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: restaurant.coverPhotoUrl,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(
              width: 56,
              height: 56,
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.restaurant_outlined),
            ),
          ),
        ),
        title: Text(
          restaurant.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${restaurant.cuisineType} · ${restaurant.state}',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                if (restaurant.influencerName.isNotEmpty) ...[
                  Icon(Icons.person_pin_circle_outlined,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      restaurant.influencerName,
                      style: theme.textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                Text(restaurant.priceRange, style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
          ),
        ),
      ),
    );
  }
}
