import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';

import '../../domain/admin_repository.dart';

class AdminAccountAccessResult {
  const AdminAccountAccessResult({
    required this.status,
    required this.publicMessage,
    required this.internalReason,
    this.endsAt,
  });

  final String status;
  final String publicMessage;
  final String internalReason;
  final DateTime? endsAt;
}

Future<AdminAccountAccessResult?> showAdminAccountAccessDialog(
  BuildContext context, {
  required AdminAccountSummary account,
  required String targetStatus,
  required String currentAdminId,
}) async {
  if (account.id == currentAdminId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You cannot change your own access.')),
    );
    return null;
  }

  return showDialog<AdminAccountAccessResult>(
    context: context,
    builder: (dialogContext) => _AdminAccountAccessDialogWidget(
      account: account,
      targetStatus: targetStatus,
    ),
  );
}

class _AdminAccountAccessDialogWidget extends StatefulWidget {
  const _AdminAccountAccessDialogWidget({
    required this.account,
    required this.targetStatus,
  });

  final AdminAccountSummary account;
  final String targetStatus;

  @override
  State<_AdminAccountAccessDialogWidget> createState() =>
      _AdminAccountAccessDialogWidgetState();
}

class _AdminAccountAccessDialogWidgetState
    extends State<_AdminAccountAccessDialogWidget> {
  late final TextEditingController _publicMessage;
  late final TextEditingController _internalReason;
  int _restrictionDays = 7;

  @override
  void initState() {
    super.initState();
    _publicMessage = TextEditingController();
    _internalReason = TextEditingController();
  }

  @override
  void dispose() {
    _publicMessage.dispose();
    _internalReason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetStatus = widget.targetStatus;
    final account = widget.account;

    return AlertDialog(
      title: Text(
        switch (targetStatus) {
          'active' => 'Restore ${account.displayName}?',
          'restricted' => 'Temporarily restrict ${account.displayName}?',
          _ => 'Permanently ban ${account.displayName}?',
        },
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (targetStatus == 'restricted') ...[
              DropdownButtonFormField<int>(
                initialValue: _restrictionDays,
                decoration: InputDecoration(
                  labelText: context.tr('Restriction duration'),
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 day')),
                  DropdownMenuItem(value: 7, child: Text('7 days')),
                  DropdownMenuItem(value: 30, child: Text('30 days')),
                ],
                onChanged: (value) => setState(
                  () => _restrictionDays = value ?? _restrictionDays,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (targetStatus != 'active') ...[
              TextField(
                controller: _publicMessage,
                maxLength: 500,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.tr('Message shown to the user'),
                  border: const OutlineInputBorder(),
                  helperText: context.tr(
                    'Displayed to the user on restricted account screen.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _internalReason,
              maxLength: 1000,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.tr('Internal decision reason'),
                border: const OutlineInputBorder(),
                helperText: context.tr('Recorded in the admin audit history.'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final internal = _internalReason.text.trim();
            final external = _publicMessage.text.trim();
            if (internal.length < 3) return;
            if (targetStatus != 'active' && external.length < 3) {
              return;
            }
            final result = AdminAccountAccessResult(
              status: targetStatus,
              publicMessage: external,
              internalReason: internal,
              endsAt: targetStatus == 'restricted'
                  ? DateTime.now().toUtc().add(Duration(days: _restrictionDays))
                  : null,
            );
            Navigator.pop(context, result);
          },
          style: targetStatus == 'banned'
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          child: Text(targetStatus == 'active' ? 'Restore' : 'Confirm'),
        ),
      ],
    );
  }
}
