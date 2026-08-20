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
        context.read<ProtectedNavigation>().open(context, '/home');
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
  final Set<String> _selectedCollectionIds = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    final controller = context.read<ItineraryController>();
    await controller.loadCollections();
    if (!mounted) return;

    final memberships = await controller.fetchPlaceCollectionIds(
      targetType: widget.targetType,
      targetId: widget.targetId,
    );

    if (!mounted) return;
    setState(() {
      _selectedCollectionIds.addAll(memberships);
      _isLoading = false;
    });
  }

  void _toggleCollection(String collectionId) {
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
    setState(() {
      _isSaving = true;
      _inlineError = null;
    });

    final controller = context.read<ItineraryController>();
    final targetCollectionIds = _selectedCollectionIds.toList();

    final success = await controller.setPlaceCollections(
      targetType: widget.targetType,
      targetId: widget.targetId,
      collectionIds: targetCollectionIds,
    );

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isSaving = false;
        _inlineError = controller.errorMessage ??
            'Could not update collection memberships. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(controller.errorMessage ?? 'Could not update saved places.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    Navigator.pop(context);

    String successMsg;
    if (targetCollectionIds.isEmpty) {
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
  }

  Future<void> _showCreateCollectionDialog() async {
    final nameCtrl = TextEditingController();
    String? dialogError;

    final createdId = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                maxLength: 80,
                decoration: InputDecoration(
                  hintText: 'e.g. Weekend in Penang, KL Coffee',
                  labelText: 'Collection name',
                  errorText: dialogError,
                ),
                textCapitalization: TextCapitalization.words,
                onChanged: (_) {
                  if (dialogError != null) {
                    setDialogState(() => dialogError = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final text = nameCtrl.text.trim();
                if (text.isEmpty) {
                  setDialogState(
                      () => dialogError = 'Please enter a collection name.');
                  return;
                }
                if (text.length > 80) {
                  setDialogState(() =>
                      dialogError = 'Name must be 80 characters or fewer.');
                  return;
                }

                final controller = dialogCtx.read<ItineraryController>();
                final existing = controller.collections.any(
                  (c) => c.name.trim().toLowerCase() == text.toLowerCase(),
                );
                if (existing) {
                  setDialogState(() => dialogError =
                      'A collection with this name already exists.');
                  return;
                }

                final created = await controller.createCollection(name: text);
                if (created != null && dialogCtx.mounted) {
                  Navigator.pop(dialogCtx, created.id);
                } else if (dialogCtx.mounted) {
                  setDialogState(() {
                    dialogError = controller.errorMessage ??
                        'Could not create collection.';
                  });
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();

    if (createdId != null && mounted) {
      setState(() {
        _selectedCollectionIds.add(createdId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ItineraryController>();
    final collections = controller.collections;

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
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.placeName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
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
                  child: Text(
                    _inlineError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppSpacing.x2),
                      Text(
                        'No collections yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Text(
                        'Create your first collection to start organizing places.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        secondary: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isSelected
                                ? Icons.bookmark
                                : Icons.bookmark_outline,
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                            size: 20,
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
                        onPressed: _isSaving ? null : _saveMemberships,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Done'),
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
