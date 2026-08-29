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
  const ExploreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final existingController =
        Provider.of<PlaceDiscoveryController?>(context, listen: false);
    if (existingController != null) return const _ExploreTabs();

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
      child: const _ExploreTabs(),
    );
  }
}

class _ExploreTabs extends StatelessWidget {
  const _ExploreTabs();

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 4,
        child: Scaffold(
          body: Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: const TabBar(
                  key: Key('explore_section_tabs'),
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelPadding: EdgeInsets.symmetric(horizontal: 18),
                  tabs: [
                    Tab(child: Text('Discover', maxLines: 1)),
                    Tab(child: Text('Eat', maxLines: 1)),
                    Tab(child: Text('Things to Do', maxLines: 1)),
                    Tab(child: Text('Guides', maxLines: 1)),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    ExternalPlacesScreen(),
                    LocalEatsScreen(),
                    SpotsDiscoveryScreen(),
                    NeighbourhoodExplorerScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
