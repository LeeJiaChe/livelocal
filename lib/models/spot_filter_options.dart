class SpotStateOption {
  const SpotStateOption({
    required this.rawValue,
    required this.displayName,
  });

  final String rawValue;
  final String displayName;

  factory SpotStateOption.fromRaw(String raw) {
    if (raw == 'All') {
      return const SpotStateOption(
        rawValue: 'All',
        displayName: 'All States',
      );
    }
    if (raw == 'Pulau Pinang') {
      return const SpotStateOption(
        rawValue: 'Pulau Pinang',
        displayName: 'Penang',
      );
    }
    return SpotStateOption(rawValue: raw, displayName: raw);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpotStateOption &&
          runtimeType == other.runtimeType &&
          rawValue == other.rawValue;

  @override
  int get hashCode => rawValue.hashCode;
}

class SpotFilterOptions {
  const SpotFilterOptions({
    required this.states,
    required this.categories,
  });

  final List<SpotStateOption> states;
  final List<String> categories;

  static const SpotFilterOptions fallback = SpotFilterOptions(
    states: [
      SpotStateOption(rawValue: 'All', displayName: 'All Malaysia'),
    ],
    categories: ['All'],
  );
}

class RestaurantFilterOptions {
  const RestaurantFilterOptions({
    required this.states,
    required this.cuisines,
    required this.priceRanges,
  });

  final List<String> states;
  final List<String> cuisines;
  final List<String> priceRanges;

  static const RestaurantFilterOptions fallback = RestaurantFilterOptions(
    states: ['All'],
    cuisines: ['All'],
    priceRanges: ['All'],
  );
}
