import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/theme/app_spacing.dart';
import '../controllers/itinerary_controller.dart';
import '../features/itinerary/domain/saved_itinerary_repository.dart';
import '../features/itinerary/domain/google_maps_route.dart';
import '../widgets/timeline_step_card.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key, this.initialCollectionId});

  final String? initialCollectionId;

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ItineraryController>().loadItineraries();
      context.read<ItineraryController>().loadCollections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ItineraryController>();
    final steps = controller.itinerarySteps;

    final groupedByDay = <String, List<Map<String, Object>>>{};
    if (steps.isNotEmpty) {
      String currentDay = 'Day 1';
      int dayCounter = 1;
      groupedByDay[currentDay] = [];

      for (int i = 0; i < steps.length; i++) {
        final step = steps[i];
        if (i > 0 && i % 5 == 0) {
          dayCounter++;
          currentDay = 'Day $dayCounter';
          groupedByDay[currentDay] = [];
        }
        groupedByDay[currentDay]!.add(step);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itineraries'),
        actions: [
          if (steps.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              onPressed: () => _showMapView(context, groupedByDay, steps),
              tooltip: context.tr('View on map'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x2,
          AppSpacing.x1,
          AppSpacing.x2,
          112,
        ),
        children: [
          Text(
            'Plan a route from your saved places',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.x1),
          Text(
            'Choose a manual starting city or request your device location. Proximity order is computed to help you organize a smooth day out.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.x2),
          FilledButton.icon(
            onPressed: controller.isGeneratingItinerary
                ? null
                : _chooseOriginAndCreate,
            icon: const Icon(Icons.route_outlined),
            label: Text(
              controller.isGeneratingItinerary
                  ? 'Creating itinerary…'
                  : 'Create itinerary',
            ),
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.x2),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              elevation: 0,
              child: ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                title: Text(
                  controller.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          ],
          if (groupedByDay.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x3),
            Text(
              'Suggested day itinerary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.x1),
            ...groupedByDay.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      key: ValueKey('open_google_route_${entry.key}'),
                      onPressed: () => _openRoute(entry.value),
                      icon: const Icon(Icons.navigation_outlined),
                      label: const Text('Open route in Google Maps'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  ...List.generate(entry.value.length, (index) {
                    final step = entry.value[index];
                    final globalIndex = steps.indexOf(step);
                    return TimelineStepCard(
                      step: step,
                      index: globalIndex >= 0 ? globalIndex : index,
                      isLast: (globalIndex >= 0 ? globalIndex : index) ==
                          steps.length - 1,
                    );
                  }),
                ],
              );
            }),
          ],
          const SizedBox(height: AppSpacing.x3),
          Text(
            'Saved itineraries',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.x1),
          if (controller.savedItineraries.isEmpty)
            const Card(
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.x3),
                child: Text(
                  'No saved itineraries yet. Creating a route saves its order to your account.',
                ),
              ),
            )
          else
            ...controller.savedItineraries.map(
              (itinerary) => Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.x1),
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(itinerary.title),
                  subtitle: Text(
                    '${itinerary.originLabel} · ${itinerary.targets.length} stops',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMapView(
    BuildContext context,
    Map<String, List<Map<String, Object>>> groupedByDay,
    List<Map<String, Object>> steps,
  ) {
    final validPoints = <LatLng>[];
    final markers = <Marker>[];

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final lat = step['lat'];
      final lng = step['lng'];
      if (lat is double && lng is double) {
        final point = LatLng(lat, lng);
        validPoints.add(point);
        markers.add(
          Marker(
            point: point,
            width: 36,
            height: 36,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }
    }

    final initialCenter = validPoints.isNotEmpty
        ? validPoints.first
        : const LatLng(3.1390, 101.6869);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Itinerary on Map',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.x2),
              if (validPoints.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 260,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: initialCenter,
                        initialZoom: 12,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.livelocal.app',
                        ),
                        MarkerLayer(markers: markers),
                      ],
                    ),
                  ),
                )
              else
                const Card(
                  elevation: 0,
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.x2),
                    child: Text(
                      'No verified coordinates available for this route.',
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.x2),
              const Text(
                'Numbered markers show stop order only. Google Maps provides the real road route and navigation.',
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                'Day breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.x1),
              ...groupedByDay.entries.map((entry) {
                final dayName = entry.key;
                final daySteps = entry.value;
                final dayIndex = groupedByDay.keys.toList().indexOf(dayName);
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.x1),
                  elevation: 0,
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: CircleAvatar(
                      child: Text('${dayIndex + 1}'),
                    ),
                    title: Text(dayName),
                    subtitle: Text(
                      '${daySteps.length} stops',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    children: daySteps.map<Widget>((step) {
                      final title = step['title'] as String;
                      final type = step['type'] as String;
                      final location = step['location'] as String;
                      final activity = step['activity'] as String;
                      final bestTime = step['best_time'] as String;
                      final isMeal = type.startsWith('Restaurant');
                      return ListTile(
                        leading: Icon(
                          isMeal
                              ? Icons.restaurant
                              : Icons.location_on_outlined,
                          color: isMeal
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (activity.isNotEmpty)
                              Text(
                                activity,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                          ],
                        ),
                        trailing: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 100),
                          child: Text(
                            bestTime,
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      );
                    }).toList()
                      ..insert(
                        0,
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.x2,
                            0,
                            AppSpacing.x2,
                            AppSpacing.x1,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: () => _openRoute(daySteps),
                              icon: const Icon(Icons.navigation_outlined),
                              label: const Text('Open route in Google Maps'),
                            ),
                          ),
                        ),
                      ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRoute(List<Map<String, Object>> steps) async {
    final stops = steps.map((step) {
      return GoogleMapsRouteStop(
        name: step['title'] as String,
        latitude: step['lat'] as double,
        longitude: step['lng'] as double,
        googlePlaceId:
            (step['provider'] == 'google') ? step['place_id'] as String? : null,
      );
    }).toList(growable: false);
    final uri = GoogleMapsRouteHandoff.build(stops);
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Maps could not be opened.')),
      );
    }
  }

  Future<void> _chooseOriginAndCreate() async {
    final itineraryCtrl = context.read<ItineraryController>();
    final collections = itineraryCtrl.collections;

    final title = TextEditingController(
      text: 'Day trip plan (${DateTime.now().month}/${DateTime.now().day})',
    );
    String mode = 'manual';
    _ManualOrigin city = _manualOrigins.first;
    String? selectedColId = widget.initialCollectionId;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.x2,
            0,
            AppSpacing.x2,
            MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.x3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create itinerary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.x2),
              TextField(
                controller: title,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: context.tr('Plan title'),
                ),
              ),
              if (collections.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.x1),
                DropdownButtonFormField<String?>(
                  initialValue: selectedColId,
                  decoration: InputDecoration(
                    labelText: context.tr('Source collection'),
                    prefixIcon: const Icon(Icons.bookmark_outline),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All saved places'),
                    ),
                    ...collections.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text('${c.name} (${c.itemCount})'),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => selectedColId = value),
                ),
              ],
              const SizedBox(height: AppSpacing.x2),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'manual',
                    icon: Icon(Icons.location_city_outlined),
                    label: Text('Choose city'),
                  ),
                  ButtonSegment(
                    value: 'device',
                    icon: Icon(Icons.my_location_outlined),
                    label: Text('Device location'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (values) =>
                    setSheetState(() => mode = values.single),
              ),
              const SizedBox(height: AppSpacing.x2),
              if (mode == 'manual')
                DropdownButtonFormField<_ManualOrigin>(
                  initialValue: city,
                  decoration: InputDecoration(
                    labelText: context.tr('Starting city'),
                  ),
                  items: _manualOrigins
                      .map(
                        (origin) => DropdownMenuItem(
                          value: origin,
                          child: Text(origin.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setSheetState(() => city = value ?? city),
                )
              else
                const Text(
                  'LiveLocal will ask for foreground location only after you continue. Denying permission will not block discovery; you can return and choose a city.',
                ),
              const SizedBox(height: AppSpacing.x2),
              FilledButton(
                onPressed: () {
                  if (title.text.trim().length < 2) return;
                  Navigator.pop(sheetContext, true);
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );

    final planTitle = title.text.trim();
    title.dispose();
    if (confirmed != true || !mounted) return;

    RouteOrigin? origin;
    final controller = context.read<ItineraryController>();
    if (mode == 'device') {
      origin = await controller.requestDeviceOrigin();
      if (!mounted || origin == null) return;
    } else {
      origin = RouteOrigin(
        label: city.label,
        latitude: city.latitude,
        longitude: city.longitude,
        mode: 'manual',
        state: city.state,
        city: city.city,
      );
    }

    final saved = await controller.generateAndSaveItinerary(
      title: planTitle,
      origin: origin,
      collectionId: selectedColId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Itinerary saved.'
              : controller.errorMessage ?? 'The itinerary could not be saved.',
        ),
      ),
    );
  }
}

class _ManualOrigin {
  const _ManualOrigin({
    required this.city,
    required this.state,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final String state;
  final double latitude;
  final double longitude;

  String get label => '$city, $state';
}

const _manualOrigins = [
  _ManualOrigin(
    city: 'Kuala Lumpur',
    state: 'Kuala Lumpur',
    latitude: 3.1390,
    longitude: 101.6869,
  ),
  _ManualOrigin(
    city: 'George Town',
    state: 'Penang',
    latitude: 5.4141,
    longitude: 100.3288,
  ),
  _ManualOrigin(
    city: 'Ipoh',
    state: 'Perak',
    latitude: 4.5975,
    longitude: 101.0901,
  ),
  _ManualOrigin(
    city: 'Johor Bahru',
    state: 'Johor',
    latitude: 1.4927,
    longitude: 103.7414,
  ),
  _ManualOrigin(
    city: 'Melaka City',
    state: 'Melaka',
    latitude: 2.1896,
    longitude: 102.2501,
  ),
  _ManualOrigin(
    city: 'Kota Kinabalu',
    state: 'Sabah',
    latitude: 5.9804,
    longitude: 116.0735,
  ),
  _ManualOrigin(
    city: 'Kuching',
    state: 'Sarawak',
    latitude: 1.5533,
    longitude: 110.3592,
  ),
];
