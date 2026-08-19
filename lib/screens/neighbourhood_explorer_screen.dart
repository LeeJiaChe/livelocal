import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/guide_controller.dart';
import '../models/guide_model.dart';
import 'guide_detail_screen.dart';
import '../shared/presentation/app_state_view.dart';
import '../features/guides/presentation/submit_guide_screen.dart';

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
    'Kuala Lumpur',
    'Melaka',
    'Penang',
    'Perak',
    'Sabah',
    'Sarawak',
    'Selangor',
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
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F0),
        title: const Text('Neighbourhood guides'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadGuides,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Curated routes for exploring locally',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Every published guide is curated and versioned by the LiveLocal team.',
                    ),
                    const SizedBox(height: 16),
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
                              setState(() {
                                _searchCtrl.clear();
                              });
                              controller.setSearchQuery('');
                            },
                          ),
                      ],
                      onChanged: (val) {
                        setState(() {});
                        controller.setSearchQuery(val);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey('state_${controller.selectedState}'),
                      initialValue: controller.selectedState,
                      decoration: const InputDecoration(
                        labelText: 'State or territory',
                        border: OutlineInputBorder(),
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
                        if (value != null) controller.setStateFilter(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'nh_${controller.selectedState}_${controller.selectedNeighbourhood}',
                      ),
                      initialValue: controller.selectedNeighbourhood,
                      decoration: const InputDecoration(
                        labelText: 'Neighbourhood / area',
                        border: OutlineInputBorder(),
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${guides.length} ${guides.length == 1 ? 'guide' : 'guides'} found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (hasActiveFilters)
                          TextButton.icon(
                            icon: const Icon(Icons.filter_alt_off_outlined,
                                size: 18),
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
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.errorMessage != null &&
                controller.guides.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: SingleChildScrollView(
                  child: AppStateView(
                    icon: Icons.wifi_off_outlined,
                    title: 'Guides could not be loaded',
                    message: controller.errorMessage!,
                    actionLabel: 'Try again',
                    onAction: controller.loadGuides,
                  ),
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
                        'Check back later for curated neighbourhood routes.',
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
                    actionIcon: Icons.filter_alt_off_outlined,
                    onAction: () => _clearFilters(controller),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 112),
                sliver: SliverList.separated(
                  itemCount: guides.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
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
      margin: EdgeInsets.zero,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.route_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      guide.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Text('${guide.locationName}, ${guide.state}'),
              const SizedBox(height: 8),
              Text(
                guide.routeOverview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _Meta(
                      icon: Icons.schedule_outlined,
                      text: guide.estimatedDuration),
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
        Icon(icon, size: 18),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}
