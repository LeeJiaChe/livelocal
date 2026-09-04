import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../../../../screens/neighbourhood_explorer_screen.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../navigation/presentation/explore_hub_screen.dart';
import '../../../navigation/presentation/role_home_screen.dart';
import 'admin_audit_page.dart';

class AdminMorePage extends StatelessWidget {
  const AdminMorePage({
    super.key,
    required this.onOpenQueue,
  });

  final void Function(String filter, {String? submissionFilter}) onOpenQueue;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text('More', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Applications, safety work, audit records, and workspace utilities.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          _MoreTile(
            icon: Icons.verified_user_outlined,
            title: 'Creator Applications',
            subtitle: 'Review eligibility and information requests',
            onTap: () => onOpenQueue(
              'Submissions',
              submissionFilter: 'Creators',
            ),
          ),
          _MoreTile(
            icon: Icons.flag_outlined,
            title: 'Reports',
            subtitle: 'Resolve content and safety reports',
            onTap: () => onOpenQueue('Reports'),
          ),
          _MoreTile(
            icon: Icons.support_agent_outlined,
            title: 'Account Appeals',
            subtitle: 'Review account access decisions',
            onTap: () => onOpenQueue('Appeals'),
          ),
          _MoreTile(
            icon: Icons.history_outlined,
            title: 'Audit History',
            subtitle: 'Trace administrative actions and reasons',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const _AuditHistoryScreen(),
              ),
            ),
          ),
          const Divider(height: 32),
          _MoreTile(
            icon: Icons.public_outlined,
            title: 'Preview public experience',
            subtitle: 'Open discovery without mixing it into Admin Overview',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const _PublicPreviewScreen(),
              ),
            ),
          ),
          _MoreTile(
            icon: Icons.translate,
            title: 'Language',
            subtitle: context.watch<AppLocaleController>().isMalay
                ? 'Bahasa Malaysia'
                : 'English',
            onTap: () => _chooseLanguage(context),
          ),
          _MoreTile(
            icon: Icons.logout,
            title: 'Sign out',
            subtitle: 'End this administrator session',
            onTap: context.read<AuthController>().logout,
          ),
        ],
      );

  Future<void> _chooseLanguage(BuildContext context) async {
    final current = context.read<AppLocaleController>();
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: current.locale.languageCode == 'en'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(sheetContext, 'en'),
            ),
            ListTile(
              title: const Text('Bahasa Malaysia'),
              trailing: current.locale.languageCode == 'ms'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(sheetContext, 'ms'),
            ),
          ],
        ),
      ),
    );
    if (selected != null) await current.setLanguage(selected);
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        minTileHeight: 64,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}

class _AuditHistoryScreen extends StatelessWidget {
  const _AuditHistoryScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Audit History')),
        body: const AdminAuditPage(),
      );
}

class _PublicPreviewScreen extends StatefulWidget {
  const _PublicPreviewScreen();

  @override
  State<_PublicPreviewScreen> createState() => _PublicPreviewScreenState();
}

class _PublicPreviewScreenState extends State<_PublicPreviewScreen> {
  int _currentIndex = 0;
  final ValueNotifier<int> _exploreTabNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _exploreTabNotifier.dispose();
    super.dispose();
  }

  void _showReadOnlyNotice(String action) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Public Preview (Read-Only): $action requires logging in as a tourist.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final home = RoleHomeScreen(
      onOpenExplore: ([int tabIndex = 0]) {
        _exploreTabNotifier.value = tabIndex;
        setState(() => _currentIndex = 1);
      },
      onOpenPlanning: () => _showReadOnlyNotice('Trip planning'),
      onOpenStudio: () => _showReadOnlyNotice('Creator Studio'),
    );

    final pages = [
      home,
      ExploreHubScreen(selectedTabNotifier: _exploreTabNotifier),
      const NeighbourhoodExplorerScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Public Preview (Read-Only)'),
        backgroundColor: theme.colorScheme.secondaryContainer,
      ),
      body: Column(
        children: [
          Container(
            color: theme.colorScheme.tertiaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 20,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Previewing public discovery experience as Guest',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Guides',
          ),
        ],
      ),
    );
  }
}
