import 'package:flutter/material.dart';

Future<String?> showAdminReasonDialog(
  BuildContext context, {
  required String title,
  required String prompt,
  String label = 'Decision reason',
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _AdminReasonDialogWidget(
      title: title,
      prompt: prompt,
      label: label,
      confirmLabel: confirmLabel,
      destructive: destructive,
    ),
  );
}

class _AdminReasonDialogWidget extends StatefulWidget {
  const _AdminReasonDialogWidget({
    required this.title,
    required this.prompt,
    required this.label,
    required this.confirmLabel,
    required this.destructive,
  });

  final String title;
  final String prompt;
  final String label;
  final String confirmLabel;
  final bool destructive;

  @override
  State<_AdminReasonDialogWidget> createState() =>
      _AdminReasonDialogWidgetState();
}

class _AdminReasonDialogWidgetState extends State<_AdminReasonDialogWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.prompt),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLength: 1000,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: widget.label,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
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
            final reason = _controller.text.trim();
            if (reason.length < 3) return;
            Navigator.pop(context, reason);
          },
          style: widget.destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
