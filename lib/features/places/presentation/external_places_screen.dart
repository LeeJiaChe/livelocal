import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/itinerary_controller.dart';
import '../../../core/routing/protected_navigation.dart';
import '../../../services/location_service.dart';
import '../../../shared/presentation/app_state_view.dart';
import '../../../shared/presentation/save_to_collection_sheet.dart';
import '../domain/external_place.dart';
import '../domain/place_provider.dart';
import 'place_discovery_controller.dart';

class ExternalPlacesScreen extends StatefulWidget {
  const ExternalPlacesScreen({super.key});

  @override
  State<ExternalPlacesScreen> createState() => _ExternalPlacesScreenState();
}

class _ExternalPlacesScreenState extends State<ExternalPlacesScreen> {
  late final TextEditingController _search;

  static const _categories = <(String, String?)>[
    ('All', null),
    ('Food', 'restaurant'),
    ('Cafes', 'cafe'),
    ('Attractions', 'attraction'),
    ('Museums', 'museum'),
    ('Parks', 'park'),
    ('Beaches', 'beach'),
  ];

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: context.read<PlaceDiscoveryController>().query,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlaceDiscoveryController>();
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.isNearby ? controller.nearby : controller.search,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x2,
                  AppSpacing.x2,
                  AppSpacing.x2,
                  AppSpacing.x1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover Malaysia',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Search real places across Malaysia, alongside LiveLocal community Spots, Eats and Guides.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    SearchBar(
                      key: const Key('external_place_search'),
                      controller: _search,
                      hintText: context.tr('e.g. cafe in Penang'),
                      leading: const Icon(Icons.search),
                      trailing: [
                        if (_search.text.isNotEmpty)
                          IconButton(
                            tooltip: context.tr('Clear search'),
                            onPressed: () {
                              _search.clear();
                              controller.updateQuery('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                      ],
                      onChanged: (value) {
                        controller.updateQuery(value);
                        setState(() {});
                      },
                      onSubmitted: controller.search,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        key: const Key('near_me_button'),
                        onPressed:
                            controller.isLoading ? null : controller.nearby,
                        icon: const Icon(Icons.near_me_outlined),
                        label: const Text('Near me'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(entry.$1),
                              selected: controller.category == entry.$2,
                              onSelected: (_) =>
                                  controller.selectCategory(entry.$2),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (!controller.isLoading && controller.places.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.x1),
                        child: Text(
                          controller.isNearby
                              ? 'Places near your current location'
                              : 'Google Places results',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (controller.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.errorMessage != null &&
                controller.places.isEmpty)
              SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 260),
                  child: AppStateView(
                    icon: controller.locationFailure == null
                        ? Icons.cloud_off_outlined
                        : Icons.location_off_outlined,
                    title: controller.locationFailure == null
                        ? 'Places could not be loaded'
                        : 'Location is not available',
                    message: controller.errorMessage!,
                    actionLabel: _settingsAction(controller.locationFailure)
                        ? 'Open settings'
                        : context.tr('Try again'),
                    onAction: _settingsAction(controller.locationFailure)
                        ? controller.openRelevantSettings
                        : (controller.isNearby
                            ? controller.nearby
                            : controller.search),
                  ),
                ),
              )
            else if (controller.places.isEmpty)
              SliverToBoxAdapter(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 260),
                  child: AppStateView(
                    icon: Icons.travel_explore_outlined,
                    title: controller.query.length < 2
                        ? 'Search thousands of real places'
                        : 'No matching places',
                    message: controller.query.length < 2
                        ? 'Try “museum Kuala Lumpur”, “beach Terengganu”, or use Near me.'
                        : 'Try a broader search, another category, or a nearby city.',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x2,
                  AppSpacing.x1,
                  AppSpacing.x2,
                  AppSpacing.x2,
                ),
                sliver: SliverList.separated(
                  itemCount: controller.places.length +
                      (controller.canLoadMore || controller.isLoadingMore
                          ? 1
                          : 0),
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.x1),
                  itemBuilder: (context, index) {
                    if (index == controller.places.length) {
                      return Center(
                        child: controller.isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(AppSpacing.x2),
                                child: CircularProgressIndicator(),
                              )
                            : OutlinedButton.icon(
                                onPressed: controller.loadMore,
                                icon: const Icon(Icons.expand_more),
                                label: const Text('Load more places'),
                              ),
                      );
                    }
                    return ExternalPlaceCard(place: controller.places[index]);
                  },
                ),
              ),
            if (controller.errorMessage != null && controller.places.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x2,
                    0,
                    AppSpacing.x2,
                    AppSpacing.x2,
                  ),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(controller.errorMessage!),
                      trailing: TextButton(
                        onPressed: controller.loadMore,
                        child: const Text('Retry'),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _settingsAction(LocationRequestFailure? failure) =>
      failure == LocationRequestFailure.serviceDisabled ||
      failure == LocationRequestFailure.deniedForever;
}

class ExternalPlaceCard extends StatelessWidget {
  const ExternalPlaceCard({super.key, required this.place});

  final ExternalPlace place;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('external-place-${place.placeId}'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/external-place-detail'),
            builder: (_) => ExternalPlaceDetailScreen(initialPlace: place),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  _iconForType(place.primaryType),
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.formattedAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (place.rating != null)
                          _Meta(
                            icon: Icons.star,
                            text: '${place.rating!.toStringAsFixed(1)}'
                                '${place.userRatingCount == null ? '' : ' (${place.userRatingCount})'}',
                          ),
                        if (place.openNow != null)
                          _Meta(
                            icon: place.openNow!
                                ? Icons.schedule
                                : Icons.schedule_outlined,
                            text: place.openNow! ? 'Open now' : 'Closed now',
                          ),
                        const _Meta(
                          icon: Icons.verified_outlined,
                          text: 'Google Places',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconForType(String? type) => switch (type) {
        'restaurant' || 'cafe' => Icons.restaurant_outlined,
        'museum' => Icons.museum_outlined,
        'beach' => Icons.beach_access_outlined,
        'park' => Icons.park_outlined,
        _ => Icons.place_outlined,
      };
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 3),
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      );
}

class ExternalPlaceDetailScreen extends StatefulWidget {
  const ExternalPlaceDetailScreen({
    super.key,
    required this.initialPlace,
    this.pendingAction,
  });

  final ExternalPlace initialPlace;
  final ExternalPlacePendingAction? pendingAction;

  @override
  State<ExternalPlaceDetailScreen> createState() =>
      _ExternalPlaceDetailScreenState();
}

class _ExternalPlaceDetailScreenState extends State<ExternalPlaceDetailScreen> {
  late Future<ExternalPlace> _details;
  bool _addingToTrip = false;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.pendingAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        switch (widget.pendingAction!) {
          case ExternalPlacePendingAction.save:
            _save(widget.initialPlace);
          case ExternalPlacePendingAction.addToTrip:
            _addToTrip(widget.initialPlace);
        }
      });
    }
  }

  void _load() {
    _details =
        context.read<PlaceProvider>().details(widget.initialPlace.placeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.initialPlace.name)),
      body: FutureBuilder<ExternalPlace>(
        future: _details,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final place = snapshot.data ?? widget.initialPlace;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x2,
              AppSpacing.x2,
              AppSpacing.x2,
              AppSpacing.x4,
            ),
            children: [
              if (snapshot.hasError) ...[
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: const Icon(Icons.cloud_off_outlined),
                    title: const Text('Live place details are unavailable'),
                    subtitle: const Text(
                      'Showing the latest search details. You can still save this place or open directions.',
                    ),
                    trailing: TextButton(
                      onPressed: () => setState(_load),
                      child: Text(context.tr('Try again')),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
              ],
              Icon(
                Icons.location_on,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                place.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                place.formattedAddress,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.x2),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (place.rating != null)
                    _Meta(
                      icon: Icons.star,
                      text:
                          '${place.rating!.toStringAsFixed(1)} ${context.tr('Google rating')}',
                    ),
                  if (place.openNow != null)
                    _Meta(
                      icon: Icons.schedule,
                      text: place.openNow! ? 'Open now' : 'Closed now',
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.x3),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _save(place),
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x1),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addingToTrip ? null : () => _addToTrip(place),
                      icon: _addingToTrip
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.route_outlined),
                      label: const Text('Add to Trip'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x1),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openMaps(place),
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Open directions in Maps'),
                ),
              ),
              if (place.phoneNumber != null || place.websiteUri != null) ...[
                const SizedBox(height: AppSpacing.x2),
                Card(
                  child: Column(
                    children: [
                      if (place.phoneNumber != null)
                        ListTile(
                          leading: const Icon(Icons.phone_outlined),
                          title: Text(place.phoneNumber!),
                          onTap: () => _openExternalUri(
                            Uri.parse('tel:${place.phoneNumber}'),
                            'No phone application could open this number.',
                          ),
                        ),
                      if (place.websiteUri != null)
                        ListTile(
                          leading: const Icon(Icons.language_outlined),
                          title: const Text('Visit website'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () => _openExternalUri(
                            Uri.parse(place.websiteUri!),
                            'The website could not be opened on this device.',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (place.weekdayDescriptions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.x2),
                Text('Opening hours',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.x1),
                ...place.weekdayDescriptions.map(
                  (line) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(line),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.x2),
              Text(
                'Place information is provided live by Google Places. LiveLocal reviews are shown only for LiveLocal community listings.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addToTrip(ExternalPlace place) async {
    final auth = context.read<AuthController>();
    if (!auth.canWrite) {
      _openProtectedAction(place, ExternalPlacePendingAction.addToTrip);
      return;
    }
    setState(() => _addingToTrip = true);
    final controller = context.read<ItineraryController>();
    final saved = await controller.saveExternalToDefaultCollection(
      provider: place.provider,
      placeId: place.placeId,
    );
    if (!mounted) return;
    setState(() => _addingToTrip = false);
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(controller.errorMessage ?? 'Place could not be added.')),
      );
      return;
    }
    Navigator.pushNamed(context, '/trips');
  }

  Future<void> _save(ExternalPlace place) async {
    if (!context.read<AuthController>().canWrite) {
      _openProtectedAction(place, ExternalPlacePendingAction.save);
      return;
    }
    await SaveToCollectionSheet.show(
      context,
      targetType: 'external',
      targetId: place.placeId,
      externalProvider: place.provider,
      placeName: place.name,
    );
  }

  void _openProtectedAction(
    ExternalPlace place,
    ExternalPlacePendingAction action,
  ) {
    context.read<ProtectedNavigation>().open(
          context,
          '/external-place-detail',
          arguments: ExternalPlaceDetailArguments(
            place: place,
            pendingAction: action,
          ),
        );
  }

  Future<void> _openMaps(ExternalPlace place) async {
    final uri = place.googleMapsUri == null
        ? Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': '${place.latitude},${place.longitude}',
            'query_place_id': place.placeId,
          })
        : Uri.parse(place.googleMapsUri!);
    await _openExternalUri(
      uri,
      'No Maps application could open this place.',
    );
  }

  Future<void> _openExternalUri(Uri uri, String failureMessage) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureMessage)),
      );
    }
  }
}

enum ExternalPlacePendingAction { save, addToTrip }

class ExternalPlaceDetailArguments {
  const ExternalPlaceDetailArguments({
    required this.place,
    this.pendingAction,
  });

  final ExternalPlace place;
  final ExternalPlacePendingAction? pendingAction;
}
