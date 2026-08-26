import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_spacing.dart';
import '../controllers/guide_controller.dart';
import '../core/routing/protected_navigation.dart';
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
    final availableStates = controller.availableStates;
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
                      'Explore travel guides',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Community routes and itineraries shared by travellers and LiveLocal Creators.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    SearchBar(
                      controller: _searchCtrl,
                      hintText: context.tr('Search guides or neighbourhoods'),
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            tooltip: context.tr('Clear search'),
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
                      initialValue: availableStates.any(
                              (s) => s.rawValue == controller.selectedState)
                          ? controller.selectedState
                          : 'All',
                      decoration: InputDecoration(
                        labelText: context.tr('State or territory'),
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                      items: availableStates
                          .map(
                            (stateOption) => DropdownMenuItem(
                              value: stateOption.rawValue,
                              child: Text(stateOption.displayName),
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
                      initialValue: neighbourhoods
                              .contains(controller.selectedNeighbourhood)
                          ? controller.selectedNeighbourhood
                          : 'All',
                      decoration: InputDecoration(
                        labelText: context.tr('Neighbourhood / area'),
                        prefixIcon: const Icon(Icons.holiday_village_outlined),
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
                  actionLabel: context.tr('Try again'),
                  onAction: controller.loadGuides,
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
                    actionLabel: context.tr(
                      hasActiveFilters ? 'Clear filters' : 'Submit guide',
                    ),
                    onAction: hasActiveFilters
                        ? () => _clearFilters(controller)
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const SubmitGuideScreen(),
                              ),
                            ),
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
                  itemBuilder: (context, index) {
                    final guide = guides[index];
                    return _GuideCard(guide: guide);
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'submit_guide_fab',
        onPressed: () =>
            context.read<ProtectedNavigation>().open(context, '/submit-guide'),
        icon: const Icon(Icons.add_road_outlined),
        label: const Text('Create a guide'),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide});

  final GuideModel guide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stateDisplay = guide.state == 'Pulau Pinang' ? 'Penang' : guide.state;

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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/guide-detail'),
            builder: (_) => GuideDetailScreen(guide: guide),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      guide.locationName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  Text(
                    stateDisplay,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                guide.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                guide.routeOverview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.x2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pin_drop_outlined,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${guide.stops.length} stops',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    guide.estimatedDuration,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
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

class _GuideLoadingSliver extends StatelessWidget {
  const _GuideLoadingSliver();

  @override
  Widget build(BuildContext context) {
    return SliverList.separated(
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x2),
      itemBuilder: (context, _) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: AppSpacing.x1),
              Container(
                width: double.infinity,
                height: 18,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: AppSpacing.x1),
              Container(
                width: 200,
                height: 14,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
