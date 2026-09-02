import 'dart:typed_data';

import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';
import '../controllers/spot_controller.dart';
import '../core/routing/protected_navigation.dart';
import '../features/spots/domain/spot_repository.dart';
import '../features/places/domain/external_place.dart';
import '../features/places/domain/place_provider.dart';
import '../features/places/presentation/google_place_search_sheet.dart';
import '../models/spot_model.dart';
import '../shared/presentation/contributions/contribution_header.dart';
import '../shared/presentation/contributions/contribution_image_picker.dart';
import '../shared/presentation/contributions/contribution_review_summary.dart';
import '../shared/presentation/contributions/contribution_scaffold.dart';
import '../shared/presentation/contributions/contribution_section.dart';
import '../shared/presentation/contributions/contribution_success_view.dart';

import '../constants/malaysia_states.dart';
import '../features/spots/domain/spot_taxonomy.dart';

class SubmitSpotScreen extends StatefulWidget {
  const SubmitSpotScreen({super.key, this.source, this.initialPlace});

  final SpotModel? source;
  final ExternalPlace? initialPlace;

  @override
  State<SubmitSpotScreen> createState() => _SubmitSpotScreenState();
}

class _SubmitSpotScreenState extends State<SubmitSpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _bestTime = TextEditingController();
  final _thingsToDo = TextEditingController();

  String? _displayState;
  String? _category;
  late List<String> _states;
  late List<String> _categories;
  String _priceRange = r'$';
  Uint8List? _imageBytes;
  String? _imageMimeType;
  SpotDraftResult? _createdDraft;
  bool _submitting = false;
  bool _imageRightsConfirmed = false;
  bool _submittedSuccess = false;
  ExternalPlace? _selectedPlace;
  bool _placeConfirmed = false;
  late bool _useCustomPlace;

  bool get _isRevision => widget.source != null;
  bool get _allowsLegacyMissingPin =>
      _isRevision &&
      widget.source?.googlePlaceId == null &&
      widget.source?.latitude == null &&
      widget.source?.longitude == null;

  @override
  void initState() {
    super.initState();
    final source = widget.source;
    _displayState =
        source != null ? MalaysiaStates.toDisplay(source.state) : null;
    _states = MalaysiaStates.getDisplayList(
      existingRawOrDisplay: source?.state,
    );
    _category = source?.category;
    _categories = SpotTaxonomy.getCategoriesForRevision(source?.category);
    _useCustomPlace = source != null && source.googlePlaceId == null;

    if (source == null) {
      final initialPlace = widget.initialPlace;
      if (initialPlace != null) {
        _selectedPlace = initialPlace;
        _name.text = initialPlace.name;
        _address.text = initialPlace.formattedAddress;
        _latitude.text = initialPlace.latitude.toString();
        _longitude.text = initialPlace.longitude.toString();
      }
      return;
    }
    _name.text = source.name;
    _description.text = source.description;
    _city.text = source.city;
    _address.text = source.address;
    _latitude.text = source.latitude?.toString() ?? '';
    _longitude.text = source.longitude?.toString() ?? '';
    _bestTime.text = source.bestTime;
    _thingsToDo.text = source.thingsToDo;
    _priceRange = source.priceRange;
    _imageRightsConfirmed = true;
    if (source.googlePlaceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadLinkedPlace(source.googlePlaceId!);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _city.dispose();
    _address.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _bestTime.dispose();
    _thingsToDo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final spotController = context.watch<SpotController>();

    if (!auth.canWrite) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isRevision ? 'Revise place' : 'Share a local place'),
        ),
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
                  'Sign in to share a place',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  'Sign in with your verified account to contribute places to LiveLocal.',
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
                          '/submit-spot',
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
        appBar: AppBar(
          title: const Text('Submission sent'),
        ),
        body: ContributionSuccessView(
          title: 'Thanks for sharing this place',
          message:
              'Your submission is waiting for review. An administrator will verify the details before it appears in public discovery.',
          primaryActionLabel: 'View my submissions',
          onPrimaryAction: () {
            Navigator.pushReplacementNamed(context, '/my-submissions');
          },
          secondaryActionLabel: 'Back to Spots',
          onSecondaryAction: () {
            Navigator.pop(context);
          },
        ),
      );
    }

    return ContributionScaffold(
      appBarTitle: _isRevision ? 'Revise place' : 'Share a local place',
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
            ContributionHeader(
              icon: Icons.add_location_alt_outlined,
              title: _isRevision ? 'Revise this place' : 'Share a local place',
              subtitle: _isRevision
                  ? 'Your last approved version remains public while material changes are reviewed.'
                  : 'Help travellers discover a place worth visiting in Malaysia.',
            ),
            const SizedBox(height: AppSpacing.x2),

            ContributionSection(
              title: 'Find the real place',
              subtitle: _useCustomPlace
                  ? 'LiveLocal custom place'
                  : 'Google provides the location. You provide the local insight.',
              children: [
                if (_selectedPlace == null && !_useCustomPlace)
                  FilledButton.icon(
                    key: const Key('spot_choose_google_place'),
                    onPressed: _chooseGooglePlace,
                    icon: const Icon(Icons.search),
                    label: const Text('Find this place'),
                  )
                else if (_selectedPlace != null) ...[
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.x2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PLACE',
                              style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 4),
                          Text(
                            _selectedPlace!.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(_selectedPlace!.formattedAddress),
                          const SizedBox(height: AppSpacing.x1),
                          if (!_placeConfirmed)
                            FilledButton(
                              key: const Key('spot_confirm_google_place'),
                              onPressed: () =>
                                  setState(() => _placeConfirmed = true),
                              child: const Text('Confirm this place'),
                            )
                          else
                            const Row(
                              children: [
                                Icon(Icons.verified_outlined, size: 18),
                                SizedBox(width: 6),
                                Text('Place confirmed'),
                              ],
                            ),
                          TextButton(
                            onPressed: _chooseGooglePlace,
                            child: const Text('Choose another place'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (!_useCustomPlace)
                  TextButton(
                    key: const Key('spot_custom_place_fallback'),
                    onPressed: () => setState(() {
                      _useCustomPlace = true;
                      _selectedPlace = null;
                      _placeConfirmed = false;
                    }),
                    child: const Text(
                        "Can't find it on Google? Add a custom local place"),
                  )
                else
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Use this only for a genuine hidden place that is not on Google.',
                        ),
                      ),
                      TextButton(
                        onPressed: _chooseGooglePlace,
                        child: const Text('Search Google'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),

            // BASICS SECTION
            ContributionSection(
              title: 'Place basics',
              subtitle: 'Name and classification of this spot',
              children: [
                _field(
                  _name,
                  'Place name',
                  hintText: context.tr('e.g. Toh Soon Cafe, Hin Bus Depot'),
                  minLength: 2,
                  maxLength: 120,
                ),
                const SizedBox(height: AppSpacing.x2),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        label: 'Category',
                        value: _category,
                        hintText: context.tr('Select category'),
                        values: _categories,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return context.tr('Select category.');
                          }
                          return null;
                        },
                        onChanged: (val) => setState(() => _category = val),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(
                      child: _dropdown(
                        label: 'State',
                        value: _displayState,
                        hintText: context.tr('Select state'),
                        values: _states,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return context.tr('Select state.');
                          }
                          return null;
                        },
                        onChanged: (val) => setState(() => _displayState = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),

            // LOCATION SECTION
            ContributionSection(
              title: 'Location details',
              subtitle: 'Where visitors can find this place',
              children: [
                _field(
                  _city,
                  'City or district',
                  hintText: context.tr('e.g. George Town, Ipoh Old Town'),
                  minLength: 2,
                  maxLength: 100,
                ),
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _address,
                  'Full address',
                  hintText:
                      context.tr('e.g. 120 Campbell Street, 10100 George Town'),
                  minLength: 5,
                  maxLength: 300,
                ),
                if (_useCustomPlace) ...[
                  const SizedBox(height: AppSpacing.x2),
                  const Text(
                    'Pin coordinates are required so this hidden gem can be saved, routed, and opened in Maps.',
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  Row(
                    children: [
                      Expanded(
                        child: _coordinateField(
                          _latitude,
                          'Latitude',
                          minimum: -90,
                          maximum: 90,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x2),
                      Expanded(
                        child: _coordinateField(
                          _longitude,
                          'Longitude',
                          minimum: -180,
                          maximum: 180,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.x2),

            // ABOUT THIS PLACE SECTION
            ContributionSection(
              title: 'About this place',
              subtitle: 'Tell travellers what makes this spot special',
              children: [
                _field(
                  _description,
                  'Why is this place special?',
                  hintText: context.tr(
                    'Describe the atmosphere, specialty, heritage or local significance...',
                  ),
                  minLength: 20,
                  maxLength: 3000,
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _bestTime,
                  'Best time to visit',
                  hintText: context.tr(
                    'e.g. Morning for fresh toast, sunset for sea breeze',
                  ),
                  minLength: 2,
                  maxLength: 160,
                ),
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _thingsToDo,
                  'What to do or try',
                  hintText: context.tr(
                    'e.g. Order charcoal toast, stroll through the art market',
                  ),
                  minLength: 2,
                  maxLength: 500,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.x2),
                _dropdown(
                  label: 'Price range',
                  value: _priceRange,
                  values: const [r'$', r'$$', r'$$$', r'$$$$'],
                  onChanged: (val) => setState(() => _priceRange = val ?? r'$'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),

            // COVER PHOTO SECTION
            ContributionSection(
              title: 'Cover photo',
              subtitle: 'Add an appealing landscape photo',
              children: [
                ContributionImagePicker(
                  imageBytes: _imageBytes,
                  existingImageUrl: widget.source?.imageUrl,
                  onImagePicked: (bytes) {
                    setState(() {
                      _imageBytes = bytes;
                      _imageMimeType = 'image/jpeg';
                      _imageRightsConfirmed = false;
                      _createdDraft = null;
                    });
                  },
                  onImageCleared: () {
                    setState(() {
                      _imageBytes = null;
                      _imageMimeType = null;
                      _imageRightsConfirmed = false;
                    });
                  },
                  rightsConfirmed: _imageRightsConfirmed,
                  onRightsChanged: (val) =>
                      setState(() => _imageRightsConfirmed = val),
                  requireRightsConfirmation: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),

            // REVIEW SUMMARY SECTION
            ContributionReviewSummary(
              items: [
                MapEntry('Place name', _name.text.trim()),
                MapEntry('Category', _category ?? ''),
                MapEntry(
                    'Location', '${_city.text.trim()}, ${_displayState ?? ''}'),
                MapEntry('Price', _priceRange),
              ],
              moderationNotice:
                  'Submissions are reviewed by LiveLocal before appearing publicly.',
            ),
            if (spotController.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.x2),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  spotController.errorMessage!,
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
              : Text(
                  _createdDraft == null
                      ? 'Submit place for review'
                      : 'Resolve probable duplicate',
                ),
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

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      hint: hintText != null
          ? Text(hintText, overflow: TextOverflow.ellipsis)
          : null,
      decoration: InputDecoration(labelText: label),
      validator: validator,
      items: values
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _coordinateField(
    TextEditingController controller,
    String label, {
    required double minimum,
    required double maximum,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (_allowsLegacyMissingPin &&
            _latitude.text.trim().isEmpty &&
            _longitude.text.trim().isEmpty) {
          return null;
        }
        final coordinate = double.tryParse(value?.trim() ?? '');
        if (coordinate == null ||
            coordinate < minimum ||
            coordinate > maximum) {
          return 'Enter $minimum to $maximum.';
        }
        return null;
      },
    );
  }

  Future<void> _submit() async {
    if (_createdDraft != null) {
      await _resolveDuplicates(_createdDraft!);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (!_useCustomPlace && (_selectedPlace == null || !_placeConfirmed)) {
      _message('Choose and confirm the exact place before submitting.');
      return;
    }
    if (_imageBytes == null && widget.source?.imageUrl.isNotEmpty != true) {
      _message('Choose a clear photo of the place.');
      return;
    }
    if (!_imageRightsConfirmed) {
      _message('Confirm that you have permission to share the photo.');
      return;
    }
    setState(() => _submitting = true);
    final input = SpotDraftInput(
      name: _name.text.trim(),
      category: _category ?? '',
      description: _description.text.trim(),
      state: MalaysiaStates.toCanonical(_displayState ?? ''),
      city: _city.text.trim(),
      address: _address.text.trim(),
      priceRange: _priceRange,
      bestTime: _bestTime.text.trim(),
      thingsToDo: _thingsToDo.text.trim(),
      latitude:
          _selectedPlace?.latitude ?? double.tryParse(_latitude.text.trim()),
      longitude:
          _selectedPlace?.longitude ?? double.tryParse(_longitude.text.trim()),
      placeProvider: _selectedPlace?.provider,
      googlePlaceId: _selectedPlace?.placeId,
    );
    final controller = context.read<SpotController>();
    final result = _isRevision
        ? await controller.reviseAndSubmit(
            context,
            source: widget.source!,
            input: input,
            imageBytes: _imageBytes,
            imageMimeType: _imageMimeType,
            imageRightsConfirmed: _imageRightsConfirmed,
          )
        : await controller.submitDraft(
            context,
            input: input,
            imageBytes: _imageBytes,
            imageMimeType: _imageMimeType,
            imageRightsConfirmed: _imageRightsConfirmed,
          );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result == null) return;
    if (result.probableDuplicates.isNotEmpty) {
      setState(() => _createdDraft = result);
      await _resolveDuplicates(result);
      return;
    }
    setState(() => _submittedSuccess = true);
  }

  Future<void> _loadLinkedPlace(String placeId) async {
    try {
      final place = await context.read<PlaceProvider>().details(placeId);
      if (!mounted) return;
      setState(() {
        _selectedPlace = place;
        _placeConfirmed = true;
      });
    } catch (_) {
      // Keep the linked identity on the editable legacy fields if Google is
      // temporarily unavailable; the user can retry by choosing another place.
    }
  }

  Future<void> _chooseGooglePlace() async {
    final place = await GooglePlaceSearchSheet.show(
      context,
      title: 'Find a place for this insight',
      hintText: 'Search place name and city',
    );
    if (place == null || !mounted) return;
    setState(() {
      _selectedPlace = place;
      _placeConfirmed = false;
      _useCustomPlace = false;
      _name.text = place.name;
      _address.text = place.formattedAddress;
      _latitude.text = place.latitude.toString();
      _longitude.text = place.longitude.toString();
      final lowerAddress = place.formattedAddress.toLowerCase();
      for (final option in MalaysiaStates.options) {
        if (lowerAddress.contains(option.rawValue.toLowerCase()) ||
            lowerAddress.contains(option.displayName.toLowerCase())) {
          _displayState = option.displayName;
          break;
        }
      }
    });
  }

  Future<void> _resolveDuplicates(SpotDraftResult draft) async {
    final reasonController = TextEditingController();
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('This may already be listed'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Review these probable matches before creating another listing:',
              ),
              const SizedBox(height: 12),
              ...draft.probableDuplicates.map(
                (duplicate) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(duplicate.name),
                  subtitle: Text(
                    '${duplicate.address}\n${duplicate.city}, ${duplicate.state}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: context.tr('Why is this a different place?'),
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'existing'),
            child: const Text('Use existing listing'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().length < 10) return;
              Navigator.pop(dialogContext, 'override');
            },
            child: const Text('Submit as different'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (!mounted || action == null) return;
    if (action == 'existing') {
      setState(() => _submitting = true);
      final discarded =
          await context.read<SpotController>().discardDraft(draft);
      if (!mounted) return;
      setState(() => _submitting = false);
      if (!discarded) return;
      _message('Draft discarded. Open the existing listing from discovery.');
      Navigator.pop(context);
      return;
    }
    setState(() => _submitting = true);
    final submitted = await context.read<SpotController>().submitExistingDraft(
          context,
          draft.revisionId,
          reason,
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (submitted) setState(() => _submittedSuccess = true);
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
