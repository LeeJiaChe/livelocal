import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';
import '../controllers/itinerary_controller.dart';
import '../controllers/localeats_controller.dart';
import '../core/routing/protected_navigation.dart';
import '../features/influencer_applications/presentation/influencer_application_controller.dart';
import '../models/restaurant_model.dart';
import '../shared/presentation/app_state_view.dart';
import '../shared/presentation/contributions/contribution_status_chip.dart';
import '../shared/presentation/save_to_collection_sheet.dart';
import 'add_restaurant_screen.dart';
import 'manage_discount_screen.dart';
import 'restaurant_detail_screen.dart';

class LocalEatsScreen extends StatefulWidget {
  const LocalEatsScreen({super.key});

  @override
  State<LocalEatsScreen> createState() => _LocalEatsScreenState();
}

class _LocalEatsScreenState extends State<LocalEatsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showStateSelector(
      BuildContext context, LocalEatsController controller) {
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
                  children: controller.availableStates.map((state) {
                    final isSelected = controller.selectedState == state;
                    final displayName = state == 'Pulau Pinang'
                        ? 'Penang'
                        : (state == 'All' ? 'All Malaysia' : state);
                    return ListTile(
                      title: Text(
                        displayName,
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
                        controller.setFilter(state: state);
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
    final controller = context.watch<LocalEatsController>();
    final isInfluencer =
        context.watch<AuthController>().currentUser?.role == 'influencer';
    final restaurants = controller.filteredRestaurants;
    final hasActiveFilters = controller.hasActiveFilters;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.loadData,
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
                      'Local eats recommended by creators',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Authentic dining, street food, and kopitiams recommended by verified food lovers.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    SearchBar(
                      controller: _search,
                      hintText: 'Search restaurants, cuisines, or dishes',
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (_search.text.isNotEmpty)
                          IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _search.clear();
                              controller.setSearchQuery('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                      ],
                      onChanged: (value) {
                        controller.setSearchQuery(value);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    // Filter bar: State + Cuisines + Budget chips
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
                          ...controller.availableCuisines.map((cuisine) {
                            final isSelected =
                                controller.selectedCuisine == cuisine;
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.x1),
                              child: FilterChip(
                                label: Text(cuisine),
                                selected: isSelected,
                                onSelected: (_) => controller.setFilter(
                                  cuisine: isSelected ? 'All' : cuisine,
                                ),
                              ),
                            );
                          }),
                          ...controller.availablePriceRanges
                              .where((p) => p != 'All')
                              .map((price) {
                            final isSelected =
                                controller.selectedBudget == price;
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.x1),
                              child: FilterChip(
                                label: Text(price),
                                selected: isSelected,
                                onSelected: (_) => controller.setFilter(
                                  budget: isSelected ? 'All' : price,
                                ),
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
                          '${restaurants.length} ${restaurants.length == 1 ? 'place' : 'places'} found',
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
                              _search.clear();
                              controller.resetFilters();
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (controller.isLoading && controller.restaurants.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.all(AppSpacing.x2),
                sliver: _RestaurantLoadingSliver(),
              )
            else if (controller.errorMessage != null &&
                controller.restaurants.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppStateView(
                  icon: Icons.wifi_off_outlined,
                  title: 'Restaurants could not be loaded',
                  message: controller.errorMessage!,
                  actionLabel: 'Try again',
                  onAction: controller.loadData,
                ),
              )
            else if (restaurants.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppStateView(
                  icon: Icons.search_off_outlined,
                  title: 'No restaurants found',
                  message: 'Try a broader search or reset the filters.',
                  actionLabel: 'Reset filters',
                  onAction: () {
                    _search.clear();
                    controller.resetFilters();
                    setState(() {});
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x2,
                  0,
                  AppSpacing.x2,
                  112,
                ),
                sliver: SliverList.separated(
                  itemCount: restaurants.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.x2),
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    final hasDiscount = controller
                        .getActiveDiscountsForRestaurant(restaurant.id)
                        .isNotEmpty;
                    return _RestaurantCard(
                      restaurant: restaurant,
                      hasDiscount: hasDiscount,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => RestaurantDetailScreen(
                            restaurant: restaurant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'localeats_fab',
        onPressed: () => _handleRecommendRestaurant(context, isInfluencer),
        icon: const Icon(Icons.restaurant_outlined),
        label: const Text('Recommend a restaurant'),
      ),
    );
  }

  void _handleRecommendRestaurant(BuildContext context, bool isInfluencer) {
    final auth = context.read<AuthController>();
    if (!auth.canWrite) {
      context.read<ProtectedNavigation>().open(
            context,
            '/recommend-restaurant',
          );
      return;
    }

    if (isInfluencer) {
      _showCreatorActions();
    } else {
      _showCreatorEligibilitySheet();
    }
  }

  Future<void> _showCreatorEligibilitySheet() async {
    final influencerCtrl = context.read<InfluencerApplicationController>();
    await influencerCtrl.loadMine();
    if (!mounted) return;
    final application = influencerCtrl.mine;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'LiveLocal Creator Program',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Restaurant recommendations are submitted by approved LiveLocal Creators.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Apply to become a Creator. Once your application is approved by our team, Creator tools and restaurant recommendations will be unlocked.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 20),
              if (application != null &&
                  ['submitted', 'under_review', 'approved']
                      .contains(application.status)) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Application status:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      ContributionStatusChip(
                        status: application.status,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      Navigator.pushNamed(context, '/creator-application');
                    },
                    child: const Text('View application status'),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      Navigator.pushNamed(context, '/creator-application');
                    },
                    child: const Text('Apply to become a Creator'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: const Text('Maybe later'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreatorActions() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Creator tools',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListTile(
                minTileHeight: 56,
                leading: const Icon(Icons.add_business_outlined),
                title: const Text('Submit a restaurant'),
                subtitle:
                    const Text('Create a listing for community moderation.'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AddRestaurantScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                minTileHeight: 56,
                leading: const Icon(Icons.local_offer_outlined),
                title: const Text('Create a discount'),
                subtitle: const Text('Share deals for your listings.'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ManageDiscountScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.restaurant,
    required this.hasDiscount,
    required this.onTap,
  });

  final RestaurantModel restaurant;
  final bool hasDiscount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itineraryCtrl = context.watch<ItineraryController>();
    final isSaved = itineraryCtrl.isSaved(restaurantId: restaurant.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: restaurant.coverPhotoUrl,
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
                        child: Icon(Icons.restaurant_outlined, size: 48),
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
                      tooltip: isSaved
                          ? 'Saved to collections'
                          : 'Save to collection',
                      onPressed: () => SaveToCollectionSheet.show(
                        context,
                        targetType: 'restaurant',
                        targetId: restaurant.id,
                        placeName: restaurant.name,
                        restaurant: restaurant,
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
                      restaurant.cuisineType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_offer,
                              color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'PROMO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                          restaurant.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      Text(
                        restaurant.priceRange,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${restaurant.city}, ${restaurant.state}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (restaurant.reviewedDishes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Must try: ${restaurant.reviewedDishes}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestaurantLoadingSliver extends StatelessWidget {
  const _RestaurantLoadingSliver();

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
