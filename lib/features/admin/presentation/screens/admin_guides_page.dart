import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../controllers/guide_controller.dart';
import '../../../../models/guide_model.dart';
import '../../../../screens/guide_detail_screen.dart';
import '../../../guides/presentation/admin_guide_editor_screen.dart';
import '../dialogs/admin_reason_dialog.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_state_panel.dart';
import '../widgets/admin_status_chip.dart';

class AdminGuidesPage extends StatefulWidget {
  const AdminGuidesPage({super.key});

  @override
  State<AdminGuidesPage> createState() => _AdminGuidesPageState();
}

class _AdminGuidesPageState extends State<AdminGuidesPage> {
  String _selectedSection = 'Drafts';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _publishGuide(GuideModel guide) async {
    final reason = await showAdminReasonDialog(
      context,
      title: 'Publish this guide?',
      prompt:
          'Confirm that the route, public locations, and walking instructions have been checked.',
      destructive: false,
    );
    if (reason == null || !mounted) return;
    final controller = context.read<GuideController>();
    final saved = await controller.publishDraft(guide, reason);
    _showMessage(
      saved
          ? 'Guide published.'
          : controller.errorMessage ?? 'The guide could not be published.',
    );
  }

  Future<void> _archiveGuide(GuideModel guide) async {
    final reason = await showAdminReasonDialog(
      context,
      title: 'Archive this guide?',
      prompt:
          'The guide will stop appearing publicly. Record why the route is no longer suitable.',
      destructive: true,
    );
    if (reason == null || !mounted) return;
    final controller = context.read<GuideController>();
    final saved = await controller.archiveGuide(guide, reason);
    _showMessage(
      saved
          ? 'Guide archived.'
          : controller.errorMessage ?? 'The guide could not be archived.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final guidesController = context.watch<GuideController>();

    final drafts =
        guidesController.adminDrafts.where((g) => g.status == 'draft').toList();
    final published = guidesController.guides;

    final query = _searchCtrl.text.trim().toLowerCase();

    final filteredDrafts = drafts.where((g) {
      if (query.isEmpty) return true;
      return g.title.toLowerCase().contains(query) ||
          g.locationName.toLowerCase().contains(query) ||
          g.state.toLowerCase().contains(query);
    }).toList();

    final filteredPublished = published.where((g) {
      if (query.isEmpty) return true;
      return g.title.toLowerCase().contains(query) ||
          g.locationName.toLowerCase().contains(query) ||
          g.state.toLowerCase().contains(query);
    }).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        AdminSectionHeader(
          title: 'Guide Management',
          subtitle: 'Curate, revise, and publish neighbourhood guides',
          action: FilledButton.tonalIcon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AdminGuideEditorScreen(),
              ),
            ),
            icon: const Icon(Icons.add_road_outlined),
            label: const Text('New draft'),
          ),
        ),
        const SizedBox(height: 8),
        SearchBar(
          controller: _searchCtrl,
          hintText: 'Search guides by title or area',
          leading: const Icon(Icons.search),
          trailing: [
            if (_searchCtrl.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() => _searchCtrl.clear());
                },
              ),
          ],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: Text('Admin Drafts (${drafts.length})'),
                selected: _selectedSection == 'Drafts',
                onSelected: (selected) {
                  if (selected) setState(() => _selectedSection = 'Drafts');
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text('Published (${published.length})'),
                selected: _selectedSection == 'Published',
                onSelected: (selected) {
                  if (selected) setState(() => _selectedSection = 'Published');
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedSection == 'Drafts') ...[
          if (filteredDrafts.isEmpty)
            AdminStatePanel(
              icon: Icons.edit_note_outlined,
              title: 'No admin drafts',
              description: query.isNotEmpty
                  ? 'No drafts match "$query".'
                  : 'There are no active draft revisions in progress.',
            )
          else
            for (final guide in filteredDrafts)
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_document, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              guide.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const AdminStatusChip(status: 'draft'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${guide.locationName}, ${guide.state} · ${guide.stops.length} stops · v${guide.version}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (guide.routeOverview.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          guide.routeOverview,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      AdminGuideEditorScreen(guide: guide),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Edit draft'),
                            ),
                            FilledButton.icon(
                              onPressed: () => _publishGuide(guide),
                              icon:
                                  const Icon(Icons.publish_outlined, size: 16),
                              label: const Text('Publish'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ] else ...[
          if (filteredPublished.isEmpty)
            AdminStatePanel(
              icon: Icons.map_outlined,
              title: 'No published guides',
              description: query.isNotEmpty
                  ? 'No published guides match "$query".'
                  : 'No neighbourhood guides are currently published.',
            )
          else
            for (final guide in filteredPublished)
              Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => GuideDetailScreen(guide: guide),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.map_outlined, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                guide.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const AdminStatusChip(status: 'published'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${guide.locationName}, ${guide.state} · ${guide.stops.length} stops · v${guide.version}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (guide.routeOverview.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            guide.routeOverview,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _archiveGuide(guide),
                                icon: const Icon(Icons.archive_outlined,
                                    size: 16),
                                label: const Text('Archive'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        AdminGuideEditorScreen(guide: guide),
                                  ),
                                ),
                                icon: const Icon(Icons.rate_review_outlined,
                                    size: 16),
                                label: const Text('Revise'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }
}
