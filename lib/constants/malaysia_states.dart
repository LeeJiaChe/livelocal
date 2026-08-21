class MalaysiaStateOption {
  const MalaysiaStateOption({
    required this.rawValue,
    required this.displayName,
  });

  /// Canonical raw database value (e.g. 'Pulau Pinang')
  final String rawValue;

  /// User-facing display label (e.g. 'Penang')
  final String displayName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MalaysiaStateOption &&
          runtimeType == other.runtimeType &&
          rawValue == other.rawValue;

  @override
  int get hashCode => rawValue.hashCode;
}

class MalaysiaStates {
  MalaysiaStates._();

  static const List<MalaysiaStateOption> options = [
    MalaysiaStateOption(rawValue: 'Johor', displayName: 'Johor'),
    MalaysiaStateOption(rawValue: 'Kedah', displayName: 'Kedah'),
    MalaysiaStateOption(rawValue: 'Kelantan', displayName: 'Kelantan'),
    MalaysiaStateOption(rawValue: 'Melaka', displayName: 'Melaka'),
    MalaysiaStateOption(
        rawValue: 'Negeri Sembilan', displayName: 'Negeri Sembilan'),
    MalaysiaStateOption(rawValue: 'Pahang', displayName: 'Pahang'),
    MalaysiaStateOption(rawValue: 'Perak', displayName: 'Perak'),
    MalaysiaStateOption(rawValue: 'Perlis', displayName: 'Perlis'),
    MalaysiaStateOption(rawValue: 'Pulau Pinang', displayName: 'Penang'),
    MalaysiaStateOption(rawValue: 'Sabah', displayName: 'Sabah'),
    MalaysiaStateOption(rawValue: 'Sarawak', displayName: 'Sarawak'),
    MalaysiaStateOption(rawValue: 'Selangor', displayName: 'Selangor'),
    MalaysiaStateOption(rawValue: 'Terengganu', displayName: 'Terengganu'),
    MalaysiaStateOption(rawValue: 'Kuala Lumpur', displayName: 'Kuala Lumpur'),
    MalaysiaStateOption(rawValue: 'Labuan', displayName: 'Labuan'),
    MalaysiaStateOption(rawValue: 'Putrajaya', displayName: 'Putrajaya'),
  ];

  static const String canonicalPenang = 'Pulau Pinang';
  static const String displayPenang = 'Penang';

  /// Maps display names or aliases to canonical database raw values.
  /// E.g. 'Penang' -> 'Pulau Pinang', 'Pulau Pinang' -> 'Pulau Pinang'.
  /// Returns empty string for empty input.
  /// Preserves unknown/legacy raw strings cleanly.
  static String toCanonical(String rawOrDisplay) {
    final trimmed = rawOrDisplay.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.toLowerCase() == 'penang' ||
        trimmed.toLowerCase() == 'pulau pinang') {
      return canonicalPenang;
    }
    for (final opt in options) {
      if (opt.displayName.toLowerCase() == trimmed.toLowerCase() ||
          opt.rawValue.toLowerCase() == trimmed.toLowerCase()) {
        return opt.rawValue;
      }
    }
    return trimmed;
  }

  /// Maps raw database values to user-facing display names.
  /// E.g. 'Pulau Pinang' -> 'Penang', 'Penang' -> 'Penang'.
  /// Returns empty string for empty input.
  /// Preserves unknown raw strings.
  static String toDisplay(String rawOrDisplay) {
    final trimmed = rawOrDisplay.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.toLowerCase() == 'pulau pinang' ||
        trimmed.toLowerCase() == 'penang') {
      return displayPenang;
    }
    for (final opt in options) {
      if (opt.rawValue.toLowerCase() == trimmed.toLowerCase() ||
          opt.displayName.toLowerCase() == trimmed.toLowerCase()) {
        return opt.displayName;
      }
    }
    return trimmed;
  }

  /// Returns supported display options for contribution dropdowns.
  /// If [existingRawOrDisplay] is provided and not in the default list,
  /// it is included to avoid data loss on revision.
  static List<String> getDisplayList({String? existingRawOrDisplay}) {
    final list = options.map((opt) => opt.displayName).toList();
    if (existingRawOrDisplay != null &&
        existingRawOrDisplay.trim().isNotEmpty) {
      final disp = toDisplay(existingRawOrDisplay);
      if (!list.contains(disp)) {
        list.insert(0, disp);
      }
    }
    return list;
  }
}
