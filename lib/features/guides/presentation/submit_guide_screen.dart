import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../controllers/auth_controller.dart';
import '../../../core/routing/protected_navigation.dart';
import '../../moderation/presentation/ugc_consent_dialog.dart';
import '../domain/guide_repository.dart';
import '../presentation/guide_controller.dart';
import '../../../shared/presentation/contributions/contribution_header.dart';
import '../../../shared/presentation/contributions/contribution_review_summary.dart';
import '../../../shared/presentation/contributions/contribution_scaffold.dart';
import '../../../shared/presentation/contributions/contribution_section.dart';
import '../../../shared/presentation/contributions/contribution_success_view.dart';

import '../../../constants/malaysia_states.dart';
import '../../../models/guide_model.dart';
import '../../restaurants/presentation/local_eats_controller.dart';
import '../../spots/presentation/spot_controller.dart';

class SubmitGuideScreen extends StatefulWidget {
  const SubmitGuideScreen({super.key});

  @override
  State<SubmitGuideScreen> createState() => _SubmitGuideScreenState();
}

class _SubmitGuideScreenState extends State<SubmitGuideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  String? _displayState;
  final _overview = TextEditingController();
  final _duration = TextEditingController(text: '1 day');
  final List<_StopDraft> _stops = [_StopDraft(), _StopDraft()];
  bool _submitting = false;
  bool _submittedSuccess = false;

  final List<String> _states = MalaysiaStates.getDisplayList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GuideController>().loadMySubmissions();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _overview.dispose();
    _duration.dispose();
    for (final stop in _stops) {
      stop.dispose();
    }
    super.dispose();
  }

  void _addStop() {
    setState(() {
      _stops.add(_StopDraft());
    });
  }

  void _removeStop(int index) {
    if (_stops.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('A travel guide requires at least 2 stops.')),
      );
      return;
    }
    setState(() {
      final removed = _stops.removeAt(index);
      removed.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<GuideController>();
    final listingChoices = <_ListingChoice>[
      ...context
          .watch<SpotController>()
          .spots
          .map((spot) => _ListingChoice('spot', spot.id, spot.name)),
      ...context.watch<LocalEatsController>().restaurants.map(
            (restaurant) => _ListingChoice(
              'restaurant',
              restaurant.id,
              restaurant.name,
            ),
          ),
    ];

    if (!auth.canWrite) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create a travel guide')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Sign in to create a guide',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  'Share your travel itineraries and local routes with the LiveLocal community.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.x3),
                FilledButton(
                  onPressed: () {
                    context.read<ProtectedNavigation>().open(
                          context,
                          '/submit-guide',
                        );
                  },
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_submittedSuccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Guide submitted')),
        body: ContributionSuccessView(
          title: 'Guide submitted for review',
          message:
              'Community travel guides are reviewed by LiveLocal before becoming public. Once approved, your itinerary will be visible to all travellers.',
          primaryActionLabel: 'View my submissions',
          onPrimaryAction: () {
            Navigator.pushReplacementNamed(context, '/my-submissions');
          },
          secondaryActionLabel: 'Back to Guides',
          onSecondaryAction: () {
            Navigator.pop(context);
          },
        ),
      );
    }

    return ContributionScaffold(
      appBarTitle: 'Create a travel guide',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x2,
            AppSpacing.x2,
            AppSpacing.x2,
            AppSpacing.x4,
          ),
          children: [
            const ContributionHeader(
              icon: Icons.map_outlined,
              title: 'Create a travel guide',
              subtitle:
                  'Share a route, itinerary or local plan that helped you explore an area in Malaysia.',
            ),
            const SizedBox(height: AppSpacing.x2),

            // BASICS SECTION
            ContributionSection(
              title: 'Guide overview',
              subtitle: 'Title, destination, and trip duration',
              children: [
                _field(
                  _title,
                  'Guide title',
                  hintText: context.tr('e.g. Penang Street Food in One Day'),
                  minLength: 3,
                  maxLength: 160,
                ),
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _overview,
                  'Description & route summary',
                  hintText: context.tr(
                    'Describe the route theme, ideal timing, and general highlights...',
                  ),
                  minLength: 20,
                  maxLength: 3000,
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.x2),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _displayState,
                        hint: const Text(
                          'Select state',
                          overflow: TextOverflow.ellipsis,
                        ),
                        decoration:
                            InputDecoration(labelText: context.tr('State')),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return context.tr('Select state.');
                          }
                          return null;
                        },
                        items: _states
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child:
                                      Text(s, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() => _displayState = val);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(
                      child: _field(
                        _duration,
                        'Estimated duration',
                        hintText: context.tr('e.g. 1 day, Half day, 3D2N'),
                        minLength: 2,
                        maxLength: 80,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _location,
                  'Neighbourhood or area',
                  hintText: context
                      .tr('e.g. George Town, Jonker Street, Bukit Bintang'),
                  minLength: 2,
                  maxLength: 120,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),

            // ORDERED STOPS SECTION
            ContributionSection(
              title: 'Ordered stops (Min. 2 stops)',
              subtitle: 'Add the sequence of places to visit along the route',
              children: [
                ...List.generate(_stops.length, (index) {
                  final stop = _stops[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.x2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Stop ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_stops.length > 2)
                                IconButton(
                                  tooltip: context.tr('Remove stop'),
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 20),
                                  onPressed: () => _removeStop(index),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.x1),
                          SegmentedButton<GuideStopKind>(
                            segments: const [
                              ButtonSegment(
                                value: GuideStopKind.listing,
                                icon: Icon(Icons.verified_outlined),
                                label: Text('LiveLocal listing'),
                              ),
                              ButtonSegment(
                                value: GuideStopKind.custom,
                                icon: Icon(Icons.add_location_alt_outlined),
                                label: Text('Custom stop'),
                              ),
                            ],
                            selected: {stop.kind},
                            onSelectionChanged: (selection) => setState(() {
                              stop.kind = selection.first;
                              stop.listingKey = null;
                              stop.stopName.clear();
                            }),
                          ),
                          const SizedBox(height: AppSpacing.x1),
                          if (stop.kind == GuideStopKind.listing)
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: stop.listingKey,
                              decoration: InputDecoration(
                                labelText:
                                    context.tr('Approved Spot or Restaurant'),
                                helperText: context.tr(
                                  'Verified LiveLocal listings are labelled separately from custom stops.',
                                ),
                              ),
                              items: listingChoices
                                  .map((choice) => DropdownMenuItem(
                                        value: choice.key,
                                        child: Text(
                                          '${choice.type == 'spot' ? 'Spot' : 'Restaurant'} · ${choice.name}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              validator: (value) => value == null
                                  ? context.tr('Choose an approved listing.')
                                  : null,
                              onChanged: (value) {
                                final matches = listingChoices
                                    .where((item) => item.key == value);
                                final choice =
                                    matches.isEmpty ? null : matches.first;
                                setState(() {
                                  stop.listingKey = value;
                                  stop.stopName.text = choice?.name ?? '';
                                });
                              },
                            )
                          else
                            TextFormField(
                              controller: stop.stopName,
                              decoration: InputDecoration(
                                labelText: context.tr('Custom stop name'),
                                hintText: context.tr(
                                  'e.g. MRT exit, meeting point, or landmark',
                                ),
                                helperText: context.tr(
                                  'Custom stops are context only and are not approved LiveLocal listings.',
                                ),
                              ),
                              validator: (val) {
                                if ((val?.trim().length ?? 0) < 2) {
                                  return context.tr('Enter stop name.');
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          const SizedBox(height: AppSpacing.x1),
                          TextFormField(
                            controller: stop.walkingInstruction,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText:
                                  context.tr('Tips & walking directions'),
                              hintText: context.tr(
                                'e.g. Order charcoal toast and coffee, then walk 5 mins to Armenian St.',
                              ),
                            ),
                            validator: (val) {
                              if ((val?.trim().length ?? 0) < 3) {
                                return context.tr(
                                  'Enter tips or directions for this stop.',
                                );
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: _addStop,
                  icon: const Icon(Icons.add),
                  label: const Text('Add another stop'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),

            // REVIEW SUMMARY SECTION
            ContributionReviewSummary(
              items: [
                MapEntry('Guide title', _title.text.trim()),
                MapEntry('Area', '${_location.text.trim()}, $_displayState'),
                MapEntry('Duration', _duration.text.trim()),
                MapEntry('Total stops', '${_stops.length} stops'),
              ],
              moderationNotice:
                  'Community guides are reviewed by LiveLocal moderators before becoming public.',
            ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.x2),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  controller.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomAction: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit guide for review'),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hintText,
    required int minLength,
    required int maxLength,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: context.tr(label),
        hintText: hintText,
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (value) {
        final length = value?.trim().length ?? 0;
        if (length < minLength) {
          return context.tr('Enter at least $minLength characters.');
        }
        return null;
      },
      onChanged: (_) => setState(() {}),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_stops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A travel guide requires at least 2 stops.'),
        ),
      );
      return;
    }

    final accepted = await showUgcConsentDialog(context);
    if (!accepted || !mounted) return;

    setState(() => _submitting = true);

    final input = GuideDraftInput(
      title: _title.text.trim(),
      locationName: _location.text.trim(),
      state: MalaysiaStates.toCanonical(_displayState ?? ''),
      routeOverview: _overview.text.trim(),
      stops: _stops.map((s) => s.stopName.text.trim()).toList(),
      walkingSequence:
          _stops.map((s) => s.walkingInstruction.text.trim()).toList(),
      stopDetails: _stops.map((stop) {
        final listingParts = stop.listingKey?.split(':');
        return GuideStopModel(
          kind: stop.kind,
          name: stop.stopName.text.trim(),
          instruction: stop.walkingInstruction.text.trim(),
          listingType: listingParts?.first,
          listingId: listingParts != null && listingParts.length == 2
              ? listingParts.last
              : null,
        );
      }).toList(),
      estimatedDuration: _duration.text.trim(),
    );

    final controller = context.read<GuideController>();
    final saved = await controller.submitGuide(input);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (saved) {
      setState(() => _submittedSuccess = true);
    }
  }
}

class _StopDraft {
  GuideStopKind kind = GuideStopKind.listing;
  String? listingKey;
  final TextEditingController stopName = TextEditingController();
  final TextEditingController walkingInstruction = TextEditingController();

  void dispose() {
    stopName.dispose();
    walkingInstruction.dispose();
  }
}

class _ListingChoice {
  const _ListingChoice(this.type, this.id, this.name);

  final String type;
  final String id;
  final String name;
  String get key => '$type:$id';
}
