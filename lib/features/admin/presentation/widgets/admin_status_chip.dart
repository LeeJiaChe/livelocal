import 'package:flutter/material.dart';

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, bgColor, fgColor) = switch (status.toLowerCase()) {
      'active' || 'approved' || 'published' => (
          status.toUpperCase(),
          Colors.green.shade50,
          Colors.green.shade800,
        ),
      'pending' || 'submitted' || 'under_review' => (
          status.replaceAll('_', ' ').toUpperCase(),
          Colors.amber.shade50,
          Colors.amber.shade900,
        ),
      'draft' => (
          'DRAFT',
          Colors.blueGrey.shade50,
          Colors.blueGrey.shade800,
        ),
      'restricted' || 'needs_information' => (
          status.replaceAll('_', ' ').toUpperCase(),
          Colors.orange.shade50,
          Colors.orange.shade900,
        ),
      'banned' || 'rejected' || 'dismissed' || 'archived' => (
          status.toUpperCase(),
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
        ),
      'upheld' => (
          'UPHELD',
          Colors.teal.shade50,
          Colors.teal.shade800,
        ),
      _ => (
          status.toUpperCase(),
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurfaceVariant,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fgColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fgColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
