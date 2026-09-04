import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../screens/localeats_screen.dart';
import '../../../screens/neighbourhood_explorer_screen.dart';
import '../../../screens/spots_discovery_screen.dart';
import '../../places/domain/place_provider.dart';
import '../../places/data/supabase_google_places_provider.dart';
import '../../places/presentation/external_places_screen.dart';
import '../../places/presentation/place_discovery_controller.dart';

class ExploreHubScreen extends StatelessWidget {
  const ExploreHubScreen({
    super.key,
    this.selectedTabNotifier,
    this.initialIndex,
  });

  final ValueNotifier<int>? selectedTabNotifier;
  final int? initialIndex;

  @override
  Widget build(BuildContext context) {
    final existingController =
        Provider.of<PlaceDiscoveryController?>(context, listen: false);
    if (existingController != null) {
      return _ExploreTabs(
        selectedTabNotifier: selectedTabNotifier,
        initialIndex: initialIndex,
      );
    }

    final existingProvider =
        Provider.of<PlaceProvider?>(context, listen: false);
    final provider = existingProvider ?? const UnavailablePlaceProvider();
    return MultiProvider(
      providers: [
        if (existingProvider == null)
          Provider<PlaceProvider>.value(value: provider),
        ChangeNotifierProvider(
          create: (_) => PlaceDiscoveryController(provider: provider),
        ),
      ],
      child: _ExploreTabs(
        selectedTabNotifier: selectedTabNotifier,
        initialIndex: initialIndex,
      ),
    );
  }
}

class _ExploreTabs extends StatefulWidget {
  const _ExploreTabs({this.selectedTabNotifier, this.initialIndex});

  final ValueNotifier<int>? selectedTabNotifier;
  final int? initialIndex;

  @override
  State<_ExploreTabs> createState() => _ExploreTabsState();
}

class _ExploreTabsState extends State<_ExploreTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initial =
        widget.initialIndex ?? widget.selectedTabNotifier?.value ?? 0;
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: initial.clamp(0, 3),
    );
    widget.selectedTabNotifier?.addListener(_handleNotifierChange);
  }

  void _handleNotifierChange() {
    final target = widget.selectedTabNotifier?.value;
    if (target != null &&
        target >= 0 &&
        target < 4 &&
        _tabController.index != target) {
      _tabController.animateTo(target);
    }
  }

  @override
  void didUpdateWidget(_ExploreTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTabNotifier != widget.selectedTabNotifier) {
      oldWidget.selectedTabNotifier?.removeListener(_handleNotifierChange);
      widget.selectedTabNotifier?.addListener(_handleNotifierChange);
    }
  }

  @override
  void dispose() {
    widget.selectedTabNotifier?.removeListener(_handleNotifierChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                key: const Key('explore_section_tabs'),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.symmetric(horizontal: 18),
                tabs: const [
                  Tab(child: Text('Discover', maxLines: 1)),
                  Tab(child: Text('Eat', maxLines: 1)),
                  Tab(child: Text('Things to Do', maxLines: 1)),
                  Tab(child: Text('Guides', maxLines: 1)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  ExternalPlacesScreen(),
                  LocalEatsScreen(),
                  SpotsDiscoveryScreen(),
                  NeighbourhoodExplorerScreen(),
                ],
              ),
            ),
          ],
        ),
      );
}
