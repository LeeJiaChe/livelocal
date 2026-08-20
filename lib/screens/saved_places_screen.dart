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
      if (!mounted || !context.read<AuthController>().canWrite) return;
      context.read<ItineraryController>().loadSavedPlaces();
    });
  }

  @override
  void dispose() {
    _newCollectionNameCtrl.dispose();
    super.dispose();
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
            hintText: 'e.g. Penang Food Hunt, Weekend Getaways',
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
      await controller.createCollection(name: newName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (!auth.canWrite) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bookmark_border_outlined,
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
                        '/saved',
                      ),
                  child: const Text('Sign in to LiveLocal'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = context.watch<ItineraryController>();
    final collections = controller.collections;
    final savedPlaces = controller.savedPlaces;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved collections'),
        actions: [
          IconButton(
            tooltip: 'New collection',
            icon: const Icon(Icons.create_new_folder_outlined),
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
                    childAspectRatio: 0.85,
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
          .withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
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
    final count = collection.itemCount;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Icon(
                  Icons.bookmark_outline,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count ${count == 1 ? "place" : "places"}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
