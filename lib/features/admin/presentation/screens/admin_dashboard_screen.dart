import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../../../../controllers/admin_controller.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/guide_controller.dart';
import '../../../../controllers/localeats_controller.dart';
import '../../../../controllers/spot_controller.dart';
import '../../../influencer_applications/presentation/influencer_application_controller.dart';
import 'admin_content_page.dart';
import 'admin_more_page.dart';
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
  String _reviewSubFilter = 'Submissions';
  String _reviewSubmissionFilter = 'Spots';

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

  void _navigateToTab(
    int index, {
    String? subFilter,
    String? submissionFilter,
  }) {
    setState(() {
      _selectedIndex = index;
      if (subFilter != null) {
        _reviewSubFilter = subFilter;
      }
      if (submissionFilter != null) {
        _reviewSubmissionFilter = submissionFilter;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    if (auth.currentUser?.role != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
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

    final isAnyLoading = admin.isRefreshing ||
        spots.isLoading ||
        spots.isLoadingPending ||
        localEats.isLoading ||
        localEats.isLoadingPending ||
        guides.isLoading ||
        guides.isLoadingAdminDrafts ||
        applications.isLoading ||
        applications.isLoadingPending;

    final pages = [
      AdminOverviewPage(onNavigateToTab: _navigateToTab),
      AdminReviewQueuePage(
        key: ValueKey(
          'review_${_reviewSubFilter}_$_reviewSubmissionFilter',
        ),
        initialFilter: _reviewSubFilter,
        initialSubmissionFilter: _reviewSubmissionFilter,
      ),
      const AdminContentPage(),
      const AdminUsersPage(),
      AdminMorePage(
        onOpenQueue: (filter, {submissionFilter}) => _navigateToTab(
          1,
          subFilter: filter,
          submissionFilter: submissionFilter,
        ),
      ),
    ];

    const sectionTitles = [
      'Overview',
      'Review Queue',
      'Content',
      'User Management',
      'More',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        final content = IndexedStack(
          index: _selectedIndex,
          children: pages,
        );

        return Scaffold(
          appBar: AppBar(
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
                  tooltip: context.tr('Refresh all'),
                  onPressed: _refreshAll,
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle_outlined),
                tooltip: context.tr('Admin account'),
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
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.dashboard_outlined),
                          selectedIcon: const Icon(Icons.dashboard),
                          label: Text(context.tr('Overview')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.fact_check_outlined),
                          selectedIcon: const Icon(Icons.fact_check),
                          label: Text(context.tr('Queue')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.inventory_2_outlined),
                          selectedIcon: const Icon(Icons.inventory_2),
                          label: Text(context.tr('Content')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.people_outline),
                          selectedIcon: const Icon(Icons.people),
                          label: Text(context.tr('Users')),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.more_horiz),
                          selectedIcon: const Icon(Icons.more_horiz),
                          label: Text(context.tr('More')),
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
                  height: 72,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.dashboard_outlined),
                      selectedIcon: const Icon(Icons.dashboard),
                      label: context.tr('Overview'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.fact_check_outlined),
                      selectedIcon: const Icon(Icons.fact_check),
                      label: context.tr('Queue'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.inventory_2_outlined),
                      selectedIcon: const Icon(Icons.inventory_2),
                      label: context.tr('Content'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.people_outline),
                      selectedIcon: const Icon(Icons.people),
                      label: context.tr('Users'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.more_horiz),
                      selectedIcon: const Icon(Icons.more_horiz),
                      label: context.tr('More'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
