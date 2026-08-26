import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/guide_controller.dart';
import '../../../controllers/itinerary_controller.dart';
import '../../../controllers/localeats_controller.dart';
import '../../../controllers/spot_controller.dart';
import '../../../models/spot_model.dart';
import '../../../screens/spot_detail_screen.dart';

class RoleHomeScreen extends StatelessWidget {
  const RoleHomeScreen({
    super.key,
    required this.onOpenExplore,
    required this.onOpenPlanning,
    required this.onOpenStudio,
  });

  final VoidCallback onOpenExplore;
  final VoidCallback onOpenPlanning;
  final VoidCallback onOpenStudio;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final spots = context.watch<SpotController>().spots;
    final restaurants = context.watch<LocalEatsController>().restaurants;
    final guides = context.watch<GuideController>().approvedGuides;
    final planning = context.watch<ItineraryController>();
    final isGuest = auth.currentUser == null;
    final isCreator = auth.currentUser?.role == 'influencer';
    final name = auth.currentUser?.fullName.trim();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            context.read<SpotController>().loadSpots(),
            context.read<LocalEatsController>().loadData(),
            context.read<GuideController>().loadGuides(),
            if (!isGuest) ...[
              context.read<ItineraryController>().loadSavedPlaces(),
              context.read<ItineraryController>().loadItineraries(),
            ],
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _EditorialHero(
                eyebrow: isCreator
                    ? 'Creator · Malaysia'
                    : isGuest
                        ? 'Your local guide to Malaysia'
                        : 'Your Malaysia',
                title: name == null || name.isEmpty
                    ? 'Find a place worth the detour'
                    : 'Welcome back, $name',
                body: isGuest
                    ? 'Browse trusted local places, restaurants, and community guides before you decide where to go.'
                    : 'Continue a plan, revisit a saved place, or discover somewhere local today.',
                imageUrl: spots.isEmpty ? null : spots.first.imageUrl,
                onExplore: onOpenExplore,
              ),
            ),
            if (!isGuest)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x2,
                    AppSpacing.x3,
                    AppSpacing.x2,
                    0,
                  ),
                  child: _ContinuePlanning(
                    savedCount: planning.savedPlaces.length,
                    tripCount: planning.savedItineraries.length,
                    onTap: onOpenPlanning,
                  ),
                ),
              ),
            if (isCreator)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x2,
                    AppSpacing.x2,
                    AppSpacing.x2,
                    0,
                  ),
                  child: _CreatorCallout(onTap: onOpenStudio),
                ),
              ),
            SliverToBoxAdapter(
              child: _SectionHeading(
                title: 'Places to know',
                subtitle: 'Approved local picks from across Malaysia',
                onViewAll: onOpenExplore,
              ),
            ),
            if (spots.isEmpty)
              const SliverToBoxAdapter(
                child: _InlineEmpty(
                  icon: Icons.place_outlined,
                  message: 'Places will appear here when they are available.',
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 244,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x2,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: spots.take(6).length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.x2),
                    itemBuilder: (context, index) => _SpotFeatureCard(
                      spot: spots[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => SpotDetailScreen(spot: spots[index]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x2,
                  AppSpacing.x3,
                  AppSpacing.x2,
                  AppSpacing.x1,
                ),
                child: Text(
                  'Explore by mood',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x2,
                0,
                AppSpacing.x2,
                AppSpacing.x6,
              ),
              sliver: SliverGrid.count(
                crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 3 : 2,
                mainAxisSpacing: AppSpacing.x1,
                crossAxisSpacing: AppSpacing.x1,
                childAspectRatio: 1.55,
                children: [
                  _DiscoveryTile(
                    icon: Icons.park_outlined,
                    title: 'Local Spots',
                    detail: '${spots.length} approved places',
                    onTap: onOpenExplore,
                  ),
                  _DiscoveryTile(
                    icon: Icons.restaurant_outlined,
                    title: 'Local Eats',
                    detail: '${restaurants.length} restaurants',
                    onTap: onOpenExplore,
                  ),
                  _DiscoveryTile(
                    icon: Icons.route_outlined,
                    title: 'Community Guides',
                    detail: '${guides.length} routes',
                    onTap: onOpenExplore,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorialHero extends StatelessWidget {
  const _EditorialHero({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.onExplore,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String? imageUrl;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 310),
      decoration: BoxDecoration(color: scheme.primary),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (imageUrl case final image?)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: image,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    scheme.primary.withValues(alpha: 0.32),
                    scheme.primary.withValues(alpha: 0.96),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 34),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.primaryContainer,
                            letterSpacing: 0.8,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: scheme.onPrimary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onPrimary.withValues(alpha: 0.88),
                          ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.surface,
                        foregroundColor: scheme.primary,
                      ),
                      onPressed: onExplore,
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('Explore Malaysia'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinuePlanning extends StatelessWidget {
  const _ContinuePlanning({
    required this.savedCount,
    required this.tripCount,
    required this.onTap,
  });

  final int savedCount;
  final int tripCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Row(
            children: [
              const Icon(Icons.luggage_outlined, size: 30),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue planning',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text('$savedCount saved places · $tripCount trips'),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatorCallout extends StatelessWidget {
  const _CreatorCallout({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        tileColor: Theme.of(context).colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: const Icon(Icons.dashboard_customize_outlined),
        title: const Text('Creator Studio'),
        subtitle: const Text('Continue drafts and follow moderation decisions'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.onViewAll,
  });
  final String title;
  final String subtitle;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onViewAll, child: const Text('View all')),
          ],
        ),
      );
}

class _SpotFeatureCard extends StatelessWidget {
  const _SpotFeatureCard({required this.spot, required this.onTap});
  final SpotModel spot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 248,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CachedNetworkImage(
                    imageUrl: spot.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Center(
                      child: Icon(Icons.landscape_outlined),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${spot.city}, ${spot.state}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _DiscoveryTile extends StatelessWidget {
  const _DiscoveryTile({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      );
}
