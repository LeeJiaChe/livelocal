import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';

class ContributionStatusChip extends StatelessWidget {
  const ContributionStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (label, icon, bgColor, fgColor) = switch (status.toLowerCase()) {
      'approved' => (
          'Approved',
          Icons.check_circle_outline,
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
        ),
      'submitted' || 'under_review' => (
          'Under review',
          Icons.hourglass_top_outlined,
          colorScheme.secondaryContainer,
          colorScheme.onSecondaryContainer,
        ),
      'needs_information' || 'needs_changes' => (
          'Needs information',
          Icons.info_outline,
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
        ),
      'rejected' || 'not_approved' => (
          'Not approved',
          Icons.cancel_outlined,
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
        ),
      'withdrawn' => (
          'Withdrawn',
          Icons.undo_outlined,
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
        ),
      'draft' => (
          'Draft',
          Icons.edit_note_outlined,
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
        ),
      _ => (
          status,
          Icons.help_outline,
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurfaceVariant,
        ),
    };

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fgColor,
              ),
            ),
          ],
        ),
      );
    }

    return Chip(
      visualDensity: VisualDensity.compact,
      backgroundColor: bgColor,
      side: BorderSide.none,
      avatar: Icon(icon, size: 16, color: fgColor),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fgColor,
        ),
      ),
    );
  }
}
