class RestaurantTaxonomy {
  RestaurantTaxonomy._();

  /// Curated Malaysian restaurant cuisine types for suggestions and autocomplete.
  static const List<String> curatedCuisines = [
    'Bakery / Traditional',
    'Cantonese / Zi Char',
    'Chinese / Kopitiam',
    'Chinese / Noodles',
    'Chinese / Seafood',
    'Chinese / Street Food',
    'Fusion',
    'Hainanese',
    'Hainanese / Kopitiam',
    'Hainanese / Street Food',
    'Hawker / Street Food',
    'Indian',
    'Italian',
    'Japanese',
    'Kopitiam / Hawker',
    'Kopitiam / Multi-ethnic',
    'Korean',
    'Malay / Nasi Lemak',
    'Malay / Traditional',
    'Mamak / Indian Muslim',
    'Nasi Kandar / Indian Muslim',
    'Nasi Kandar / Street Food',
    'Peranakan / Nyonya',
    'Sabah / Noodles',
    'Sarawak / Kopitiam',
    'Seafood / Local',
    'Thai',
    'Western',
    'Other',
  ];

  static const String defaultCuisine = 'Malay / Traditional';

  /// Suggest matching cuisines based on user input query.
  static List<String> filterSuggestions(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return curatedCuisines.take(8).toList();
    return curatedCuisines
        .where((c) => c.toLowerCase().contains(clean))
        .toList();
  }
}
