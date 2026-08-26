import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';

import '../../../screens/localeats_screen.dart';
import '../../../screens/neighbourhood_explorer_screen.dart';
import '../../../screens/spots_discovery_screen.dart';

class ExploreHubScreen extends StatelessWidget {
  const ExploreHubScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          body: Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.surface,
                child: const TabBar(
                  tabs: [
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
