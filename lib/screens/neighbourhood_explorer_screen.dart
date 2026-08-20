import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_spacing.dart';
import '../controllers/guide_controller.dart';
import '../features/guides/presentation/submit_guide_screen.dart';
import '../models/guide_model.dart';
import '../shared/presentation/app_state_view.dart';
import 'guide_detail_screen.dart';

class NeighbourhoodExplorerScreen extends StatefulWidget {
  const NeighbourhoodExplorerScreen({super.key});

  @override
  State<NeighbourhoodExplorerScreen> createState() =>
      _NeighbourhoodExplorerScreenState();
}

class _NeighbourhoodExplorerScreenState
    extends State<NeighbourhoodExplorerScreen> {
  static const _states = [
    'All',
    'Johor',
    'Kedah',
    'Kuala Lumpur',
    'Melaka',
    'Pahang',
    'Penang',
    'Perak',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
  ];

  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearFilters(GuideController controller) {
    setState(() {
      _searchCtrl.clear();
    });
    controller.resetFilters();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GuideController>();
    final guides = controller.approvedGuides;
    final neighbourhoods = controller.availableNeighbourhoods;
    final hasActiveFilters = controller.hasActiveFilters;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.loadGuides,
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
                      'Neighbourhood guides',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Curated walking routes and district explorations curated by the community.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    SearchBar(
                      controller: _searchCtrl,
                      hintText: 'Search guides or neighbourhoods',
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(_searchCtrl.clear);
                              controller.setSearchQuery('');
                            },
                          ),
                      ],
                      onChanged: (val) {
                        setState(() {});
                        controller.setSearchQuery(val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    DropdownButtonFormField<String>(
                      key: ValueKey('state_${controller.selectedState}'),
                      initialValue: controller.selectedState,
                      decoration: const InputDecoration(
                        labelText: 'State or territory',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: _states
                          .map(
                            (state) => DropdownMenuItem(
                              value: state,
                              child:
                                  Text(state == 'All' ? 'All Malaysia' : state),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) controller.setStateFilter(value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'nh_${controller.selectedState}_${controller.selectedNeighbourhood}',
                      ),
                      initialValue: controller.selectedNeighbourhood,
                      decoration: const InputDecoration(
                        labelText: 'Neighbourhood / area',
                        prefixIcon: Icon(Icons.holiday_village_outlined),
                      ),
                      items: neighbourhoods
                          .map(
                            (nh) => DropdownMenuItem(
                              value: nh,
                              child: Text(nh),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.setNeighbourhoodFilter(value);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${guides.length} ${guides.length == 1 ? 'guide' : 'guides'} found',
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
                            onPressed: () => _clearFilters(controller),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (controller.isLoading && controller.guides.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.all(AppSpacing.x2),
                sliver: _GuideLoadingSliver(),
              )
            else if (controller.errorMessage != null &&
                controller.guides.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppStateView(
                  icon: Icons.wifi_off_outlined,
                  title: 'Guides could not be loaded',
                  message: controller.errorMessage!,
                  actionLabel: 'Try again',
                  onAction: controller.loadGuides,
                ),
              )
            else if (controller.guides.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: SingleChildScrollView(
                  child: AppStateView(
                    icon: Icons.explore_off_outlined,
                    title: 'No guides available',
                    message:
                        'Check back soon for curated neighbourhood routes.',
                  ),
                ),
              )
            else if (guides.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: SingleChildScrollView(
                  child: AppStateView(
                    icon: Icons.explore_off_outlined,
                    title: 'No matching guides',
                    message: 'Try another search, state, or neighbourhood.',
                    actionLabel: 'Clear filters',
                    onAction: () => _clearFilters(controller),
                  ),
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
                  itemCount: guides.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.x2),
                  itemBuilder: (context, index) => _GuideCard(
                    guide: guides[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => GuideDetailScreen(guide: guides[index]),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'neighbourhood_explorer_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const SubmitGuideScreen()),
        ),
        icon: const Icon(Icons.add_road_outlined),
        label: const Text('Submit guide'),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide, required this.onTap});

  final GuideModel guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.route_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          guide.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${guide.locationName}, ${guide.state}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                guide.routeOverview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.x2),
              Wrap(
                spacing: AppSpacing.x2,
                runSpacing: AppSpacing.x1,
                children: [
                  _Meta(
                    icon: Icons.schedule_outlined,
                    text: guide.estimatedDuration,
                  ),
                  _Meta(
                    icon: Icons.pin_drop_outlined,
                    text: '${guide.stops.length} stops',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _GuideLoadingSliver extends StatelessWidget {
  const _GuideLoadingSliver();

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x2),
      itemBuilder: (_, __) => Container(
        height: 140,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
