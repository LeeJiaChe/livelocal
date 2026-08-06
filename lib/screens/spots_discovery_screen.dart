import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_spacing.dart';
import '../controllers/spot_controller.dart';
import '../core/routing/protected_navigation.dart';
import '../models/spot_model.dart';
import '../shared/presentation/app_state_view.dart';
import 'spot_detail_screen.dart';

class SpotsDiscoveryScreen extends StatefulWidget {
  const SpotsDiscoveryScreen({super.key});

  @override
  State<SpotsDiscoveryScreen> createState() => _SpotsDiscoveryScreenState();
}

class _SpotsDiscoveryScreenState extends State<SpotsDiscoveryScreen> {
  static const _states = [
    'All',
    'Johor',
    'Kuala Lumpur',
    'Melaka',
    'Penang',
    'Perak',
    'Sabah',
    'Sarawak',
    'Selangor',
  ];
  static const _categories = [
    'All',
    'Kopitiam',
    'Pasar Malam',
    'Indie Cafe',
    'Park / Walkway',
    'Hawker Food',
    'Heritage Spot',
  ];

<<<<<<< HEAD
  final List<String> _states = ['All', 'Penang', 'Kuala Lumpur', 'Perak', 'Johor', 'Selangor', 'Melaka', 'Sabah', 'Sarawak'];
  final List<String> _categories = ['All', 'Heritage Site', 'Nature & Parks', 'Museum & Gallery', 'Street Art', 'Viewpoint', 'Cultural Landmark'];

  late AnimationController _heroTextController;
  late Animation<double> _heroTextOpacity;
  late Animation<Offset> _heroTextSlide;

  @override
  void initState() {
    super.initState();
    _heroTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heroTextOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroTextController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );
    _heroTextSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _heroTextController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );
    _heroTextController.forward();
  }
=======
  final _search = TextEditingController();
>>>>>>> origin/master

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SpotController>();
    final spots = controller.approvedSpots;
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
<<<<<<< HEAD
                    SlideTransition(
                      position: _heroTextSlide,
                      child: FadeTransition(
                        opacity: _heroTextOpacity,
                        child: const Text(
                          'Discover Local Spots',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(Icons.search, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (val) => spotCtrl.filter(query: val),
                              onEditingComplete: () => FocusScope.of(context).unfocus(),
                              decoration: InputDecoration(
                                hintText: 'Search temples, parks, museums...',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                              onPressed: () {
                                setState(() => _searchCtrl.clear());
                                spotCtrl.filter(query: '');
                                FocusScope.of(context).unfocus();
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Column(
                  children: [
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSelected = spotCtrl.selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () => spotCtrl.filter(category: cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                                    ),
                                    boxShadow: isSelected
                                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
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
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
=======
>>>>>>> origin/master
                    Text(
                      'Discover places locals value',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Browse approved public spots without sharing your location.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    SearchBar(
                      controller: _search,
                      hintText: 'Search places, food, or neighbourhoods',
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (_search.text.isNotEmpty)
                          IconButton(
                            tooltip: 'Clear search',
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
                    DropdownButtonFormField<String>(
                      initialValue: controller.selectedState,
                      decoration: const InputDecoration(
                        labelText: 'State or territory',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: _states
                          .map(
                            (state) => DropdownMenuItem(
                              value: state,
                              child: Text(state),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) controller.filter(state: value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Semantics(
                      label: 'Filter spots by category',
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories
                              .map(
                                (category) => Padding(
                                  padding: const EdgeInsets.only(
                                      right: AppSpacing.x1),
                                  child: FilterChip(
                                    label: Text(category),
                                    selected:
                                        controller.selectedCategory == category,
                                    onSelected: (_) =>
                                        controller.filter(category: category),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      '${spots.length} ${spots.length == 1 ? 'place' : 'places'}',
                      style: Theme.of(context).textTheme.titleMedium,
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
                  actionLabel: 'Try again',
                  onAction: controller.loadSpots,
                ),
              )
            else if (spots.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppStateView(
                  icon: Icons.travel_explore_outlined,
                  title: 'No matching places',
                  message: 'Try another search, category, or state.',
                  actionLabel: 'Clear filters',
                  onAction: () {
                    _search.clear();
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
        onPressed: () =>
            context.read<ProtectedNavigation>().open(context, '/submit-spot'),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Submit a place'),
      ),
    );
  }
}

class _SpotCard extends StatelessWidget {
  const _SpotCard({required this.spot});

  final SpotModel spot;

  @override
  Widget build(BuildContext context) {
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
            AspectRatio(
              aspectRatio: 16 / 7,
              child: CachedNetworkImage(
                imageUrl: spot.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined, size: 48),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.x1,
                    runSpacing: AppSpacing.x1,
                    children: [
                      Chip(label: Text(spot.category)),
                      if (spot.reviewCount > 0)
                        Chip(
                          avatar: const Icon(Icons.star, size: 18),
                          label: Text(
                            '${spot.rating.toStringAsFixed(1)} · ${spot.reviewCount}',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    spot.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  Text('${spot.city}, ${spot.state} · ${spot.priceRange}'),
                  const SizedBox(height: AppSpacing.x1),
                  Text(
                    spot.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
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
        height: 260,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
