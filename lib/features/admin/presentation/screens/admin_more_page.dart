import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../../../../screens/main_navigation_screen.dart';
import '../../../auth/presentation/auth_controller.dart';
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

class _PublicPreviewScreen extends StatelessWidget {
  const _PublicPreviewScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Preview public experience'),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        ),
        body: const MainNavigationScreen(),
      );
}
