import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_spacing.dart';
import '../domain/external_place.dart';
import '../domain/place_provider.dart';

class GooglePlaceSearchSheet extends StatefulWidget {
  const GooglePlaceSearchSheet({
    super.key,
    required this.title,
    required this.hintText,
  });

  final String title;
  final String hintText;

  static Future<ExternalPlace?> show(
    BuildContext context, {
    required String title,
    required String hintText,
    String initialQuery = '',
  }) {
    return showModalBottomSheet<ExternalPlace>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => GooglePlaceSearchSheet(
        title: title,
        hintText: hintText,
      ),
    );
  }

  @override
  State<GooglePlaceSearchSheet> createState() => _GooglePlaceSearchSheetState();
}

class _GooglePlaceSearchSheetState extends State<GooglePlaceSearchSheet> {
  final _query = TextEditingController();
  List<ExternalPlace> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final value = _query.text.trim();
    if (value.length < 2) {
      setState(() => _error = 'Enter at least two characters.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await context.read<PlaceProvider>().search(query: value);
      if (!mounted) return;
      setState(() => _results = page.places);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Places could not be loaded. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.x2,
          right: AppSpacing.x2,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.x2,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.x1),
              TextField(
                key: const Key('google_place_search_field'),
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Search',
                    onPressed: _loading ? null : _search,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ),
              ),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.x1),
                  child: Text(
                    _error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: AppSpacing.x1),
              Expanded(
                child: _results.isEmpty && !_loading
                    ? const Center(
                        child: Text(
                          'Search by place name and city, then choose the exact location.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final place = _results[index];
                          return ListTile(
                            key: ValueKey('place-choice-${place.placeId}'),
                            leading: const Icon(Icons.place_outlined),
                            title: Text(place.name),
                            subtitle: Text(place.formattedAddress),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(context, place),
                          );
                        },
                      ),
              ),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Place results provided by Google',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
