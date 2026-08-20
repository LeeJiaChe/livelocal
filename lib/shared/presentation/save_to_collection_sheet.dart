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
        context.read<ProtectedNavigation>().open(context, '/main');
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
  final _newCollectionNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  @override
  void dispose() {
    _newCollectionNameCtrl.dispose();
    super.dispose();
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

  Future<void> _toggleCollection(String collectionId) async {
    setState(() {
      if (_selectedCollectionIds.contains(collectionId)) {
        _selectedCollectionIds.remove(collectionId);
      } else {
        _selectedCollectionIds.add(collectionId);
      }
    });
  }

  Future<void> _saveMemberships() async {
    setState(() => _isSaving = true);
    final controller = context.read<ItineraryController>();
    final success = await controller.setPlaceCollections(
      targetType: widget.targetType,
      targetId: widget.targetId,
      collectionIds: _selectedCollectionIds.toList(),
    );

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (_selectedCollectionIds.isEmpty
                  ? 'Removed from saved places'
                  : 'Saved to ${_selectedCollectionIds.length == 1 ? "1 collection" : "${_selectedCollectionIds.length} collections"}')
              : controller.errorMessage ?? 'Could not update saved places',
        ),
      ),
    );
  }

  Future<void> _showCreateCollectionDialog() async {
    _newCollectionNameCtrl.clear();
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('New collection'),
        content: TextField(
          controller: _newCollectionNameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Weekend in Penang, KL Coffee',
            labelText: 'Collection name',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = _newCollectionNameCtrl.text.trim();
              if (text.isNotEmpty) Navigator.pop(dialogCtx, text);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      final controller = context.read<ItineraryController>();
      final created = await controller.createCollection(name: newName);
      if (created != null && mounted) {
        setState(() {
          _selectedCollectionIds.add(created.id);
        });
      }
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
              const Divider(height: 1),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.x5),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.x1,
                    ),
                    children: [
                      ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                        title: const Text(
                          'Create new collection',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle:
                            const Text('Group places for a trip or theme'),
                        onTap: _showCreateCollectionDialog,
                      ),
                      if (collections.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.x3),
                          child: Center(
                            child:
                                Text('No collections yet. Create your first!'),
                          ),
                        )
                      else
                        ...collections.map((collection) {
                          final isSelected =
                              _selectedCollectionIds.contains(collection.id);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (_) => _toggleCollection(collection.id),
                            secondary: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.bookmark_outline,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ),
                            title: Text(
                              collection.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${collection.itemCount} ${collection.itemCount == 1 ? "place" : "places"}',
                            ),
                            controlAffinity: ListTileControlAffinity.trailing,
                          );
                        }),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.x2),
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
      ),
    );
  }
}
