import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../../../../controllers/admin_controller.dart';
import '../../../../controllers/auth_controller.dart';
import '../../domain/admin_repository.dart';
import '../dialogs/admin_account_access_dialog.dart';
import '../widgets/admin_section_header.dart';
import '../widgets/admin_state_panel.dart';
import '../widgets/admin_status_chip.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String _selectedStatus = 'All';
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

  Future<void> _handleAccountAccess(
    AdminAccountSummary account,
    String targetStatus,
  ) async {
    final currentAdminId = context.read<AuthController>().currentUser?.id ?? '';
    final result = await showAdminAccountAccessDialog(
      context,
      account: account,
      targetStatus: targetStatus,
      currentAdminId: currentAdminId,
    );
    if (result == null || !mounted) return;

    final controller = context.read<AdminController>();
    final saved = await controller.setAccountAccess(
      account: account,
      status: result.status,
      publicMessage: result.publicMessage,
      internalReason: result.internalReason,
      endsAt: result.endsAt,
    );
    _showMessage(
      saved
          ? 'Account access updated.'
          : controller.errorMessage ?? 'The account action could not be saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final admin = context.watch<AdminController>();
    final currentUserId = auth.currentUser?.id ?? '';

    final query = _searchCtrl.text.trim().toLowerCase();

    final filteredAccounts = admin.accounts.where((account) {
      final matchesStatus = switch (_selectedStatus) {
        'Active' => account.accessStatus == 'active',
        'Restricted' => account.accessStatus == 'restricted',
        'Banned' => account.accessStatus == 'banned',
        _ => true,
      };
      if (!matchesStatus) return false;

      if (query.isEmpty) return true;
      return account.displayName.toLowerCase().contains(query) ||
          account.email.toLowerCase().contains(query);
    }).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        AdminSectionHeader(
          title: 'User Management',
          count: filteredAccounts.length,
          subtitle: 'Manage user roles and account access permissions',
        ),
        const SizedBox(height: 8),
        SearchBar(
          controller: _searchCtrl,
          hintText: context.tr('Search by name or email'),
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
              for (final status in [
                'All',
                'Active',
                'Restricted',
                'Banned'
              ]) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: _selectedStatus == status,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedStatus = status);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filteredAccounts.isEmpty)
          AdminStatePanel(
            icon: Icons.person_search_outlined,
            title: 'No accounts found',
            description: query.isNotEmpty
                ? 'No accounts match "$query".'
                : 'No accounts match the selected status filter.',
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
              itemCount: filteredAccounts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final account = filteredAccounts[index];
                final isSelf = account.id == currentUserId;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: Text(
                      account.displayName.isEmpty
                          ? '?'
                          : account.displayName[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          account.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AdminStatusChip(status: account.accessStatus),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(account.email),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              account.role.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (account.accessEndsAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Until: ${MaterialLocalizations.of(context).formatMediumDate(account.accessEndsAt!)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: isSelf
                      ? const Tooltip(
                          message: 'You cannot change your own access.',
                          child: Icon(Icons.lock_outline),
                        )
                      : PopupMenuButton<String>(
                          tooltip: context.tr('Manage account access'),
                          onSelected: (action) =>
                              _handleAccountAccess(account, action),
                          itemBuilder: (_) => [
                            if (account.accessStatus != 'active')
                              const PopupMenuItem(
                                value: 'active',
                                child: ListTile(
                                  leading: Icon(Icons.restore),
                                  title: Text('Restore access'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            if (account.accessStatus == 'active') ...[
                              const PopupMenuItem(
                                value: 'restricted',
                                child: ListTile(
                                  leading: Icon(Icons.timer_outlined),
                                  title: Text('Temporarily restrict'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'banned',
                                child: ListTile(
                                  leading: Icon(Icons.block, color: Colors.red),
                                  title: Text('Permanently ban',
                                      style: TextStyle(color: Colors.red)),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ],
                        ),
                );
              },
            ),
          ),
      ],
    );
  }
}
