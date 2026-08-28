import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../../../screens/localeats_screen.dart';
import '../../../screens/neighbourhood_explorer_screen.dart';
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
        length: 4,
        child: Scaffold(
          body: Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: const TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.travel_explore_outlined),
                      child: Text('Places'),
                    ),
                    Tab(
                      icon: Icon(Icons.place_outlined),
                      child: Text('Spots'),
                    ),
                    Tab(
                      icon: Icon(Icons.restaurant_outlined),
                      child: Text('Eats'),
                    ),
                    Tab(
                      icon: Icon(Icons.route_outlined),
                      child: Text('Guides'),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    ExternalPlacesScreen(),
                    SpotsDiscoveryScreen(),
                    LocalEatsScreen(),
                    NeighbourhoodExplorerScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
