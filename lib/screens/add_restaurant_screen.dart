import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';
import '../controllers/localeats_controller.dart';
import '../core/routing/protected_navigation.dart';
import '../core/validation/social_url_validator.dart';
import '../features/restaurants/domain/local_eats_repository.dart';
import '../models/restaurant_model.dart';
import '../shared/presentation/contributions/contribution_header.dart';
import '../shared/presentation/contributions/contribution_image_picker.dart';
import '../shared/presentation/contributions/contribution_review_summary.dart';
import '../shared/presentation/contributions/contribution_scaffold.dart';
import '../shared/presentation/contributions/contribution_section.dart';
import '../shared/presentation/contributions/contribution_success_view.dart';

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key, this.source});

  final RestaurantModel? source;

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _dishes = TextEditingController();
  final _socialUrl = TextEditingController();

  String _state = 'Kuala Lumpur';
  String _cuisine = 'Malay';
  String _price = r'$';
  Uint8List? _imageBytes;
  String? _imageMimeType;
  bool _submitting = false;
  bool _imageRightsConfirmed = false;
  bool _submittedSuccess = false;

  static const _states = [
    'Johor',
    'Kedah',
    'Kuala Lumpur',
    'Melaka',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Sabah',
    'Sarawak',
    'Selangor',
  ];
  static const _cuisines = [
    'Malay',
    'Chinese',
    'Indian',
    'Japanese',
    'Korean',
    'Thai',
    'Italian',
    'Kopitiam',
    'Hawker Food',
    'Western',
    'Fusion',
    'Other',
  ];

  bool get _isRevision => widget.source != null;

  @override
  void initState() {
    super.initState();
    final source = widget.source;
    if (source == null) return;
    _name.text = source.name;
    _address.text = source.address;
    _city.text = source.city;
    _dishes.text = source.reviewedDishes;
    _socialUrl.text = source.socialMediaUrl;
    if (_states.contains(source.state)) _state = source.state;
    if (_cuisines.contains(source.cuisineType)) {
      _cuisine = source.cuisineType;
    }
    _price = source.priceRange;
    _imageRightsConfirmed = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _dishes.dispose();
    _socialUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final isCreator = user?.role == 'influencer';

    if (!auth.canWrite) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recommend a restaurant')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.x4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
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
                      'Sign in to recommend a restaurant',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Restaurant recommendations are submitted by approved LiveLocal Creators.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    FilledButton(
                      onPressed: () {
                        context.read<ProtectedNavigation>().open(
                              context,
                              '/recommend-restaurant',
                            );
                      },
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (!isCreator) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recommend a restaurant')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.x4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 44,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    Text(
                      'Creator tools required',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Restaurant recommendations on LiveLocal are submitted by approved Creators to ensure authentic, high-quality local dining tips.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      'Apply to become a Creator. Once approved by our team, Creator tools and restaurant submissions will be unlocked.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/creator-application');
                        },
                        child: const Text('Apply to become a Creator'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Maybe later'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_submittedSuccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Submission sent')),
        body: ContributionSuccessView(
          title: 'Thanks for the recommendation',
          message:
              'Your restaurant submission has been sent for moderation. Once approved by an administrator, it will appear in Local Eats.',
          primaryActionLabel: 'View my submissions',
          onPrimaryAction: () {
            Navigator.pushReplacementNamed(context, '/my-submissions');
          },
          secondaryActionLabel: 'Back to Local Eats',
          onSecondaryAction: () {
            Navigator.pop(context);
          },
        ),
      );
    }

    final controller = context.watch<LocalEatsController>();

    return ContributionScaffold(
      appBarTitle: _isRevision ? 'Revise restaurant' : 'Recommend a restaurant',
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
              icon: Icons.restaurant_outlined,
              title:
                  _isRevision ? 'Revise restaurant' : 'Recommend a restaurant',
              subtitle: _isRevision
                  ? 'Your current live listing remains active while updates are reviewed.'
                  : 'Share a local food spot you think travellers should know.',
            ),
            const SizedBox(height: AppSpacing.x2),

            // BASICS SECTION
            ContributionSection(
              title: 'Restaurant info',
              subtitle: 'Basic details and cuisine style',
              children: [
                _field(
                  _name,
                  'Restaurant name',
                  hintText: 'e.g. Line Clear Nasi Kandar',
                  minLength: 2,
                  maxLength: 120,
                ),
                const SizedBox(height: AppSpacing.x2),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown(
                        label: 'Cuisine type',
                        value: _cuisine,
                        values: _cuisines,
                        onChanged: (val) => setState(() => _cuisine = val),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(
                      child: _dropdown(
                        label: 'Price range',
                        value: _price,
                        values: const [r'$', r'$$', r'$$$', r'$$$$'],
                        onChanged: (val) => setState(() => _price = val),
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
              subtitle: 'Address and state in Malaysia',
              children: [
                _dropdown(
                  label: 'State',
                  value: _state,
                  values: _states,
                  onChanged: (val) => setState(() => _state = val),
                ),
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _city,
                  'City or district',
                  hintText: 'e.g. George Town, Petaling Jaya',
                  minLength: 2,
                  maxLength: 100,
                ),
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _address,
                  'Full address',
                  hintText: 'e.g. 161 & 163 Lebuh Campbell, 10100 George Town',
                  minLength: 5,
                  maxLength: 300,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),

            // WHAT TO TRY SECTION
            ContributionSection(
              title: 'Recommended dishes & social source',
              subtitle: 'Highlight your top recommendations and video link',
              children: [
                _field(
                  _dishes,
                  'Reviewed / recommended dishes',
                  hintText:
                      'e.g. Nasi Kandar with fried chicken and salted egg',
                  minLength: 3,
                  maxLength: 300,
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _socialUrl,
                  'TikTok or Instagram video link',
                  hintText: 'https://www.tiktok.com/@creator/video/123...',
                  minLength: 8,
                  maxLength: 500,
                  validator: (value) {
                    if (!SocialUrlValidator.isSupported(value ?? '')) {
                      return 'Enter a supported TikTok or Instagram HTTPS URL.';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),

            // COVER PHOTO SECTION
            ContributionSection(
              title: 'Cover photo',
              subtitle: 'Add an appetizing photo of the food or venue',
              children: [
                ContributionImagePicker(
                  imageBytes: _imageBytes,
                  existingImageUrl: widget.source?.coverPhotoUrl,
                  onImagePicked: (bytes) {
                    setState(() {
                      _imageBytes = bytes;
                      _imageMimeType = 'image/jpeg';
                      _imageRightsConfirmed = false;
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
                MapEntry('Restaurant', _name.text.trim()),
                MapEntry('Cuisine', _cuisine),
                MapEntry('Location', '${_city.text.trim()}, $_state'),
                MapEntry('Price', _price),
                MapEntry('Top dishes', _dishes.text.trim()),
              ],
              moderationNotice:
                  'All creator recommendations are verified by LiveLocal before publication.',
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
              : const Text('Submit restaurant for review'),
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
    String? Function(String?)? validator,
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
      validator: validator ??
          (value) {
            final length = value?.trim().length ?? 0;
            if (length < minLength) {
              return 'Enter at least $minLength characters.';
            }
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
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null &&
        widget.source?.coverPhotoUrl.isNotEmpty != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Choose a clear photo of the restaurant.')),
      );
      return;
    }
    if (!_imageRightsConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confirm that you have permission to share the photo.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final input = RestaurantDraftInput(
      name: _name.text.trim(),
      address: _address.text.trim(),
      state: _state,
      city: _city.text.trim(),
      cuisineType: _cuisine,
      priceRange: _price,
      reviewedDishes: _dishes.text.trim(),
      socialMediaUrl: _socialUrl.text.trim(),
    );

    final controller = context.read<LocalEatsController>();
    final result = _isRevision
        ? await controller.reviseRestaurant(
            source: widget.source!,
            input: input,
            imageBytes: _imageBytes,
            imageMimeType: _imageMimeType ?? 'image/jpeg',
          )
        : await controller.createRestaurantDraft(
            input: input,
            imageBytes: _imageBytes!,
            imageMimeType: _imageMimeType ?? 'image/jpeg',
          );

    if (!mounted) return;
    if (result == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'The submission could not be saved.',
          ),
        ),
      );
      return;
    }

    if (result.probableDuplicates.isNotEmpty) {
      final resolved = await _resolveDuplicates(result);
      if (!mounted) return;
      setState(() => _submitting = false);
      if (!resolved) return;
    }

    setState(() {
      _submitting = false;
      _submittedSuccess = true;
    });
  }

  Future<bool> _resolveDuplicates(RestaurantDraftResult draft) async {
    final reasonCtrl = TextEditingController();
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Possible existing listing'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We found similar public listings. Avoid creating a duplicate when one of these is the same business.',
              ),
              const SizedBox(height: 12),
              ...draft.probableDuplicates.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  subtitle:
                      Text('${item.address}\n${item.city}, ${item.state}'),
                  isThreeLine: true,
                ),
              ),
              TextField(
                controller: reasonCtrl,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Why this is a different listing',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'discard'),
            child: const Text('Discard my draft'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonCtrl.text.trim().length < 10) return;
              Navigator.pop(dialogContext, 'submit');
            },
            child: const Text('Submit with explanation'),
          ),
        ],
      ),
    );
    final overrideReason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (!mounted || action == null) return false;
    final messenger = ScaffoldMessenger.of(context);
    final controller = context.read<LocalEatsController>();
    final saved = await controller.resolveRestaurantDuplicate(
      draft,
      discard: action == 'discard',
      overrideReason: action == 'submit' ? overrideReason : null,
    );
    if (!mounted || !saved) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ??
                'The duplicate decision could not be saved.',
          ),
        ),
      );
      return false;
    }
    if (action == 'discard') {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Draft discarded. You can use the existing listing.'),
        ),
      );
      if (mounted) {
        Navigator.pop(context);
      }
      return false;
    }
    return true;
  }
}
