import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';

/// Displays a review's content with language-selection affordances (EN, ZH, MS).
///
/// If a translation for the selected language is not available in the current
/// build, an honest fallback notice is displayed instead of fabricating
/// pseudo-translations.
class ReviewTextWidget extends StatefulWidget {
  const ReviewTextWidget({
    super.key,
    required this.text,
  });

  final String text;

  @override
  State<ReviewTextWidget> createState() => _ReviewTextWidgetState();
}

class _ReviewTextWidgetState extends State<ReviewTextWidget> {
  String _selectedLanguage = 'EN';

  static const List<String> _languages = ['EN', 'ZH', 'MS'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTranslatedAvailable = _selectedLanguage == 'EN';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6,
          children: _languages.map((lang) {
            final isSelected = _selectedLanguage == lang;
            return ChoiceChip(
              label: Text(
                lang,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedLanguage = lang);
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        if (isTranslatedAvailable)
          Text(
            widget.text,
            style: const TextStyle(fontSize: 13, height: 1.4),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Translation ($_selectedLanguage) is not available for this review in this build.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
      ],
    );
  }
}
