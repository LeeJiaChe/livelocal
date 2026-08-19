import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../controllers/admin_controller.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/guide_controller.dart';
import '../../../../controllers/localeats_controller.dart';
import '../../../../controllers/spot_controller.dart';
import '../../../influencer_applications/presentation/influencer_application_controller.dart';
import 'admin_audit_page.dart';
import 'admin_guides_page.dart';
import 'admin_overview_page.dart';
import 'admin_review_queue_page.dart';
import 'admin_users_page.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  String _reviewSubFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAll());
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    final auth = context.read<AuthController>();
    if (auth.currentUser?.role != 'admin') return;

    await Future.wait([
      context.read<AdminController>().loadDashboard(),
      context.read<SpotController>().loadPendingSpots(),
      context.read<LocalEatsController>().loadPendingRestaurants(),
      context.read<GuideController>().loadAdminDrafts(),
      context.read<GuideController>().loadGuides(),
      context.read<InfluencerApplicationController>().loadPending(),
    ]);
  }

  void _navigateToTab(int index, {String? subFilter}) {
    setState(() {
      _selectedIndex = index;
      if (subFilter != null) {
        _reviewSubFilter = subFilter;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    if (auth.currentUser?.role != 'admin') {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F5F0),
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: const Color(0xFFF7F5F0),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gpp_bad_outlined,
                  size: 56,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Administrator permission is required.',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your account is not authorized to view the admin operations workspace.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: auth.logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final admin = context.watch<AdminController>();
    final spots = context.watch<SpotController>();
    final localEats = context.watch<LocalEatsController>();
    final guides = context.watch<GuideController>();
    final applications = context.watch<InfluencerApplicationController>();

    final errorMessage = admin.errorMessage ??
        spots.errorMessage ??
        localEats.errorMessage ??
        guides.errorMessage ??
        applications.errorMessage;

    final isAnyLoading = admin.isRefreshing ||
        spots.isLoading ||
        localEats.isLoading ||
        guides.isLoading ||
        applications.isLoading;

    final pages = [
      AdminOverviewPage(onNavigateToTab: _navigateToTab),
      AdminReviewQueuePage(
        key: ValueKey('review_$_reviewSubFilter'),
        initialFilter: _reviewSubFilter,
      ),
      const AdminGuidesPage(),
      const AdminUsersPage(),
      const AdminAuditPage(),
    ];

    const sectionTitles = [
      'Overview',
      'Review Queue',
      'Guide Management',
      'User Management',
      'Audit History',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        Widget content = Column(
          children: [
            if (errorMessage != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _refreshAll,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: pages,
              ),
            ),
          ],
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF7F5F0),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F5F0),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Admin Center',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        sectionTitles[_selectedIndex],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (isAnyLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh all',
                  onPressed: _refreshAll,
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle_outlined),
                tooltip: 'Admin account',
                onSelected: (value) {
                  if (value == 'logout') auth.logout();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      auth.currentUser?.fullName ?? 'Administrator',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      auth.currentUser?.email ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18),
                        SizedBox(width: 8),
                        Text('Sign out'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: isWide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) =>
                          setState(() => _selectedIndex = index),
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard),
                          label: Text('Overview'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.fact_check_outlined),
                          selectedIcon: Icon(Icons.fact_check),
                          label: Text('Review'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.map_outlined),
                          selectedIcon: Icon(Icons.map),
                          label: Text('Guides'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.people_outline),
                          selectedIcon: Icon(Icons.people),
                          label: Text('Users'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.history_outlined),
                          selectedIcon: Icon(Icons.history),
                          label: Text('Audit'),
                        ),
                      ],
                    ),
                    const VerticalDivider(thickness: 1, width: 1),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshAll,
                        child: content,
                      ),
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: content,
                ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Overview',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.fact_check_outlined),
                      selectedIcon: Icon(Icons.fact_check),
                      label: 'Review',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map),
                      label: 'Guides',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: 'Users',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history),
                      label: 'Audit',
                    ),
                  ],
                ),
        );
      },
    );
  }
}
