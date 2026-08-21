import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../controllers/admin_controller.dart';
import '../../../../controllers/guide_controller.dart';
import '../../../../controllers/localeats_controller.dart';
import '../../../../controllers/spot_controller.dart';
import '../../../guides/presentation/admin_guide_editor_screen.dart';
import '../../../influencer_applications/presentation/influencer_application_controller.dart';
import '../widgets/admin_metric_card.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_state_panel.dart';

class AdminOverviewPage extends StatelessWidget {
  const AdminOverviewPage({
    super.key,
    required this.onNavigateToTab,
  });

  final void Function(int tabIndex, {String? subFilter}) onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final admin = context.watch<AdminController>();
    final spots = context.watch<SpotController>();
    final localEats = context.watch<LocalEatsController>();
    final guides = context.watch<GuideController>();
    final applications = context.watch<InfluencerApplicationController>();

    final submittedGuidesCount = guides.adminDrafts
        .where((g) => g.status == 'submitted' || g.status == 'under_review')
        .length;

    final needsReviewCount = spots.pendingSpots.length +
        localEats.pendingRestaurants.length +
        submittedGuidesCount +
        applications.pending.length +
        admin.moderationCases.length +
        admin.appeals.length;

    final publishedContentCount = (admin.statistics?.spotsPublished ?? 0) +
        (admin.statistics?.restaurantsPublished ?? 0) +
        (admin.statistics?.guidesPublished ?? guides.guides.length) +
        (admin.statistics?.reviewsPublished ?? 0);

    final recentAudit = admin.auditEvents.take(4).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Center',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Platform operations and safety',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (admin.lastUpdatedAt != null)
              Text(
                'Updated ${admin.lastUpdatedAt!.hour.toString().padLeft(2, '0')}:${admin.lastUpdatedAt!.minute.toString().padLeft(2, '0')}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isWide ? 1.3 : 1.05,
              children: [
                AdminMetricCard(
                  label: 'Needs review',
                  value: needsReviewCount,
                  icon: Icons.fact_check_outlined,
                  color: needsReviewCount > 0
                      ? Colors.amber.shade800
                      : theme.colorScheme.primary,
                  onTap: () => onNavigateToTab(1),
                ),
                AdminMetricCard(
                  label: 'Published content',
                  value: publishedContentCount,
                  icon: Icons.public_outlined,
                  subtitle: 'Live listings',
                ),
                AdminMetricCard(
                  label: 'Total users',
                  value: admin.totalUsers,
                  icon: Icons.people_outline,
                  onTap: () => onNavigateToTab(3),
                ),
                AdminMetricCard(
                  label: 'Restricted',
                  value: admin.suspendedUsersCount,
                  icon: Icons.gpp_maybe_outlined,
                  color: admin.suspendedUsersCount > 0
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  onTap: () => onNavigateToTab(3),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        AdminSectionHeader(
          title: 'Action items',
          count: needsReviewCount,
          subtitle: 'Submissions, reports, and appeals awaiting review',
        ),
        if (needsReviewCount == 0)
          const Card(
            elevation: 0,
            child: AdminStatePanel(
              icon: Icons.check_circle_outline,
              title: 'All caught up',
              description:
                  'No items currently require administrator moderation or review.',
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                if (spots.pendingSpots.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: const Text('Spot submissions'),
                    subtitle: Text(
                      '${spots.pendingSpots.length} pending moderation',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigateToTab(1, subFilter: 'Submissions'),
                  ),
                if (localEats.pendingRestaurants.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.restaurant_outlined),
                    title: const Text('Restaurant submissions'),
                    subtitle: Text(
                      '${localEats.pendingRestaurants.length} pending moderation',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigateToTab(1, subFilter: 'Submissions'),
                  ),
                if (submittedGuidesCount > 0)
                  ListTile(
                    leading: const Icon(Icons.route_outlined),
                    title: const Text('Guide submissions'),
                    subtitle: Text(
                      '$submittedGuidesCount pending moderation',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigateToTab(1, subFilter: 'Submissions'),
                  ),
                if (applications.pending.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: const Text('Creator applications'),
                    subtitle: Text(
                      '${applications.pending.length} pending review',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigateToTab(1, subFilter: 'Submissions'),
                  ),
                if (admin.moderationCases.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Content reports'),
                    subtitle: Text(
                      '${admin.moderationCases.length} awaiting resolution',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigateToTab(1, subFilter: 'Reports'),
                  ),
                if (admin.appeals.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined),
                    title: const Text('Account appeals'),
                    subtitle: Text(
                      '${admin.appeals.length} awaiting review',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onNavigateToTab(1, subFilter: 'Appeals'),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        const AdminSectionHeader(
          title: 'Quick Actions',
          subtitle: 'Common administrative operations',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const AdminGuideEditorScreen(),
                ),
              ),
              icon: const Icon(Icons.add_road_outlined),
              label: const Text('Create guide draft'),
            ),
            OutlinedButton.icon(
              onPressed: () => onNavigateToTab(1),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Review queue'),
            ),
            OutlinedButton.icon(
              onPressed: () => onNavigateToTab(3),
              icon: const Icon(Icons.manage_accounts_outlined),
              label: const Text('Manage users'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AdminSectionHeader(
          title: 'Recent Activity',
          subtitle: 'Administrative decisions and system events',
          action: recentAudit.isNotEmpty
              ? TextButton(
                  onPressed: () => onNavigateToTab(4),
                  child: const Text('View all'),
                )
              : null,
        ),
        if (recentAudit.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No recent audit events recorded.'),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentAudit.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final event = recentAudit[index];
                return ListTile(
                  leading: const Icon(Icons.history_outlined, size: 20),
                  title: Text(
                    event.action.replaceAll('.', ' · '),
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    '${event.actorName} · ${event.targetType}${event.reason == null ? '' : '\n${event.reason}'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    MaterialLocalizations.of(context)
                        .formatShortDate(event.occurredAt),
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
