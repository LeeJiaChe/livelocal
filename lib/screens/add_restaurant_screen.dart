import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/auth_controller.dart';
import '../controllers/localeats_controller.dart';
import '../core/validation/social_url_validator.dart';
import '../features/restaurants/domain/generated_restaurant_listing.dart';
import '../features/restaurants/domain/local_eats_repository.dart';
import '../models/restaurant_model.dart';

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key, this.source});

  final RestaurantModel? source;

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sourceUrl = TextEditingController();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _dishes = TextEditingController();
  final _socialUrl = TextEditingController();
  String? _state = 'Kuala Lumpur';
  String? _cuisine = 'Malay';
  String? _price = r'$';
  Uint8List? _imageBytes;
  String? _imageMimeType;
  bool _submitting = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LocalEatsController>().clearGeneratedResult();
    });
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
  }

  @override
  void dispose() {
    _sourceUrl.dispose();
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _dishes.dispose();
    _socialUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthController>().currentUser?.role;
    if (role != 'influencer') {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'An approved creator account is required to submit a restaurant.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final localEats = context.watch<LocalEatsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isRevision ? 'Revise your restaurant' : 'Submit a restaurant',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            Text(
              _isRevision ? 'Restaurant revision' : 'Restaurant submission',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _isRevision
                  ? 'Your approved listing stays public while these material changes are reviewed. Prior decisions remain in history.'
                  : 'Add public business details and the TikTok or Instagram post that supports your recommendation. The listing is reviewed before publication.',
            ),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Import from social media',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Generate an editable restaurant draft from one review post or your recent creator posts.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('ai_source_field'),
                      controller: _sourceUrl,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'TikTok or Instagram source',
                        helperText:
                            'Paste a TikTok/Instagram review post or your creator profile.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: const Key('ai_generate_button'),
                      onPressed: localEats.isGeneratingListing
                          ? null
                          : _generateListing,
                      icon: localEats.isGeneratingListing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_outlined),
                      label: Text(
                        localEats.isGeneratingListing
                            ? 'Analysing social source…'
                            : 'Generate Listing with AI',
                      ),
                    ),
                    if (localEats.generationError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        localEats.generationError!,
                        key: const Key('ai_generation_error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      if (SocialUrlValidator.detectSourceType(
                            _sourceUrl.text,
                          ) ==
                          SocialSourceType.profile) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: localEats.isConnectingSocialAccount
                              ? null
                              : _connectSocialAccount,
                          icon: const Icon(Icons.link),
                          label: Text(
                            localEats.isConnectingSocialAccount
                                ? 'Opening connection…'
                                : 'Connect creator account',
                          ),
                        ),
                      ],
                    ],
                    if (localEats.socialConnectionError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        localEats.socialConnectionError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (localEats.generatedCandidates.length > 1) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Choose a restaurant review',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...localEats.generatedCandidates.map(
                        (candidate) => _candidateCard(
                          context,
                          candidate,
                          localEats.selectedGeneratedCandidate == candidate,
                        ),
                      ),
                    ],
                    if (localEats.selectedGeneratedCandidate != null) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'AI-generated draft — please verify the details before submitting.',
                        key: Key('ai_draft_notice'),
                      ),
                      if (localEats
                          .selectedGeneratedCandidate!.missingFields.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Still required: ${localEats.selectedGeneratedCandidate!.missingFields.map(_fieldLabel).join(', ')}.',
                            key: const Key('ai_missing_fields'),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('restaurant_name_field'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Restaurant name',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey('cuisine-$_cuisine'),
              initialValue: _cuisine,
              decoration: const InputDecoration(
                labelText: 'Cuisine',
                border: OutlineInputBorder(),
              ),
              items: _cuisines
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _cuisine = value ?? _cuisine),
              validator: _required,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey('state-$_state'),
              initialValue: _state,
              decoration: const InputDecoration(
                labelText: 'State or territory',
                border: OutlineInputBorder(),
              ),
              items: _states
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _state = value ?? _state),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('restaurant_city_field'),
              controller: _city,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'City or area',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('restaurant_address_field'),
              controller: _address,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Public address',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey('price-$_price'),
              initialValue: _price,
              decoration: const InputDecoration(
                labelText: 'Typical price range',
                border: OutlineInputBorder(),
              ),
              items: const [r'$', r'$$', r'$$$', r'$$$$']
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => _price = value ?? _price),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('restaurant_dishes_field'),
              controller: _dishes,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Recommended dishes',
                hintText: 'What should visitors try?',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('social_review_url_field'),
              controller: _socialUrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'TikTok or Instagram post URL',
                helperText:
                    'HTTPS links from tiktok.com or instagram.com only.',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (!SocialUrlValidator.isReviewPost(value ?? '')) {
                  return 'Enter a TikTok video or Instagram post/reel URL, not a profile URL.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _submitting ? null : _pickImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _imageBytes == null
                    ? _isRevision
                        ? 'Keep or replace cover photo'
                        : 'Choose cover photo'
                    : 'Change cover photo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _imageBytes == null
                  ? _isRevision
                      ? 'The current photo will be kept unless replaced.'
                      : 'JPEG, PNG or WebP · maximum 8 MB'
                  : 'Photo selected · ${(_imageBytes!.length / 1024).ceil()} KB',
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('restaurant_submit_button'),
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Submitting…' : 'Submit for review'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required.'
        : null;
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageMimeType = image.mimeType ?? _mimeFromName(image.name);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isRevision && (_imageBytes == null || _imageMimeType == null)) {
      _message('Choose a cover photo.');
      return;
    }
    setState(() => _submitting = true);
    final controller = context.read<LocalEatsController>();
    final input = RestaurantDraftInput(
      name: _name.text.trim(),
      address: _address.text.trim(),
      state: _state!,
      city: _city.text.trim(),
      cuisineType: _cuisine!,
      priceRange: _price!,
      reviewedDishes: _dishes.text.trim(),
      socialMediaUrl: _socialUrl.text.trim(),
    );
    final result = _isRevision
        ? await controller.reviseRestaurant(
            source: widget.source!,
            input: input,
            imageBytes: _imageBytes,
            imageMimeType: _imageMimeType,
          )
        : await controller.createRestaurantDraft(
            input: input,
            imageBytes: _imageBytes!,
            imageMimeType: _imageMimeType!,
          );
    if (!mounted) return;
    if (result == null) {
      setState(() => _submitting = false);
      _message(controller.errorMessage ?? 'The submission could not be saved.');
      return;
    }
    if (result.probableDuplicates.isNotEmpty) {
      final resolved = await _resolveDuplicates(result);
      if (!mounted) return;
      setState(() => _submitting = false);
      if (!resolved) return;
    }
    _message(
      _isRevision
          ? 'Restaurant revision submitted for review.'
          : 'Restaurant submitted for review.',
    );
    Navigator.pop(context);
  }

  Future<void> _generateListing() async {
    final source = _sourceUrl.text.trim();
    final controller = context.read<LocalEatsController>();
    if (SocialUrlValidator.detectSourceType(source) ==
        SocialSourceType.unsupported) {
      controller.clearGeneratedResult();
      _message(
        'Paste a valid TikTok or Instagram post or creator profile URL.',
      );
      return;
    }
    final generated =
        await controller.generateRestaurantListingFromSource(source);
    if (!mounted || !generated) return;
    final candidate = controller.selectedGeneratedCandidate;
    if (candidate != null) _applyCandidate(candidate);
  }

  Future<void> _connectSocialAccount() async {
    final platform = SocialUrlValidator.detectPlatform(_sourceUrl.text);
    if (platform == null) return;
    final controller = context.read<LocalEatsController>();
    final authorizationUrl =
        await controller.startSocialAccountConnection(platform);
    if (!mounted || authorizationUrl == null) return;
    final opened = await launchUrl(
      authorizationUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;
    if (!opened) {
      _message('Could not open the $platform connection page.');
      return;
    }
    _message(
      'Complete the $platform connection, then return and tap Generate Listing with AI again.',
    );
  }

  Widget _candidateCard(
    BuildContext context,
    GeneratedRestaurantListing candidate,
    bool selected,
  ) {
    return Card(
      key: ValueKey('generated-candidate-${candidate.sourcePostUrl}'),
      color: selected
          ? Theme.of(context).colorScheme.secondaryContainer
          : null,
      child: InkWell(
        onTap: () => _applyCandidate(candidate),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                candidate.restaurantName ?? 'Restaurant name not identified',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(candidate.reviewedDishes ?? 'Dishes not identified'),
              const SizedBox(height: 4),
              Text(
                '${SocialUrlValidator.platformLabel(candidate.sourcePostUrl)} · ${(candidate.confidence * 100).round()}% confidence',
              ),
              const SizedBox(height: 4),
              Text(
                candidate.sourcePostUrl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyCandidate(GeneratedRestaurantListing candidate) {
    if (!SocialUrlValidator.isReviewPost(candidate.sourcePostUrl)) {
      _message('The generated candidate did not contain a valid review post.');
      return;
    }
    context.read<LocalEatsController>().selectGeneratedCandidate(candidate);
    setState(() {
      _name.text = candidate.restaurantName ?? '';
      _address.text = candidate.address ?? '';
      _city.text = candidate.city ?? '';
      _dishes.text = candidate.reviewedDishes ?? '';
      _socialUrl.text = candidate.sourcePostUrl;
      _state = _matchingValue(_states, candidate.state);
      _cuisine = _matchingValue(_cuisines, candidate.cuisineType) ??
          (candidate.cuisineType == null ? null : 'Other');
      _price = const [r'$', r'$$', r'$$$', r'$$$$']
              .contains(candidate.priceRange)
          ? candidate.priceRange
          : null;
    });
  }

  String? _matchingValue(List<String> values, String? candidate) {
    if (candidate == null) return null;
    final normalized = candidate.trim().toLowerCase();
    for (final value in values) {
      if (value.toLowerCase() == normalized) return value;
    }
    return null;
  }

  static String _fieldLabel(String value) {
    const labels = {
      'restaurantName': 'restaurant name',
      'address': 'address',
      'state': 'state',
      'city': 'city',
      'cuisineType': 'cuisine',
      'priceRange': 'price range',
      'reviewedDishes': 'reviewed dishes',
    };
    return labels[value] ?? value;
  }

  Future<bool> _resolveDuplicates(RestaurantDraftResult draft) async {
    final reason = TextEditingController();
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
                controller: reason,
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
              if (reason.text.trim().length < 10) return;
              Navigator.pop(dialogContext, 'submit');
            },
            child: const Text('Submit with explanation'),
          ),
        ],
      ),
    );
    final overrideReason = reason.text.trim();
    reason.dispose();
    if (!mounted || action == null) return false;
    final controller = context.read<LocalEatsController>();
    final saved = await controller.resolveRestaurantDuplicate(
      draft,
      discard: action == 'discard',
      overrideReason: action == 'submit' ? overrideReason : null,
    );
    if (!mounted || !saved) {
      _message(controller.errorMessage ??
          'The duplicate decision could not be saved.');
      return false;
    }
    if (action == 'discard') {
      _message('Draft discarded. You can use the existing listing.');
      Navigator.pop(context);
      return false;
    }
    return true;
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}
