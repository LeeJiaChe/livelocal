import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/itinerary_controller.dart';
import '../controllers/localeats_controller.dart';
import '../controllers/spot_controller.dart';
import '../features/itinerary/domain/saved_itinerary_repository.dart';
import '../widgets/timeline_step_card.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ItineraryController>();
    final steps = controller.itinerarySteps;
    
    Map<String, List<Map<String, Object>>> groupedByDay = {};
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
        groupedByDay[currentDay]?.add(step);
      }
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F5F0),
        title: const Text('Itineraries'),
        actions: [
          if (steps.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              onPressed: () => _showMapView(context, groupedByDay),
              tooltip: 'View on map',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: [
          Text(
            'Plan a route from your saved places',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a starting point or request your device location. Route order is an estimate based on straight-line proximity, not travel time.',
          ),
          const SizedBox(height: 20),
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
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(controller.errorMessage!),
              ),
            ),
          ],
          if (groupedByDay.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'Suggested day itinerary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...groupedByDay.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(entry.value.length, (index) {
                    final step = entry.value[index];
                    final globalIndex = groupedByDay.values
                        .takeWhile((e) => e != entry.value)
                        .fold(0, (sum, e) => sum + e.length) + index;
                    return TimelineStepCard(
                      step: step,
                      index: globalIndex,
                      isLast: globalIndex == steps.length - 1,
                    );
                  }),
                ],
              );
            }),
          ],
          const SizedBox(height: 28),
          Text(
            'Saved itineraries',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (controller.savedItineraries.isEmpty)
            const Card(
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No saved itinerary yet. Creating a route saves its order to your account.',
                ),
              ),
            )
          else
            ...controller.savedItineraries.map(
              (itinerary) => Card(
                margin: const EdgeInsets.only(bottom: 8),
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
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Itinerary on Map',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: groupedByDay.keys.length,
                  itemBuilder: (context, index) {
                    final dayName = groupedByDay.keys.elementAt(index);
                    final daySteps = groupedByDay[dayName]!;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(dayName),
                        subtitle: Text('${daySteps.length} stops'),
                        children: daySteps.asMap().entries.map((entry) {
                          final stepIndex = entry.key;
                          final step = entry.value;
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 14,
                              child: Text('${stepIndex + 1}'),
                            ),
                            title: Text(step['title'] as String),
                            subtitle: Text(step['location'] as String),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseOriginAndCreate() async {
    final title = TextEditingController(text: 'My local day');
    var mode = 'manual';
    var city = _manualOrigins.first;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create itinerary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: title,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Plan title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'manual',
                    icon: Icon(Icons.location_city_outlined),
                    label: Text('Choose area'),
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
              const SizedBox(height: 16),
              if (mode == 'manual')
                DropdownButtonFormField<_ManualOrigin>(
                  initialValue: city,
                  decoration: const InputDecoration(
                    labelText: 'Starting area',
                    border: OutlineInputBorder(),
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
                  'LiveLocal will ask for foreground location only after you continue. Denying permission will not block discovery; you can return and choose an area.',
                ),
              const SizedBox(height: 8),
              const Text(
                'If you save the itinerary, its starting coordinates are stored privately with your account so the saved route keeps its origin.',
              ),
              const SizedBox(height: 20),
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
      );
    }
    final saved = await controller.generateAndSaveItinerary(
      title: planTitle,
      origin: origin,
      allSpots: context.read<SpotController>().spots,
      allRestaurants: context.read<LocalEatsController>().restaurants,
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
    required this.area,
    required this.latitude,
    required this.longitude,
  });

  final String area;
  final double latitude;
  final double longitude;

  String get label => area;
}

const _manualOrigins = [
  _ManualOrigin(
    area: 'Kuala Lumpur',
    latitude: 3.1390,
    longitude: 101.6869,
  ),
  _ManualOrigin(
    area: 'George Town, Penang',
    latitude: 5.4141,
    longitude: 100.3288,
  ),
  _ManualOrigin(
    area: 'Ipoh, Perak',
    latitude: 4.5975,
    longitude: 101.0901,
  ),
  _ManualOrigin(
    area: 'Johor Bahru, Johor',
    latitude: 1.4927,
    longitude: 103.7414,
  ),
  _ManualOrigin(
    area: 'Melaka City, Melaka',
    latitude: 2.1896,
    longitude: 102.2501,
  ),
  _ManualOrigin(
    area: 'Kota Kinabalu, Sabah',
    latitude: 5.9804,
    longitude: 116.0735,
  ),
  _ManualOrigin(
    area: 'Kuching, Sarawak',
    latitude: 1.5533,
    longitude: 110.3592,
  ),
];
