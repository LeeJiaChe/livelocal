import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';
import '../controllers/localeats_controller.dart';
import '../controllers/spot_controller.dart';
import '../features/guides/presentation/guide_controller.dart';
import '../features/influencer_applications/presentation/influencer_application_controller.dart';
import '../features/restaurants/domain/local_eats_repository.dart';
import '../features/spots/domain/spot_repository.dart';
import '../models/restaurant_model.dart';
import '../models/spot_model.dart';
import '../shared/presentation/contributions/contribution_status_chip.dart';
import 'add_restaurant_screen.dart';
import 'guide_detail_screen.dart';
import 'restaurant_detail_screen.dart';
import 'spot_detail_screen.dart';
import 'submit_spot_screen.dart';

class MySubmissionsScreen extends StatefulWidget {
  const MySubmissionsScreen({super.key});

  @override
  State<MySubmissionsScreen> createState() => _MySubmissionsScreenState();
}

class _MySubmissionsScreenState extends State<MySubmissionsScreen> {
  bool _loading = true;

  bool get _isCreator =>
      context.read<AuthController>().currentUser?.role == 'influencer';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final futures = <Future<void>>[
      context.read<SpotController>().loadOwnedSubmissions(),
      context.read<GuideController>().loadMySubmissions(),
    ];
    if (_isCreator) {
      futures.add(
        context.read<LocalEatsController>().loadOwnedRestaurantSubmissions(),
      );
    } else {
      futures.add(
        context.read<InfluencerApplicationController>().loadMine(),
      );
    }
    await Future.wait(futures);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spots = context.watch<SpotController>();
    final guides = context.watch<GuideController>();
    final restaurants = context.watch<LocalEatsController>();
    final influencerCtrl = context.watch<InfluencerApplicationController>();
    final application = influencerCtrl.mine;

    return Scaffold(
      appBar: AppBar(title: const Text('My Submissions')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x2,
            AppSpacing.x1,
            AppSpacing.x2,
            AppSpacing.x4,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contribution history',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track the status of your submitted places, travel guides, and creator applications.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x2),

            // CREATOR APPLICATION STATUS BANNER (for Tourists)
            if (!_isCreator && application != null) ...[
              _CreatorApplicationStatusCard(
                status: application.status,
                onTap: () =>
                    Navigator.pushNamed(context, '/creator-application'),
              ),
              const SizedBox(height: AppSpacing.x2),
            ],

            if (_loading) ...[
              const SizedBox(height: 40),
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              // 1. LOCAL SPOTS
              _SectionHeader(
                title: 'Local spots',
                count: spots.ownedSubmissions.length,
                onAdd: () => Navigator.pushNamed(context, '/submit-spot'),
                addLabel: 'Share place',
              ),
              const SizedBox(height: AppSpacing.x1),
              if (spots.ownedSubmissions.isEmpty)
                _EmptySectionCard(
                  title: 'No places submitted',
                  message:
                      'Share heritage, nature or local spots with travellers.',
                  actionLabel: context.tr('Share a place'),
                  onAction: () => Navigator.pushNamed(context, '/submit-spot'),
                )
              else
                ...spots.ownedSubmissions.map(
                  (spot) => _SubmissionCard(
                    title: spot.name,
                    subtitle: '${spot.city}, ${spot.state}',
                    status: spot.status,
                    reason: spot.decisionReason,
                    onView: spot.status == 'approved'
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => SpotDetailScreen(spot: spot),
                              ),
                            )
                        : null,
                    onEdit: () => _editSpot(spot),
                    onWithdraw: _isAwaitingReview(spot.status)
                        ? () => _withdrawSpot(spot)
                        : null,
                    onDiscard: spot.status == 'draft'
                        ? () => _discardSpot(spot)
                        : null,
                  ),
                ),

              const SizedBox(height: AppSpacing.x3),

              // 2. TRAVEL GUIDES
              _SectionHeader(
                title: 'Travel guides',
                count: guides.mySubmissions.length,
                onAdd: () => Navigator.pushNamed(context, '/submit-guide'),
                addLabel: 'Create guide',
              ),
              const SizedBox(height: AppSpacing.x1),
              if (guides.mySubmissions.isEmpty)
                _EmptySectionCard(
                  title: 'No guides submitted',
                  message: 'Create travel routes and itineraries for Malaysia.',
                  actionLabel: context.tr('Create a travel guide'),
                  onAction: () => Navigator.pushNamed(context, '/submit-guide'),
                )
              else
                ...guides.mySubmissions.map(
                  (guide) => _SubmissionCard(
                    title: guide.title,
                    subtitle:
                        '${guide.locationName}, ${guide.state} · ${guide.stops.length} stops',
                    status: guide.status,
                    reason: null,
                    onView: guide.status == 'approved'
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => GuideDetailScreen(guide: guide),
                              ),
                            )
                        : null,
                    onEdit: null,
                    onWithdraw: null,
                    onDiscard: null,
                  ),
                ),

              // 3. RESTAURANTS (for Creators)
              if (_isCreator) ...[
                const SizedBox(height: AppSpacing.x3),
                _SectionHeader(
                  title: 'Restaurants',
                  count: restaurants.ownedRestaurantSubmissions.length,
                  onAdd: () => Navigator.pushNamed(context, '/add-restaurant'),
                  addLabel: 'Recommend food',
                ),
                const SizedBox(height: AppSpacing.x1),
                if (restaurants.ownedRestaurantSubmissions.isEmpty)
                  _EmptySectionCard(
                    title: 'No restaurants submitted',
                    message:
                        'Recommend authentic eateries and local food gems.',
                    actionLabel: context.tr('Recommend a restaurant'),
                    onAction: () =>
                        Navigator.pushNamed(context, '/add-restaurant'),
                  )
                else
                  ...restaurants.ownedRestaurantSubmissions.map(
                    (restaurant) => _SubmissionCard(
                      title: restaurant.name,
                      subtitle:
                          '${restaurant.city}, ${restaurant.state} · ${restaurant.cuisineType}',
                      status: restaurant.status,
                      reason: restaurant.decisionReason,
                      onView: restaurant.status == 'approved'
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => RestaurantDetailScreen(
                                    restaurant: restaurant,
                                  ),
                                ),
                              )
                          : null,
                      onEdit: () => _editRestaurant(restaurant),
                      onWithdraw: _isAwaitingReview(restaurant.status)
                          ? () => _withdrawRestaurant(restaurant)
                          : null,
                      onDiscard: restaurant.status == 'draft'
                          ? () => _discardRestaurant(restaurant)
                          : null,
                    ),
                  ),
              ],

              if (spots.errorMessage != null ||
                  guides.errorMessage != null ||
                  (_isCreator && restaurants.errorMessage != null)) ...[
                const SizedBox(height: AppSpacing.x2),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x2),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: colorScheme.onErrorContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          spots.errorMessage ??
                              guides.errorMessage ??
                              restaurants.errorMessage!,
                          style: TextStyle(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  bool _isAwaitingReview(String status) =>
      status == 'submitted' || status == 'under_review';

  Future<void> _editSpot(SpotModel spot) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SubmitSpotScreen(source: spot),
      ),
    );
    await _load();
  }

  Future<void> _editRestaurant(RestaurantModel restaurant) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AddRestaurantScreen(source: restaurant),
      ),
    );
    await _load();
  }

  Future<void> _withdrawSpot(SpotModel spot) async {
    final confirmed = await _confirm(
      title: 'Withdraw this submission?',
      body: spot.hasApprovedRevision
          ? 'The approved version will remain public. This pending revision will stay in history.'
          : 'This submission will leave the review queue. You can revise and resubmit it later.',
      action: 'Withdraw',
    );
    if (!mounted || !confirmed) return;
    final saved = await context.read<SpotController>().withdrawSubmission(spot);
    if (!mounted) return;
    _message(saved ? 'Spot submission withdrawn.' : 'Withdrawal failed.');
    await _load();
  }

  Future<void> _withdrawRestaurant(RestaurantModel restaurant) async {
    final confirmed = await _confirm(
      title: 'Withdraw this restaurant revision?',
      body: restaurant.hasApprovedRevision
          ? 'The approved listing will remain public. This pending revision will stay in history.'
          : 'This submission will leave the review queue. You can revise and resubmit it later.',
      action: 'Withdraw',
    );
    if (!mounted || !confirmed) return;
    final saved = await context
        .read<LocalEatsController>()
        .withdrawRestaurantSubmission(restaurant);
    if (!mounted) return;
    _message(saved ? 'Restaurant submission withdrawn.' : 'Withdrawal failed.');
    await _load();
  }

  Future<void> _discardSpot(SpotModel spot) async {
    final confirmed = await _confirm(
      title: 'Discard this draft?',
      body: spot.hasApprovedRevision
          ? 'The draft and any unshared replacement photo will be removed. The approved version stays public.'
          : 'This private draft and its uploaded photo will be permanently removed.',
      action: 'Discard draft',
      destructive: true,
    );
    if (!mounted || !confirmed) return;
    final revisionId = spot.revisionId;
    if (revisionId == null) return;
    final saved = await context.read<SpotController>().discardDraft(
          SpotDraftResult(
            spotId: spot.id,
            revisionId: revisionId,
            probableDuplicates: const [],
            imagePath: spot.imagePath,
          ),
        );
    if (!mounted) return;
    _message(saved ? 'Spot draft discarded.' : 'The draft was not discarded.');
    await _load();
  }

  Future<void> _discardRestaurant(RestaurantModel restaurant) async {
    final confirmed = await _confirm(
      title: 'Discard this restaurant draft?',
      body: restaurant.hasApprovedRevision
          ? 'The draft and any unshared replacement photo will be removed. The approved listing stays public.'
          : 'This private draft and its uploaded photo will be permanently removed.',
      action: 'Discard draft',
      destructive: true,
    );
    if (!mounted || !confirmed) return;
    final revisionId = restaurant.revisionId;
    if (revisionId == null) return;
    final saved =
        await context.read<LocalEatsController>().resolveRestaurantDuplicate(
              RestaurantDraftResult(
                restaurantId: restaurant.id,
                revisionId: revisionId,
                probableDuplicates: const [],
                imagePath: restaurant.coverImagePath,
              ),
              discard: true,
            );
    if (!mounted) return;
    _message(
      saved ? 'Restaurant draft discarded.' : 'The draft was not discarded.',
    );
    await _load();
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      )
                    : null,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    this.onAdd,
    this.addLabel,
  });

  final String title;
  final int count;
  final VoidCallback? onAdd;
  final String? addLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const Spacer(),
        if (onAdd != null && addLabel != null)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text(addLabel!),
          ),
      ],
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.title,
    required this.subtitle,
    required this.status,
    this.reason,
    this.onView,
    this.onEdit,
    this.onWithdraw,
    this.onDiscard,
  });

  final String title;
  final String subtitle;
  final String status;
  final String? reason;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onWithdraw;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.x1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ContributionStatusChip(status: status, compact: true),
              ],
            ),
            if (reason?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reviewer note: $reason',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onView != null)
                  FilledButton.tonalIcon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View published'),
                  ),
                if (onEdit != null)
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(
                      _isAwaiting(status)
                          ? 'Withdraw and edit'
                          : status == 'draft'
                              ? 'Continue editing'
                              : 'Create revision',
                    ),
                  ),
                if (onWithdraw != null)
                  TextButton(
                    onPressed: onWithdraw,
                    child: const Text('Withdraw'),
                  ),
                if (onDiscard != null)
                  TextButton(
                    onPressed: onDiscard,
                    child: const Text('Discard draft'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static bool _isAwaiting(String status) =>
      status == 'submitted' || status == 'under_review';
}

class _CreatorApplicationStatusCard extends StatelessWidget {
  const _CreatorApplicationStatusCard({
    required this.status,
    required this.onTap,
  });

  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: colorScheme.onSecondaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creator application',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to view your application status or details.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ContributionStatusChip(status: status, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
