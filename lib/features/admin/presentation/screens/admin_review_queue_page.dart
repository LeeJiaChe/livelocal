import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../controllers/admin_controller.dart';
import '../../../../controllers/guide_controller.dart';
import '../../../../controllers/localeats_controller.dart';
import '../../../../controllers/spot_controller.dart';
import '../../../../models/guide_model.dart';
import '../../../../models/restaurant_model.dart';
import '../../../../models/spot_model.dart';
import '../../../influencer_applications/domain/influencer_application_repository.dart';
import '../../../influencer_applications/presentation/influencer_application_controller.dart';
import '../../domain/admin_repository.dart';
import '../dialogs/admin_reason_dialog.dart';
import '../widgets/admin_queue_card.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_state_panel.dart';

class AdminReviewQueuePage extends StatefulWidget {
  const AdminReviewQueuePage({
    super.key,
    this.initialFilter = 'All',
  });

  final String initialFilter;

  @override
  State<AdminReviewQueuePage> createState() => _AdminReviewQueuePageState();
}

class _AdminReviewQueuePageState extends State<AdminReviewQueuePage> {
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _moderateSpot(SpotModel spot, String decision) async {
    final reason = await showAdminReasonDialog(
      context,
      title: decision == 'approved' ? 'Approve spot?' : 'Reject spot?',
      prompt: decision == 'approved'
          ? 'Record why this submission meets publication guidelines.'
          : 'Explain what the owner must correct before resubmitting.',
      destructive: decision == 'rejected',
    );
    if (reason == null || !mounted) return;
    final controller = context.read<SpotController>();
    try {
      if (decision == 'approved') {
        await controller.approveSpotWithReason(spot, reason);
      } else {
        await controller.rejectSpot(spot, reason);
      }
      _showMessage('Spot decision recorded.');
    } catch (_) {
      _showMessage(
          controller.errorMessage ?? 'Spot decision could not be saved.');
    }
  }

  Future<void> _moderateRestaurant(
    RestaurantModel restaurant,
    String decision,
  ) async {
    final reason = await showAdminReasonDialog(
      context,
      title:
          decision == 'approved' ? 'Approve restaurant?' : 'Reject restaurant?',
      prompt: decision == 'approved'
          ? 'Record why the business details and supporting post are suitable.'
          : 'Explain what must be corrected before resubmission.',
      destructive: decision == 'rejected',
    );
    if (reason == null || !mounted) return;
    final controller = context.read<LocalEatsController>();
    final saved = await controller.moderateRestaurant(
      restaurant,
      decision,
      reason,
    );
    _showMessage(
      saved
          ? 'Restaurant moderation decision recorded.'
          : controller.errorMessage ??
              'The restaurant decision could not be saved.',
    );
  }

  Future<void> _moderateGuide(GuideModel guide, String decision) async {
    final reason = await showAdminReasonDialog(
      context,
      title: decision == 'approved' ? 'Approve guide?' : 'Reject guide?',
      prompt: decision == 'approved'
          ? 'Confirm that every stop and route instruction is suitable for publication.'
          : 'Explain what needs to change before a future submission.',
      destructive: decision == 'rejected',
    );
    if (reason == null || !mounted) return;
    final controller = context.read<GuideController>();
    final saved = await controller.moderateSubmission(guide, decision, reason);
    _showMessage(
      saved
          ? 'Guide decision recorded.'
          : controller.errorMessage ?? 'The guide decision could not be saved.',
    );
  }

  Future<void> _moderateCreator(
    InfluencerApplication application,
    String decision,
  ) async {
    final reason = await showAdminReasonDialog(
      context,
      title: switch (decision) {
        'approved' => 'Approve creator application?',
        'needs_information' => 'Request more information?',
        _ => 'Reject creator application?',
      },
      prompt: decision == 'approved'
          ? 'Record why the creator account meets the current rules.'
          : 'Explain the decision clearly enough for the applicant to act on it.',
      destructive: decision == 'rejected',
    );
    if (reason == null || !mounted) return;
    final controller = context.read<InfluencerApplicationController>();
    final saved = await controller.decide(application, decision, reason);
    _showMessage(
      saved
          ? 'Creator application decision recorded.'
          : controller.errorMessage ??
              'The application decision could not be saved.',
    );
  }

  Future<void> _moderateReport(
    AdminModerationCase moderationCase,
    String decision,
  ) async {
    final reason = await showAdminReasonDialog(
      context,
      title: switch (decision) {
        'upheld' => moderationCase.reason == 'broken_link'
            ? 'Remove the reported external link?'
            : 'Remove the reported content?',
        'dismissed' => 'Dismiss this report?',
        _ => 'Escalate this report?',
      },
      prompt: 'Record the evidence-based reason for this decision.',
      destructive: decision == 'upheld',
    );
    if (reason == null || !mounted) return;
    final controller = context.read<AdminController>();
    final saved = await controller.decideModerationCase(
      moderationCase: moderationCase,
      decision: decision,
      reason: reason,
    );
    _showMessage(
      saved
          ? 'Moderation decision recorded.'
          : controller.errorMessage ?? 'The decision could not be saved.',
    );
  }

  Future<void> _moderateAppeal(
    AdminAppealCase appeal,
    String decision,
  ) async {
    final reason = await showAdminReasonDialog(
      context,
      title: decision == 'upheld'
          ? 'Accept appeal and restore access?'
          : 'Do not accept this appeal?',
      prompt:
          'Record the evidence-based outcome. This will be shown in the appeal history.',
      destructive: decision == 'dismissed',
    );
    if (reason == null || !mounted) return;
    final controller = context.read<AdminController>();
    final saved = await controller.decideAppeal(
      appeal: appeal,
      decision: decision,
      reason: reason,
    );
    _showMessage(
      saved
          ? 'Appeal decision recorded.'
          : controller.errorMessage ??
              'The appeal decision could not be saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final spots = context.watch<SpotController>();
    final localEats = context.watch<LocalEatsController>();
    final guides = context.watch<GuideController>();
    final applications = context.watch<InfluencerApplicationController>();
    final admin = context.watch<AdminController>();

    final pendingGuideSubmissions = guides.adminDrafts
        .where((g) => g.status == 'submitted' || g.status == 'under_review')
        .toList();

    final showSubmissions =
        _selectedFilter == 'All' || _selectedFilter == 'Submissions';
    final showReports =
        _selectedFilter == 'All' || _selectedFilter == 'Reports';
    final showAppeals =
        _selectedFilter == 'All' || _selectedFilter == 'Appeals';

    final totalItems = (showSubmissions
            ? spots.pendingSpots.length +
                localEats.pendingRestaurants.length +
                pendingGuideSubmissions.length +
                applications.pending.length
            : 0) +
        (showReports ? admin.moderationCases.length : 0) +
        (showAppeals ? admin.appeals.length : 0);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        AdminSectionHeader(
          title: 'Review Queue',
          count: totalItems,
          subtitle: 'Moderate submissions, reports, and appeals',
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in [
                'All',
                'Submissions',
                'Reports',
                'Appeals'
              ]) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = filter);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (totalItems == 0)
          AdminStatePanel(
            icon: Icons.done_all_outlined,
            title: 'Queue is clear',
            description: switch (_selectedFilter) {
              'Submissions' => 'No submissions currently awaiting moderation.',
              'Reports' => 'No content reports currently awaiting moderation.',
              'Appeals' => 'No account appeals currently awaiting review.',
              _ => 'No review items found for this filter.',
            },
          )
        else ...[
          if (showSubmissions) ...[
            for (final spot in spots.pendingSpots)
              AdminQueueCard(
                typeLabel: 'SPOT SUBMISSION',
                typeIcon: Icons.place_outlined,
                title: spot.name,
                subtitle: '${spot.category} · ${spot.city}, ${spot.state}',
                details: spot.description,
                status: spot.status,
                actions: [
                  OutlinedButton(
                    onPressed: () => _moderateSpot(spot, 'rejected'),
                    child: const Text('Reject'),
                  ),
                  FilledButton(
                    onPressed: () => _moderateSpot(spot, 'approved'),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            for (final restaurant in localEats.pendingRestaurants)
              AdminQueueCard(
                typeLabel: 'RESTAURANT SUBMISSION',
                typeIcon: Icons.restaurant_outlined,
                title: restaurant.name,
                subtitle:
                    '${restaurant.cuisineType} · ${restaurant.city}, ${restaurant.state}',
                details: '${restaurant.address}\n${restaurant.socialMediaUrl}',
                status: restaurant.status,
                actions: [
                  OutlinedButton(
                    onPressed: () =>
                        _moderateRestaurant(restaurant, 'rejected'),
                    child: const Text('Reject'),
                  ),
                  FilledButton(
                    onPressed: () =>
                        _moderateRestaurant(restaurant, 'approved'),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            for (final guide in pendingGuideSubmissions)
              AdminQueueCard(
                typeLabel: 'GUIDE SUBMISSION',
                typeIcon: Icons.route_outlined,
                title: guide.title,
                subtitle:
                    '${guide.locationName}, ${guide.state} · ${guide.stops.length} stops',
                details: guide.routeOverview,
                status: guide.status,
                actions: [
                  OutlinedButton(
                    onPressed: () => _moderateGuide(guide, 'rejected'),
                    child: const Text('Reject'),
                  ),
                  FilledButton(
                    onPressed: () => _moderateGuide(guide, 'approved'),
                    child: const Text('Approve'),
                  ),
                ],
              ),
            for (final application in applications.pending)
              AdminQueueCard(
                typeLabel: 'CREATOR APPLICATION',
                typeIcon: Icons.verified_user_outlined,
                title: application.displayName ?? 'Unnamed applicant',
                subtitle:
                    '${application.socialPlatform ?? 'Platform'} · ${application.followerCount ?? 0} followers · ${application.contentCategory ?? 'General'}',
                details:
                    '${application.profileUrl ?? ''}\n${application.applicationMessage ?? ''}',
                status: application.status,
                actions: [
                  OutlinedButton(
                    onPressed: () => _moderateCreator(application, 'rejected'),
                    child: const Text('Reject'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _moderateCreator(application, 'needs_information'),
                    child: const Text('Request info'),
                  ),
                  FilledButton(
                    onPressed: () => _moderateCreator(application, 'approved'),
                    child: const Text('Approve'),
                  ),
                ],
              ),
          ],
          if (showReports) ...[
            for (final moderationCase in admin.moderationCases)
              AdminQueueCard(
                typeLabel: 'CONTENT REPORT',
                typeIcon: Icons.flag_outlined,
                title:
                    '${moderationCase.targetType}: ${moderationCase.targetPreview}',
                subtitle: 'Reason: ${moderationCase.reason}',
                details: moderationCase.explanation,
                status: moderationCase.status,
                actions: [
                  OutlinedButton(
                    onPressed: () =>
                        _moderateReport(moderationCase, 'dismissed'),
                    child: const Text('Dismiss'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _moderateReport(moderationCase, 'escalated'),
                    child: const Text('Escalate'),
                  ),
                  FilledButton(
                    onPressed: () => _moderateReport(moderationCase, 'upheld'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    child: Text(
                      moderationCase.reason == 'broken_link'
                          ? 'Remove link'
                          : 'Remove content',
                    ),
                  ),
                ],
              ),
          ],
          if (showAppeals) ...[
            for (final appeal in admin.appeals)
              AdminQueueCard(
                typeLabel: 'ACCOUNT APPEAL',
                typeIcon: Icons.support_agent_outlined,
                title: appeal.displayName,
                subtitle: '${appeal.email} · Status: ${appeal.accessStatus}',
                details:
                    'Reason: ${appeal.reason}${appeal.explanation == null ? '' : '\n${appeal.explanation}'}',
                status: appeal.status,
                actions: [
                  OutlinedButton(
                    onPressed: () => _moderateAppeal(appeal, 'dismissed'),
                    child: const Text('Do not accept'),
                  ),
                  FilledButton(
                    onPressed: () => _moderateAppeal(appeal, 'upheld'),
                    child: const Text('Accept & restore'),
                  ),
                ],
              ),
          ],
        ],
      ],
    );
  }
}
