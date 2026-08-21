import 'package:flutter/material.dart';
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

class SubmitGuideScreen extends StatefulWidget {
  const SubmitGuideScreen({super.key});

  @override
  State<SubmitGuideScreen> createState() => _SubmitGuideScreenState();
}

class _SubmitGuideScreenState extends State<SubmitGuideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _state = TextEditingController(text: 'Penang');
  final _overview = TextEditingController();
  final _duration = TextEditingController(text: '1 day');
  final List<_StopDraft> _stops = [_StopDraft(), _StopDraft()];
  bool _submitting = false;
  bool _submittedSuccess = false;

  static const _states = [
    'Penang',
    'Kuala Lumpur',
    'Melaka',
    'Perak',
    'Johor',
    'Selangor',
    'Sabah',
    'Sarawak',
    'Kedah',
    'Pahang',
    'Negeri Sembilan',
  ];

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
    _state.dispose();
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
                  hintText: 'e.g. Penang Street Food in One Day',
                  minLength: 3,
                  maxLength: 160,
                ),
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _overview,
                  'Description & route summary',
                  hintText:
                      'Describe the route theme, ideal timing, and general highlights...',
                  minLength: 20,
                  maxLength: 3000,
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.x2),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _states.contains(_state.text)
                            ? _state.text
                            : _states.first,
                        decoration: const InputDecoration(labelText: 'State'),
                        items: _states
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _state.text = val);
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(
                      child: _field(
                        _duration,
                        'Estimated duration',
                        hintText: 'e.g. 1 day, Half day, 3D2N',
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
                  hintText: 'e.g. George Town, Jonker Street, Bukit Bintang',
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
                                  tooltip: 'Remove stop',
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 20),
                                  onPressed: () => _removeStop(index),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.x1),
                          TextFormField(
                            controller: stop.stopName,
                            decoration: const InputDecoration(
                              labelText: 'Stop name / place',
                              hintText: 'e.g. Toh Soon Cafe',
                            ),
                            validator: (val) {
                              if ((val?.trim().length ?? 0) < 2) {
                                return 'Enter stop name.';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.x1),
                          TextFormField(
                            controller: stop.walkingInstruction,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Tips & walking directions',
                              hintText:
                                  'e.g. Order charcoal toast and coffee, then walk 5 mins to Armenian St.',
                            ),
                            validator: (val) {
                              if ((val?.trim().length ?? 0) < 3) {
                                return 'Enter tips or directions for this stop.';
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
                MapEntry(
                    'Area', '${_location.text.trim()}, ${_state.text.trim()}'),
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
        labelText: label,
        hintText: hintText,
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (value) {
        final length = value?.trim().length ?? 0;
        if (length < minLength) return 'Enter at least $minLength characters.';
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
          content: Text('A guide must include at least 2 meaningful stops.'),
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
      state: _state.text.trim(),
      routeOverview: _overview.text.trim(),
      stops: _stops.map((s) => s.stopName.text.trim()).toList(),
      walkingSequence:
          _stops.map((s) => s.walkingInstruction.text.trim()).toList(),
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
  final TextEditingController stopName = TextEditingController();
  final TextEditingController walkingInstruction = TextEditingController();

  void dispose() {
    stopName.dispose();
    walkingInstruction.dispose();
  }
}
