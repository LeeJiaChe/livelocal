import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';
import '../controllers/spot_controller.dart';
import '../core/routing/protected_navigation.dart';
import '../features/spots/domain/spot_repository.dart';
import '../models/spot_model.dart';
import '../shared/presentation/contributions/contribution_header.dart';
import '../shared/presentation/contributions/contribution_image_picker.dart';
import '../shared/presentation/contributions/contribution_review_summary.dart';
import '../shared/presentation/contributions/contribution_scaffold.dart';
import '../shared/presentation/contributions/contribution_section.dart';
import '../shared/presentation/contributions/contribution_success_view.dart';

class SubmitSpotScreen extends StatefulWidget {
  const SubmitSpotScreen({super.key, this.source});

  final SpotModel? source;

  @override
  State<SubmitSpotScreen> createState() => _SubmitSpotScreenState();
}

class _SubmitSpotScreenState extends State<SubmitSpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _bestTime = TextEditingController();
  final _thingsToDo = TextEditingController();

  String _state = 'Penang';
  String _category = 'Kopitiam';
  String _priceRange = r'$';
  Uint8List? _imageBytes;
  String? _imageMimeType;
  SpotDraftResult? _createdDraft;
  bool _submitting = false;
  bool _imageRightsConfirmed = false;
  bool _submittedSuccess = false;

  static const _states = [
    'Penang',
    'Kuala Lumpur',
    'Perak',
    'Johor',
    'Selangor',
    'Melaka',
    'Sabah',
    'Sarawak',
  ];
  static const _categories = [
    'Kopitiam',
    'Pasar Malam',
    'Indie Cafe',
    'Park / Walkway',
    'Hawker Food',
    'Heritage Spot',
  ];

  bool get _isRevision => widget.source != null;

  @override
  void initState() {
    super.initState();
    final source = widget.source;
    if (source == null) return;
    _name.text = source.name;
    _description.text = source.description;
    _city.text = source.city;
    _address.text = source.address;
    _bestTime.text = source.bestTime;
    _thingsToDo.text = source.thingsToDo;
    if (_states.contains(source.state)) _state = source.state;
    if (_categories.contains(source.category)) _category = source.category;
    _priceRange = source.priceRange;
    _imageRightsConfirmed = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _city.dispose();
    _address.dispose();
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

            // BASICS SECTION
            ContributionSection(
              title: 'Place basics',
              subtitle: 'Name and classification of this spot',
              children: [
                _field(
                  _name,
                  'Place name',
                  hintText: 'e.g. Toh Soon Cafe, Hin Bus Depot',
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
                        values: _categories,
                        onChanged: (val) => setState(() => _category = val),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(
                      child: _dropdown(
                        label: 'State',
                        value: _state,
                        values: _states,
                        onChanged: (val) => setState(() => _state = val),
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
                  hintText: 'e.g. George Town, Ipoh Old Town',
                  minLength: 2,
                  maxLength: 100,
                ),
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _address,
                  'Full address',
                  hintText: 'e.g. 120 Campbell Street, 10100 George Town',
                  minLength: 5,
                  maxLength: 300,
                ),
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
                  hintText:
                      'Describe the atmosphere, specialty, heritage or local significance...',
                  minLength: 20,
                  maxLength: 3000,
                  maxLines: 4,
                ),
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _bestTime,
                  'Best time to visit',
                  hintText:
                      'e.g. Morning for fresh toast, sunset for sea breeze',
                  minLength: 2,
                  maxLength: 160,
                ),
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _thingsToDo,
                  'What to do or try',
                  hintText:
                      'e.g. Order charcoal toast, stroll through the art market',
                  minLength: 2,
                  maxLength: 500,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.x2),
                _dropdown(
                  label: 'Price range',
                  value: _priceRange,
                  values: const [r'$', r'$$', r'$$$', r'$$$$'],
                  onChanged: (val) => setState(() => _priceRange = val),
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
                MapEntry('Category', _category),
                MapEntry('Location', '${_city.text.trim()}, $_state'),
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

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }

  Future<void> _submit() async {
    if (_createdDraft != null) {
      await _resolveDuplicates(_createdDraft!);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
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
      category: _category,
      description: _description.text.trim(),
      state: _state,
      city: _city.text.trim(),
      address: _address.text.trim(),
      priceRange: _priceRange,
      bestTime: _bestTime.text.trim(),
      thingsToDo: _thingsToDo.text.trim(),
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
                decoration: const InputDecoration(
                  labelText: 'Why is this a different place?',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
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
