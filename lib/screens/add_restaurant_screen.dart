import 'dart:typed_data';

import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_spacing.dart';
import '../constants/malaysia_states.dart';
import '../controllers/auth_controller.dart';
import '../controllers/localeats_controller.dart';
import '../core/routing/protected_navigation.dart';
import '../core/validation/restaurant_source_url_validator.dart';
import '../core/validation/social_url_validator.dart';
import '../features/restaurants/domain/generated_restaurant_listing.dart';
import '../features/restaurants/domain/local_eats_repository.dart';
import '../features/restaurants/domain/restaurant_taxonomy.dart';
import '../features/places/domain/external_place.dart';
import '../features/places/domain/place_provider.dart';
import '../features/places/presentation/google_place_search_sheet.dart';
import '../models/restaurant_model.dart';
import '../shared/presentation/contributions/contribution_header.dart';
import '../shared/presentation/contributions/contribution_image_picker.dart';
import '../shared/presentation/contributions/contribution_review_summary.dart';
import '../shared/presentation/contributions/contribution_scaffold.dart';
import '../shared/presentation/contributions/contribution_section.dart';
import '../shared/presentation/contributions/contribution_success_view.dart';

class AddRestaurantScreen extends StatefulWidget {
  const AddRestaurantScreen({super.key, this.source, this.initialPlace});

  final RestaurantModel? source;
  final ExternalPlace? initialPlace;

  @override
  State<AddRestaurantScreen> createState() => _AddRestaurantScreenState();
}

class _AddRestaurantScreenState extends State<AddRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sourceUrl = TextEditingController();
  final _restaurantLookup = TextEditingController();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _dishes = TextEditingController();
  final _socialUrl = TextEditingController();
  final _cuisine = TextEditingController();

  String? _displayState;
  late List<String> _states;
  final _cuisineFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _scrollController = ScrollController();
  String _price = r'$';
  Uint8List? _imageBytes;
  String? _imageMimeType;
  bool _submitting = false;
  bool _imageRightsConfirmed = false;
  bool _submittedSuccess = false;
  bool _aiAssisted = false;
  String? _aiSourcePlatform;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LocalEatsController>().clearGeneratedResult();
    });
    final source = widget.source;
    _aiAssisted = source?.aiAssisted ?? false;
    _aiSourcePlatform = source?.aiSourcePlatform;
    _useCustomPlace = source != null && source.googlePlaceId == null;
    _displayState =
        source != null ? MalaysiaStates.toDisplay(source.state) : null;
    _states = MalaysiaStates.getDisplayList(
      existingRawOrDisplay: source?.state,
    );
    _cuisine.text = source?.cuisineType ?? '';

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
    _address.text = source.address;
    _city.text = source.city;
    _latitude.text = source.latitude?.toString() ?? '';
    _longitude.text = source.longitude?.toString() ?? '';
    _dishes.text = source.reviewedDishes;
    _socialUrl.text = source.socialMediaUrl;
    _price = source.priceRange;
    _imageRightsConfirmed = true;
    if (source.googlePlaceId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadLinkedPlace(source.googlePlaceId!);
      });
    }
  }

  @override
  void dispose() {
    _sourceUrl.dispose();
    _restaurantLookup.dispose();
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _latitude.dispose();
    _longitude.dispose();
    _dishes.dispose();
    _socialUrl.dispose();
    _cuisine.dispose();
    _cuisineFocusNode.dispose();
    _nameFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isCreator = auth.currentUser?.role == 'influencer';

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
                      'Restaurant recommendations are published exclusively by approved Local Food Creators to maintain authentic, quality food guides.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
          controller: _scrollController,
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

            // AI IMPORT SECTION (for new recommendations)
            if (!_isRevision) ...[
              ContributionSection(
                title: 'Import from a link (Optional)',
                subtitle:
                    'Auto-fill from Google Maps, a public website, Instagram or TikTok',
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.x2),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'AI uses the public source to suggest details. You\'ll review everything before submitting.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        TextFormField(
                          key: const Key('ai_source_field'),
                          controller: _sourceUrl,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: context.tr('Restaurant or review link'),
                            hintText: 'https://maps.app.goo.gl/...',
                            helperText: context.tr(
                              'Paste a public Google Maps, website, TikTok, or Instagram link',
                            ),
                            prefixIcon: const Icon(Icons.link),
                            suffixIcon: _sourceUrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _sourceUrl.clear();
                                      _restaurantLookup.clear();
                                      controller.clearGeneratedResult();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        FilledButton.tonalIcon(
                          key: const Key('ai_generate_button'),
                          onPressed: controller.isGeneratingListing
                              ? null
                              : _generateListing,
                          icon: controller.isGeneratingListing
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.auto_awesome_outlined),
                          label: Text(
                            controller.isGeneratingListing
                                ? 'Reading source and preparing draft…'
                                : 'Generate details with AI',
                          ),
                        ),
                        if (controller.generationError != null) ...[
                          const SizedBox(height: AppSpacing.x2),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.x2),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                                    const SizedBox(width: AppSpacing.x1),
                                    Expanded(
                                      child: Text(
                                        controller.generationError!,
                                        key: const Key('ai_generation_error'),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onErrorContainer,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.x1),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      key:
                                          const Key('continue_manually_button'),
                                      onPressed: _scrollToManualEntry,
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 16),
                                      label: const Text('Continue manually'),
                                    ),
                                    const SizedBox(width: AppSpacing.x1),
                                    FilledButton.tonalIcon(
                                      key: const Key('try_again_ai_button'),
                                      onPressed: controller.isGeneratingListing
                                          ? null
                                          : _generateListing,
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Try again'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_shouldOfferRestaurantLookup(controller)) ...[
                          const SizedBox(height: AppSpacing.x2),
                          Container(
                            key: const Key('social_restaurant_lookup'),
                            padding: const EdgeInsets.all(AppSpacing.x2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer
                                  .withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'We couldn\'t identify the restaurant from this social link. Enter the restaurant name below and we\'ll look it up.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: AppSpacing.x1),
                                TextField(
                                  key: const Key(
                                    'social_restaurant_name_field',
                                  ),
                                  controller: _restaurantLookup,
                                  textCapitalization: TextCapitalization.words,
                                  maxLength: 120,
                                  decoration: InputDecoration(
                                    labelText: context.tr('Restaurant name'),
                                    hintText: context.tr(
                                      'e.g. Line Clear Nasi Kandar',
                                    ),
                                    counterText: '',
                                  ),
                                  onSubmitted: (_) =>
                                      _identifyRestaurantFromSocial(),
                                ),
                                const SizedBox(height: AppSpacing.x1),
                                FilledButton.tonalIcon(
                                  key: const Key(
                                    'identify_social_restaurant_button',
                                  ),
                                  onPressed: controller.isGeneratingListing
                                      ? null
                                      : _identifyRestaurantFromSocial,
                                  icon: const Icon(Icons.search),
                                  label: const Text(
                                    'Find restaurant and fill draft',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (controller.generatedCandidates.length > 1) ...[
                          const SizedBox(height: AppSpacing.x2),
                          Text(
                            'Choose a restaurant review:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.x1),
                          ...controller.generatedCandidates.map(
                            (candidate) => _candidateCard(
                              context,
                              candidate,
                              controller.selectedGeneratedCandidate ==
                                  candidate,
                            ),
                          ),
                        ],
                        if (controller.selectedGeneratedCandidate != null) ...[
                          const SizedBox(height: AppSpacing.x2),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.x2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: AppSpacing.x1),
                                    Expanded(
                                      child: Text(
                                        'AI-assisted draft generated. Review and edit all fields below.',
                                        key: const Key('ai_draft_notice'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (controller.selectedGeneratedCandidate!
                                    .missingFields.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Missing in post (please provide): ${controller.selectedGeneratedCandidate!.missingFields.map(_fieldLabel).join(', ')}.',
                                    key: const Key('ai_missing_fields'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x2),
            ],

            ContributionSection(
              title: 'Place',
              subtitle: _useCustomPlace
                  ? 'LiveLocal custom food place'
                  : 'Confirm the real-world restaurant before adding your insight.',
              children: [
                if (_selectedPlace == null && !_useCustomPlace)
                  FilledButton.icon(
                    key: const Key('restaurant_choose_google_place'),
                    onPressed: _chooseGooglePlace,
                    icon: const Icon(Icons.search),
                    label: const Text('Find the restaurant'),
                  )
                else if (_selectedPlace != null)
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
                              key: const Key('restaurant_confirm_google_place'),
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
                if (!_useCustomPlace)
                  TextButton(
                    key: const Key('restaurant_custom_place_fallback'),
                    onPressed: () => setState(() {
                      _useCustomPlace = true;
                      _selectedPlace = null;
                      _placeConfirmed = false;
                    }),
                    child: const Text(
                      "Can't find it on Google? Add an uncommon custom food place",
                    ),
                  )
                else
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Use this only for a genuine stall or business not listed on Google.',
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
              title: 'Restaurant info',
              subtitle: 'Basic details and cuisine style',
              children: [
                _field(
                  _name,
                  'Restaurant name',
                  hintText: context.tr('e.g. Line Clear Nasi Kandar'),
                  minLength: 2,
                  maxLength: 120,
                  focusNode: _nameFocusNode,
                  key: const Key('restaurant_name_field'),
                ),
                const SizedBox(height: AppSpacing.x2),
                RawAutocomplete<String>(
                  textEditingController: _cuisine,
                  focusNode: _cuisineFocusNode,
                  optionsBuilder: (textEditingValue) {
                    return RestaurantTaxonomy.filterSuggestions(
                      textEditingValue.text,
                    );
                  },
                  onSelected: (selection) {
                    _cuisine.text = selection;
                    _cuisine.selection = TextSelection.fromPosition(
                      TextPosition(offset: selection.length),
                    );
                    setState(() {});
                  },
                  fieldViewBuilder: (
                    context,
                    textEditingController,
                    focusNode,
                    onFieldSubmitted,
                  ) {
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: context.tr('Cuisine type'),
                        hintText: context.tr(
                          'e.g. Hainanese, Peranakan / Nyonya, Kopitiam',
                        ),
                      ),
                      validator: (value) {
                        if ((value?.trim().length ?? 0) < 2) {
                          return context.tr(
                            'Enter a cuisine type (at least 2 characters).',
                          );
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    );
                  },
                  optionsViewBuilder: (
                    context,
                    onSelected,
                    options,
                  ) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.surface,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 200,
                            maxWidth: 320,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                  child: Text(option),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.x1),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'Hainanese',
                      'Peranakan / Nyonya',
                      'Chinese / Kopitiam',
                      'Malay / Traditional',
                      'Nasi Kandar / Indian Muslim',
                      'Bakery / Traditional',
                    ].map((suggestion) {
                      final isSelected = _cuisine.text.trim() == suggestion;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _cuisine.text = suggestion;
                              _cuisine.selection = TextSelection.fromPosition(
                                TextPosition(offset: suggestion.length),
                              );
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                _dropdown(
                  label: 'Price range',
                  value: _price,
                  values: const [r'$', r'$$', r'$$$', r'$$$$'],
                  onChanged: (val) => setState(() => _price = val ?? r'$'),
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
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _city,
                  'City or district',
                  hintText: context.tr('e.g. George Town, Petaling Jaya'),
                  minLength: 2,
                  maxLength: 100,
                  key: const Key('restaurant_city_field'),
                ),
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _address,
                  'Full address',
                  hintText: context
                      .tr('e.g. 161 & 163 Lebuh Campbell, 10100 George Town'),
                  minLength: 5,
                  maxLength: 300,
                  key: const Key('restaurant_address_field'),
                ),
                if (_useCustomPlace) ...[
                  const SizedBox(height: AppSpacing.x2),
                  const Text(
                    'Pin coordinates are required so this uncommon food place can be saved, routed, and opened in Maps.',
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

            // WHAT TO TRY SECTION
            ContributionSection(
              title: 'Recommended dishes & source',
              subtitle:
                  'Highlight your recommendations and keep the original public link',
              children: [
                _field(
                  _dishes,
                  'Reviewed / recommended dishes',
                  hintText: context.tr(
                    'e.g. Nasi Kandar with fried chicken and salted egg',
                  ),
                  minLength: 3,
                  maxLength: 300,
                  maxLines: 2,
                  key: const Key('restaurant_dishes_field'),
                ),
                const SizedBox(height: AppSpacing.x2),
                _field(
                  _socialUrl,
                  'Source / reference link',
                  hintText: context.tr('https://maps.app.goo.gl/...'),
                  minLength: 8,
                  maxLength: 500,
                  key: const Key('social_review_url_field'),
                  validator: (value) {
                    if (!RestaurantSourceUrlValidator.isSupported(
                      value ?? '',
                    )) {
                      return context.tr(
                        'Enter a public Google Maps, website, TikTok, or Instagram HTTPS URL.',
                      );
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
                MapEntry('Cuisine', _cuisine.text.trim()),
                MapEntry(
                    'Location', '${_city.text.trim()}, ${_displayState ?? ''}'),
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
          key: const Key('restaurant_submit_button'),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isRevision
                  ? 'Save changes'
                  : 'Submit restaurant for review'),
        ),
      ),
    );
  }

  Future<void> _generateListing() async {
    final source = _sourceUrl.text.trim();
    final controller = context.read<LocalEatsController>();
    if (SocialUrlValidator.detectSourceType(source) ==
        SocialSourceType.profile) {
      controller.clearGeneratedResult();
      _message(
        'Paste a TikTok review video or Instagram post/Reel link, not a profile link.',
      );
      return;
    }
    if (!RestaurantSourceUrlValidator.isSupported(source)) {
      controller.clearGeneratedResult();
      _message(
        'Paste a public Google Maps, website, Instagram post/Reel, or TikTok video link.',
      );
      return;
    }
    final generated =
        await controller.generateRestaurantListingFromSource(source);
    if (!mounted || !generated) return;
    final candidate = controller.selectedGeneratedCandidate;
    if (candidate != null) await _promptAndApplyCandidate(candidate);
  }

  bool _shouldOfferRestaurantLookup(LocalEatsController controller) {
    final detection = RestaurantSourceUrlValidator.detect(
      _sourceUrl.text.trim(),
    );
    if (detection.type != RestaurantSourceType.socialPost) return false;
    final candidate = controller.selectedGeneratedCandidate;
    return controller.generationError != null ||
        (candidate != null && candidate.restaurantName == null);
  }

  Future<void> _identifyRestaurantFromSocial() async {
    final source = _sourceUrl.text.trim();
    final name = _restaurantLookup.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (name.length < 2) {
      _message('Enter the restaurant name to look it up.');
      return;
    }
    if (RestaurantSourceUrlValidator.detect(source).type !=
        RestaurantSourceType.socialPost) {
      _message('Paste a public Instagram post/Reel or TikTok video link.');
      return;
    }
    final controller = context.read<LocalEatsController>();
    final generated = await controller.generateRestaurantListingFromSource(
      source,
      restaurantName: name,
    );
    if (!mounted || !generated) return;
    final candidate = controller.selectedGeneratedCandidate;
    if (candidate != null) await _promptAndApplyCandidate(candidate);
  }

  Widget _candidateCard(
    BuildContext context,
    GeneratedRestaurantListing candidate,
    bool selected,
  ) {
    return Card(
      key: ValueKey('generated-candidate-${candidate.sourcePostUrl}'),
      color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: InkWell(
        onTap: () => _promptAndApplyCandidate(candidate),
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
                '${RestaurantSourceUrlValidator.platformLabel(candidate.sourcePostUrl)} · ${(candidate.confidence * 100).round()}% confidence',
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

  bool get _hasMeaningfulFormEntries =>
      _name.text.trim().isNotEmpty ||
      _address.text.trim().isNotEmpty ||
      _city.text.trim().isNotEmpty ||
      _cuisine.text.trim().isNotEmpty ||
      _dishes.text.trim().isNotEmpty;

  Future<void> _promptAndApplyCandidate(
    GeneratedRestaurantListing candidate,
  ) async {
    if (!RestaurantSourceUrlValidator.isSupported(candidate.sourcePostUrl)) {
      _message(
          'The generated candidate did not contain a valid public source.');
      return;
    }
    if (_hasMeaningfulFormEntries) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Replace current details with this AI draft?'),
          content: const Text(
            'Applying this AI draft will replace the restaurant details you entered.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Apply draft'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    if (!mounted) return;
    _applyCandidate(candidate);
  }

  void _applyCandidate(GeneratedRestaurantListing candidate) {
    if (!RestaurantSourceUrlValidator.isSupported(candidate.sourcePostUrl)) {
      _message(
          'The generated candidate did not contain a valid public source.');
      return;
    }
    context.read<LocalEatsController>().selectGeneratedCandidate(candidate);
    setState(() {
      _aiAssisted = true;
      _aiSourcePlatform = candidate.sourcePlatform;
      if (candidate.restaurantName != null) {
        _name.text = candidate.restaurantName!;
      }
      if (candidate.address != null) _address.text = candidate.address!;
      if (candidate.city != null) _city.text = candidate.city!;
      if (candidate.reviewedDishes != null) {
        _dishes.text = candidate.reviewedDishes!;
      }
      _socialUrl.text = candidate.sourcePostUrl;
      if (candidate.cuisineType?.isNotEmpty == true) {
        _cuisine.text = candidate.cuisineType!;
      }
      if (candidate.state != null && candidate.state!.trim().isNotEmpty) {
        final display = MalaysiaStates.toDisplay(candidate.state!);
        if (display.isNotEmpty) {
          _displayState = display;
          if (!_states.contains(display)) {
            _states =
                MalaysiaStates.getDisplayList(existingRawOrDisplay: display);
          }
        }
      }
      _price =
          const [r'$', r'$$', r'$$$', r'$$$$'].contains(candidate.priceRange)
              ? candidate.priceRange!
              : _price;
      if (candidate.placeProvider == 'google' &&
          candidate.googlePlaceId != null &&
          candidate.latitude != null &&
          candidate.longitude != null) {
        _selectedPlace = ExternalPlace(
          provider: 'google',
          placeId: candidate.googlePlaceId!,
          name: candidate.restaurantName ?? _name.text,
          formattedAddress: candidate.address ?? _address.text,
          latitude: candidate.latitude!,
          longitude: candidate.longitude!,
        );
        _placeConfirmed = false;
        _useCustomPlace = false;
      }
    });
  }

  void _scrollToManualEntry() {
    _nameFocusNode.requestFocus();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        350,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hintText,
    int minLength = 0,
    int maxLength = 100,
    int maxLines = 1,
    FocusNode? focusNode,
    String? Function(String?)? validator,
    Key? key,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: context.tr(label),
        hintText: hintText,
      ),
      validator: validator ??
          (value) {
            if (minLength > 0 && (value?.trim().length ?? 0) < minLength) {
              return context.tr(
                'Enter $label (at least $minLength characters).',
              );
            }
            if (maxLength > 0 && (value?.trim().length ?? 0) > maxLength) {
              return context.tr(
                '$label cannot exceed $maxLength characters.',
              );
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
    final safeValue = values.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      hint: hintText != null
          ? Text(
              hintText,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((v) => DropdownMenuItem(
                value: v,
                child: Text(
                  v,
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      validator: validator,
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
    if (!_formKey.currentState!.validate()) return;
    if (!_useCustomPlace && (_selectedPlace == null || !_placeConfirmed)) {
      _message('Choose and confirm the exact restaurant before submitting.');
      return;
    }
    final sourceCover = widget.source?.coverPhotoUrl;
    final hasExistingCover =
        sourceCover != null && sourceCover.trim().isNotEmpty;
    if (_imageBytes == null && !hasExistingCover) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a cover photo.')),
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
      state: MalaysiaStates.toCanonical(_displayState ?? ''),
      city: _city.text.trim(),
      cuisineType: _cuisine.text.trim(),
      priceRange: _price,
      reviewedDishes: _dishes.text.trim(),
      socialMediaUrl: _socialUrl.text.trim(),
      aiAssisted: _aiAssisted,
      aiSourcePlatform: _aiSourcePlatform,
      latitude:
          _selectedPlace?.latitude ?? double.tryParse(_latitude.text.trim()),
      longitude:
          _selectedPlace?.longitude ?? double.tryParse(_longitude.text.trim()),
      placeProvider: _selectedPlace?.provider,
      googlePlaceId: _selectedPlace?.placeId,
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

  Future<void> _loadLinkedPlace(String placeId) async {
    try {
      final place = await context.read<PlaceProvider>().details(placeId);
      if (!mounted) return;
      setState(() {
        _selectedPlace = place;
        _placeConfirmed = true;
      });
    } catch (_) {
      // The existing revision remains intact. Choosing the place again retries
      // provider resolution without silently changing identity.
    }
  }

  Future<void> _chooseGooglePlace() async {
    final place = await GooglePlaceSearchSheet.show(
      context,
      title: 'Find the restaurant',
      hintText: 'Search restaurant name and city',
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
                decoration: InputDecoration(
                  labelText: context.tr('Why this is a different listing'),
                  border: const OutlineInputBorder(),
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
