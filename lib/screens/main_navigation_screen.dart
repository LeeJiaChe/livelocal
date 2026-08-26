import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/itinerary_controller.dart';
import '../features/navigation/presentation/creator_studio_screen.dart';
import '../features/navigation/presentation/explore_hub_screen.dart';
import '../features/navigation/presentation/role_home_screen.dart';
import '../features/notifications/presentation/notification_controller.dart';
import 'neighbourhood_explorer_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'saved_places_screen.dart';
import 'itinerary_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<AuthController>().canWrite) return;
      context.read<ItineraryController>().loadSavedPlaces();
      context.read<ItineraryController>().loadItineraries();
      context.read<NotificationController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final role = auth.currentUser?.role;
    final isGuest = auth.currentUser == null;
    final isCreator = role == 'influencer';

    late final List<_RoleDestination> destinations;
    if (isGuest) {
      destinations = const [
        _RoleDestination('Home', Icons.home_outlined, Icons.home),
        _RoleDestination('Explore', Icons.explore_outlined, Icons.explore),
        _RoleDestination('Guides', Icons.route_outlined, Icons.route),
        _RoleDestination('Profile', Icons.person_outline, Icons.person),
      ];
    } else if (isCreator) {
      destinations = const [
        _RoleDestination('Home', Icons.home_outlined, Icons.home),
        _RoleDestination('Explore', Icons.explore_outlined, Icons.explore),
        _RoleDestination(
          'Studio',
          Icons.dashboard_customize_outlined,
          Icons.dashboard_customize,
        ),
        _RoleDestination('Saved', Icons.bookmark_outline, Icons.bookmark),
        _RoleDestination('Profile', Icons.person_outline, Icons.person),
      ];
    } else {
      destinations = const [
        _RoleDestination('Home', Icons.home_outlined, Icons.home),
        _RoleDestination('Explore', Icons.explore_outlined, Icons.explore),
        _RoleDestination('Saved', Icons.bookmark_outline, Icons.bookmark),
        _RoleDestination('Trips', Icons.luggage_outlined, Icons.luggage),
        _RoleDestination('Profile', Icons.person_outline, Icons.person),
      ];
    }

    if (_currentIndex >= destinations.length) _currentIndex = 0;

    void selectLabel(String label) {
      final index = destinations.indexWhere((item) => item.label == label);
      if (index >= 0) setState(() => _currentIndex = index);
    }

    final home = RoleHomeScreen(
      onOpenExplore: () => selectLabel('Explore'),
      onOpenPlanning: () {
        if (!isCreator) {
          selectLabel('Trips');
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const ItineraryScreen()),
        );
      },
      onOpenStudio: () => selectLabel('Studio'),
    );

    final pages = isGuest
        ? <Widget>[
            home,
            const ExploreHubScreen(),
            const NeighbourhoodExplorerScreen(),
            const ProfileScreen(),
          ]
        : isCreator
            ? <Widget>[
                home,
                const ExploreHubScreen(),
                const CreatorStudioScreen(),
                const SavedPlacesScreen(),
                const ProfileScreen(),
              ]
            : <Widget>[
                home,
                const ExploreHubScreen(),
                const SavedPlacesScreen(),
                const ItineraryScreen(),
                const ProfileScreen(),
              ];

    final currentLabel = destinations[_currentIndex].label;
    final ownsAppBar = currentLabel == 'Saved' ||
        currentLabel == 'Trips' ||
        currentLabel == 'Profile';
    return Scaffold(
      appBar: !ownsAppBar
          ? AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    currentLabel == 'Home'
                        ? 'LiveLocal'
                        : context.tr(currentLabel),
                  ),
                ],
              ),
              actions: [
                if (!isGuest)
                  _NotificationAction(
                    unreadCount:
                        context.watch<NotificationController>().unreadCount,
                  ),
                const _LanguageAction(),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: destinations
            .map(
              (destination) => NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: context.tr(destination.label),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _RoleDestination {
  const _RoleDestination(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _NotificationAction extends StatelessWidget {
  const _NotificationAction({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.tr('Notifications'),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      ),
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class _LanguageAction extends StatelessWidget {
  const _LanguageAction();

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<AppLocaleController>();
    return PopupMenuButton<String>(
      tooltip: context.tr('Language'),
      icon: const Icon(Icons.translate),
      onSelected: locale.setLanguage,
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: 'en',
          checked: !locale.isMalay,
          child: const Text('English'),
        ),
        CheckedPopupMenuItem(
          value: 'ms',
          checked: locale.isMalay,
          child: const Text('Bahasa Malaysia'),
        ),
      ],
    );
  }
}
