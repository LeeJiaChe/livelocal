import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';
import '../controllers/itinerary_controller.dart';
import '../core/routing/protected_navigation.dart';
import '../models/saved_collection_model.dart';
import '../shared/presentation/app_state_view.dart';
import 'collection_detail_screen.dart';
import 'itinerary_screen.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final _newCollectionNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      if (auth.isAuthenticated) {
        context.read<ItineraryController>().loadSavedPlaces();
      }
    });
  }

  @override
  void dispose() {
    _newCollectionNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _showCreateCollectionDialog() async {
    _newCollectionNameCtrl.clear();
    String? dialogError;

    final created = await showDialog<SavedCollectionModel>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New collection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _newCollectionNameCtrl,
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
                final text = _newCollectionNameCtrl.text.trim();
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

                final result = await controller.createCollection(name: text);
                if (result != null && dialogCtx.mounted) {
                  Navigator.pop(dialogCtx, result);
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

    if (created != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CollectionDetailScreen(collection: created),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<ItineraryController>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved collections'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Keep track of places you love',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  'Sign in to organize spots into custom collections and plan your day itineraries.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.x3),
                FilledButton(
                  onPressed: () => context.read<ProtectedNavigation>().open(
                        context,
                        '/saved-places',
                      ),
                  child: const Text('Sign in to LiveLocal'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final collections = controller.collections;
    final savedPlaces = controller.savedPlaces;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved collections'),
        actions: [
          IconButton(
            tooltip: 'New collection',
            icon: const Icon(Icons.add),
            onPressed: _showCreateCollectionDialog,
          ),
          const SizedBox(width: AppSpacing.x1),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadSavedPlaces,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x2,
                  AppSpacing.x1,
                  AppSpacing.x2,
                  AppSpacing.x2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your curated collections',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Organize places for upcoming trips, food hunts, or weekend plans.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (controller.isLoading && collections.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.errorMessage != null && collections.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppStateView(
                  icon: Icons.wifi_off_outlined,
                  title: 'Saved collections could not be loaded',
                  message: controller.errorMessage!,
                  actionLabel: 'Try again',
                  onAction: controller.loadSavedPlaces,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x2,
                  0,
                  AppSpacing.x2,
                  112,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.x2,
                    crossAxisSpacing: AppSpacing.x2,
                    childAspectRatio: 0.82,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return _CreateCollectionCard(
                          onTap: _showCreateCollectionDialog,
                        );
                      }
                      final collection = collections[index - 1];
                      return _CollectionGridCard(
                        collection: collection,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => CollectionDetailScreen(
                              collection: collection,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: collections.length + 1,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: savedPlaces.isNotEmpty
          ? FloatingActionButton.extended(
              heroTag: 'saved_places_fab',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const ItineraryScreen(),
                ),
              ),
              icon: const Icon(Icons.route_outlined),
              label: const Text('Plan route'),
            )
          : null,
    );
  }
}

class _CreateCollectionCard extends StatelessWidget {
  const _CreateCollectionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.6),
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                'New collection',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionGridCard extends StatelessWidget {
  const _CollectionGridCard({
    required this.collection,
    required this.onTap,
  });

  final SavedCollectionModel collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final count = collection.itemCount;
    final hasCover = collection.coverImageUrl != null &&
        collection.coverImageUrl!.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: hasCover
                  ? CachedNetworkImage(
                      imageUrl: collection.coverImageUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: double.infinity,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.bookmark_outline,
                          size: 36,
                          color: colorScheme.primary,
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.collections_bookmark_outlined,
                        size: 36,
                        color: colorScheme.primary,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ${count == 1 ? "place" : "places"}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
