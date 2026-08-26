import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../../../controllers/guide_controller.dart';
import '../../../controllers/localeats_controller.dart';
import '../../../controllers/spot_controller.dart';
import '../../../shared/presentation/contributions/contribution_status_chip.dart';

class CreatorStudioScreen extends StatefulWidget {
  const CreatorStudioScreen({super.key});

  @override
  State<CreatorStudioScreen> createState() => _CreatorStudioScreenState();
}

class _CreatorStudioScreenState extends State<CreatorStudioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SpotController>().loadOwnedSubmissions();
      context.read<LocalEatsController>().loadOwnedRestaurantSubmissions();
      context.read<LocalEatsController>().loadOwnedDiscounts();
      context.read<GuideController>().loadMySubmissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final spots = context.watch<SpotController>().ownedSubmissions;
    final restaurants =
        context.watch<LocalEatsController>().ownedRestaurantSubmissions;
    final guides = context.watch<GuideController>().mySubmissions;
    final allStatuses = [
      ...spots.map((item) => item.status),
      ...restaurants.map((item) => item.status),
      ...guides.map((item) => item.status),
    ];
    int count(String status) =>
        allStatuses.where((value) => value == status).length;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<SpotController>().loadOwnedSubmissions(),
            context
                .read<LocalEatsController>()
                .loadOwnedRestaurantSubmissions(),
            context.read<LocalEatsController>().loadOwnedDiscounts(),
            context.read<GuideController>().loadMySubmissions(),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 104),
          children: [
            Text(
              'Creator Studio',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Create trusted local listings and follow every moderation decision.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusSummary(label: 'Draft', count: count('draft')),
                _StatusSummary(
                  label: 'Pending',
                  count: count('submitted') + count('under_review'),
                ),
                _StatusSummary(
                  label: 'Needs changes',
                  count: count('needs_information') + count('rejected'),
                ),
                _StatusSummary(
                  label: 'Published',
                  count: count('approved'),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Create', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _StudioAction(
              icon: Icons.add_location_alt_outlined,
              title: 'Share a local Spot',
              description:
                  'Add a real place with location details, recommendations, and an original photo.',
              onTap: () => Navigator.pushNamed(context, '/submit-spot'),
            ),
            _StudioAction(
              icon: Icons.auto_awesome_outlined,
              title: 'AI Restaurant Import',
              description:
                  'Start from an individual TikTok or Instagram review post, then verify every generated field.',
              onTap: () => Navigator.pushNamed(context, '/add-restaurant'),
            ),
            _StudioAction(
              icon: Icons.route_outlined,
              title: 'Build a Guide',
              description:
                  'Arrange approved listings and useful custom stops into a moderated local route.',
              onTap: () => Navigator.pushNamed(context, '/submit-guide'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Contribution pipeline',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/my-submissions'),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (allStatuses.isEmpty)
              const _StudioEmpty()
            else ...[
              _PipelineRow(
                title: 'Spot contributions',
                count: spots.length,
                status: spots.isEmpty ? null : spots.first.status,
              ),
              _PipelineRow(
                title: 'Restaurant contributions',
                count: restaurants.length,
                status: restaurants.isEmpty ? null : restaurants.first.status,
              ),
              _PipelineRow(
                title: 'Guide contributions',
                count: guides.length,
                status: guides.isEmpty ? null : guides.first.status,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        width: 136,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Text(label),
          ],
        ),
      );
}

class _StudioAction extends StatelessWidget {
  const _StudioAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(description),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      );
}

class _PipelineRow extends StatelessWidget {
  const _PipelineRow({
    required this.title,
    required this.count,
    required this.status,
  });
  final String title;
  final int count;
  final String? status;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text('$count total'),
        trailing:
            status == null ? null : ContributionStatusChip(status: status!),
      );
}

class _StudioEmpty extends StatelessWidget {
  const _StudioEmpty();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.edit_note_outlined, size: 40),
            SizedBox(height: 10),
            Text('No contributions yet'),
            SizedBox(height: 4),
            Text('Start with a place you know well.'),
          ],
        ),
      );
}
