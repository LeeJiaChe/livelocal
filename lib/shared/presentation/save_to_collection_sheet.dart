import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_spacing.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/itinerary_controller.dart';
import '../../core/routing/protected_navigation.dart';
import '../../models/restaurant_model.dart';
import '../../models/spot_model.dart';
import '../../screens/restaurant_detail_screen.dart';
import '../../screens/spot_detail_screen.dart';

class SaveToCollectionSheet extends StatefulWidget {
  const SaveToCollectionSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.placeName,
    this.spot,
    this.restaurant,
  });

  final String targetType;
  final String targetId;
  final String placeName;
  final SpotModel? spot;
  final RestaurantModel? restaurant;

  static Future<void> show(
    BuildContext context, {
    required String targetType,
    required String targetId,
    required String placeName,
    SpotModel? spot,
    RestaurantModel? restaurant,
  }) async {
    final auth = context.read<AuthController>();
    if (!auth.canWrite) {
      if (targetType == 'spot' && spot != null) {
        context.read<ProtectedNavigation>().open(
              context,
              '/spot-detail',
              arguments: SpotDetailArguments(
                spot: spot,
                pendingAction: const SpotPendingAction.save(),
              ),
            );
      } else if (targetType == 'restaurant' && restaurant != null) {
        context.read<ProtectedNavigation>().open(
              context,
              '/restaurant-detail',
              arguments: RestaurantDetailArguments(
                restaurant: restaurant,
                pendingAction: const RestaurantPendingAction.save(),
              ),
            );
      } else {
        context.read<ProtectedNavigation>().open(context, '/saved-places');
      }
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SaveToCollectionSheet(
        targetType: targetType,
        targetId: targetId,
        placeName: placeName,
        spot: spot,
        restaurant: restaurant,
      ),
    );
  }

  @override
  State<SaveToCollectionSheet> createState() => _SaveToCollectionSheetState();
}

class _SaveToCollectionSheetState extends State<SaveToCollectionSheet> {
  final Set<String> _initialCollectionIds = {};
  final Set<String> _selectedCollectionIds = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _initialLoadFailed = false;
  String? _inlineError;

  bool get _wasInitiallySaved => _initialCollectionIds.isNotEmpty;
  bool get _hasChanges =>
      !setEquals(_initialCollectionIds, _selectedCollectionIds);
  bool get _isRemovingAll =>
      _wasInitiallySaved && _selectedCollectionIds.isEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialState();
      }
    });
  }

  Future<void> _loadInitialState() async {
    setState(() {
      _isLoading = true;
      _initialLoadFailed = false;
      _inlineError = null;
    });

    final controller = context.read<ItineraryController>();
    try {
      await controller.loadCollections();
      if (!mounted) return;

      final memberships = await controller.fetchPlaceCollectionIds(
        targetType: widget.targetType,
        targetId: widget.targetId,
      );

      if (!mounted) return;
      setState(() {
        _initialCollectionIds.clear();
        _initialCollectionIds.addAll(memberships);
        _selectedCollectionIds.clear();
        _selectedCollectionIds.addAll(memberships);
        _isLoading = false;
        _initialLoadFailed = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _initialLoadFailed = true;
        _inlineError = 'Could not load collection memberships. Please retry.';
      });
    }
  }

  void _toggleCollection(String collectionId) {
    if (_initialLoadFailed) return;
    setState(() {
      _inlineError = null;
      if (_selectedCollectionIds.contains(collectionId)) {
        _selectedCollectionIds.remove(collectionId);
      } else {
        _selectedCollectionIds.add(collectionId);
      }
    });
  }

  Future<void> _saveMemberships() async {
    if (_initialLoadFailed || !_hasChanges) return;

    setState(() {
      _isSaving = true;
      _inlineError = null;
    });

    final controller = context.read<ItineraryController>();
    final targetCollectionIds = _selectedCollectionIds.toList();

    try {
      final result = await controller.setPlaceCollections(
        targetType: widget.targetType,
        targetId: widget.targetId,
        collectionIds: targetCollectionIds,
      );

      if (!mounted) return;

      Navigator.pop(context);

      String successMsg;
      if (_isRemovingAll || !result.saved || targetCollectionIds.isEmpty) {
        successMsg = 'Removed from Saved';
      } else if (targetCollectionIds.length == 1) {
        final colName = controller.collections
            .where((c) => c.id == targetCollectionIds.first)
            .map((c) => c.name)
            .firstOrNull;
        successMsg =
            colName != null ? 'Saved to "$colName"' : 'Saved to 1 collection';
      } else {
        successMsg = 'Saved to ${targetCollectionIds.length} collections';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _inlineError = controller.errorMessage ??
            'Could not update collection memberships. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Could not update saved places.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _showCreateCollectionDialog() async {
    final createdId = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => const _CreateCollectionDialog(),
    );

    if (createdId != null && mounted) {
      setState(() {
        _selectedCollectionIds.add(createdId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = context.watch<ItineraryController>();
    final collections = controller.collections;

    // Primary CTA configuration based on user state:
    final bool isActionEnabled;
    final String actionLabel;
    final Color? actionBgColor;
    final Color? actionFgColor;

    if (_isLoading || _isSaving || _initialLoadFailed) {
      isActionEnabled = false;
      actionLabel = 'Save';
      actionBgColor = null;
      actionFgColor = null;
    } else if (!_wasInitiallySaved) {
      if (_selectedCollectionIds.isEmpty) {
        isActionEnabled = false;
        actionLabel = 'Select a collection';
        actionBgColor = null;
        actionFgColor = null;
      } else {
        isActionEnabled = true;
        actionLabel = 'Save';
        actionBgColor = null;
        actionFgColor = null;
      }
    } else {
      if (!_hasChanges) {
        isActionEnabled = false;
        actionLabel = 'No changes';
        actionBgColor = null;
        actionFgColor = null;
      } else if (_isRemovingAll) {
        isActionEnabled = true;
        actionLabel = 'Remove from Saved';
        actionBgColor = colorScheme.errorContainer;
        actionFgColor = colorScheme.onErrorContainer;
      } else {
        isActionEnabled = true;
        actionLabel = 'Save';
        actionBgColor = null;
        actionFgColor = null;
      }
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x3,
                  vertical: AppSpacing.x1,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Save to a collection',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.placeName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'New collection',
                      icon: const Icon(Icons.create_new_folder_outlined),
                      onPressed: _showCreateCollectionDialog,
                    ),
                  ],
                ),
              ),
              if (_inlineError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x3,
                    vertical: AppSpacing.x1,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _inlineError!,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (_initialLoadFailed)
                        TextButton(
                          onPressed: _loadInitialState,
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
              const Divider(height: 1),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.x4),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (collections.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.x4),
                  child: Column(
                    children: [
                      Icon(
                        Icons.collections_bookmark_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        'No collections yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Create your first collection to start organizing places.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      FilledButton.icon(
                        onPressed: _showCreateCollectionDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create collection'),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: collections.length,
                    itemBuilder: (context, index) {
                      final collection = collections[index];
                      final isSelected =
                          _selectedCollectionIds.contains(collection.id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleCollection(collection.id),
                        title: Text(
                          collection.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${collection.itemCount} ${collection.itemCount == 1 ? "place" : "places"}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        secondary: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isSelected
                                ? Icons.bookmark
                                : Icons.bookmark_outline,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.x3),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSaving ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x2),
                    Expanded(
                      child: FilledButton(
                        onPressed: isActionEnabled && !_isSaving
                            ? _saveMemberships
                            : null,
                        style: actionBgColor != null
                            ? FilledButton.styleFrom(
                                backgroundColor: actionBgColor,
                                foregroundColor: actionFgColor,
                              )
                            : null,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(actionLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateCollectionDialog extends StatefulWidget {
  const _CreateCollectionDialog();

  @override
  State<_CreateCollectionDialog> createState() =>
      _CreateCollectionDialogState();
}

class _CreateCollectionDialogState extends State<_CreateCollectionDialog> {
  late final TextEditingController _nameCtrl;
  String? _dialogError;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final text = _nameCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _dialogError = 'Please enter a collection name.');
      return;
    }
    if (text.length > 80) {
      setState(() => _dialogError = 'Name must be 80 characters or fewer.');
      return;
    }

    final controller = context.read<ItineraryController>();
    final existing = controller.collections.any(
      (c) => c.name.trim().toLowerCase() == text.toLowerCase(),
    );
    if (existing) {
      setState(
          () => _dialogError = 'A collection with this name already exists.');
      return;
    }

    setState(() {
      _isCreating = true;
      _dialogError = null;
    });

    try {
      final created = await controller.createCollection(name: text);
      if (!mounted) return;
      if (created != null) {
        Navigator.of(context).pop(created.id);
      } else {
        setState(() {
          _isCreating = false;
          _dialogError =
              controller.errorMessage ?? 'Could not create collection.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCreating = false;
        _dialogError = 'Could not create collection. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New collection'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            maxLength: 80,
            decoration: InputDecoration(
              hintText: 'e.g. Weekend in Penang, KL Coffee',
              labelText: 'Collection name',
              errorText: _dialogError,
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              if (_dialogError != null) {
                setState(() => _dialogError = null);
              }
            },
            onSubmitted: (_) => _handleCreate(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isCreating ? null : _handleCreate,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
