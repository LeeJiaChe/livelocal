import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../../../../controllers/admin_controller.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_state_panel.dart';

class AdminAuditPage extends StatefulWidget {
  const AdminAuditPage({super.key});

  @override
  State<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends State<AdminAuditPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedTargetType = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final admin = context.watch<AdminController>();

    final query = _searchCtrl.text.trim().toLowerCase();

    final filteredEvents = admin.auditEvents.where((event) {
      if (_selectedTargetType != 'All') {
        if (!event.targetType
            .toLowerCase()
            .contains(_selectedTargetType.toLowerCase())) {
          return false;
        }
      }

      if (query.isEmpty) return true;
      return event.action.toLowerCase().contains(query) ||
          event.actorName.toLowerCase().contains(query) ||
          event.targetType.toLowerCase().contains(query) ||
          (event.reason?.toLowerCase().contains(query) ?? false);
    }).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        AdminSectionHeader(
          title: 'Audit History',
          count: filteredEvents.length,
          subtitle: 'Accountability log of administrative decisions and events',
        ),
        const SizedBox(height: 8),
        SearchBar(
          controller: _searchCtrl,
          hintText:
              context.tr('Search audit records by action, actor, or reason'),
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
              for (final type in [
                'All',
                'Account',
                'Spot',
                'Report',
                'Guide'
              ]) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: _selectedTargetType == type,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTargetType = type);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filteredEvents.isEmpty)
          AdminStatePanel(
            icon: Icons.history_outlined,
            title: 'No audit records',
            description: query.isNotEmpty
                ? 'No audit events match "$query".'
                : 'No audit events match the selected filter.',
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredEvents.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shield_outlined, size: 20),
                  ),
                  title: Text(
                    event.action.replaceAll('.', ' · '),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'By: ${event.actorName} · Target: ${event.targetType}${event.targetId == null ? '' : ' (${event.targetId})'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (event.reason != null && event.reason!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Reason: ${event.reason!}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Text(
                    MaterialLocalizations.of(context)
                        .formatShortDate(event.occurredAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
