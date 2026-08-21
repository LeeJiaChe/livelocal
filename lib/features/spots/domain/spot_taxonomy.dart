class SpotTaxonomy {
  SpotTaxonomy._();

  /// Canonical Spot categories for new submissions aligned with product taxonomy.
  static const List<String> canonicalCategories = [
    'Agriculture',
    'Architecture',
    'Culture',
    'Engineering',
    'Heritage',
    'Historical',
    'Landmark',
    'Marine',
    'Nature',
    'Urban',
    'Wildlife',
  ];

  static const String defaultCategory = 'Nature';

  /// Returns valid category options for submission/revision forms.
  /// If [existingCategory] is present and not part of the standard canonical list,
  /// it is preserved as an available option so revisions never silently overwrite legacy categories.
  static List<String> getCategoriesForRevision(String? existingCategory) {
    final list = List<String>.from(canonicalCategories);
    if (existingCategory != null && existingCategory.trim().isNotEmpty) {
      final trimmed = existingCategory.trim();
      if (!list.contains(trimmed)) {
        list.insert(0, trimmed);
      }
    }
    return list;
  }
}
