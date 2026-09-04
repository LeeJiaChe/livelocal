import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/guide_model.dart';
import '../../../models/spot_filter_options.dart';
import '../domain/guide_repository.dart';

class GuideController with ChangeNotifier {
  GuideController({required GuideRepository repository})
      : _repository = repository {
    unawaited(loadGuides());
  }

  final GuideRepository _repository;
  List<GuideModel> _guides = [];
  List<GuideModel> _adminDrafts = [];
  List<GuideModel> _mySubmissions = [];
  bool _isLoading = false;
  bool _isLoadingAdminDrafts = false;
  String _selectedState = 'All';
  String _selectedNeighbourhood = 'All';
  String _searchQuery = '';
  String? _errorMessage;
  String? _adminDraftsErrorMessage;

  List<GuideModel> get guides => List.unmodifiable(_guides);
  List<GuideModel> get adminDrafts => List.unmodifiable(_adminDrafts);
  List<GuideModel> get mySubmissions => List.unmodifiable(_mySubmissions);

  void resetPrivateState() {
    _adminDrafts = [];
    _mySubmissions = [];
    _isLoadingAdminDrafts = false;
    _adminDraftsErrorMessage = null;
    notifyListeners();
  }

  bool get isLoading => _isLoading;
  bool get isLoadingAdminDrafts => _isLoadingAdminDrafts;
  String get selectedState => _selectedState;
  String get selectedNeighbourhood => _selectedNeighbourhood;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  String? get adminDraftsErrorMessage => _adminDraftsErrorMessage;

  bool get hasActiveFilters =>
      _selectedState != 'All' ||
      _selectedNeighbourhood != 'All' ||
      _searchQuery.trim().isNotEmpty;

  List<SpotStateOption> get availableStates {
    final set = <String>{};
    for (final guide in _guides) {
      if (guide.state.trim().isNotEmpty) {
        set.add(guide.state.trim());
      }
    }
    final sorted = set.toList()..sort();
    return [
      const SpotStateOption(rawValue: 'All', displayName: 'All States'),
      ...sorted.map(SpotStateOption.fromRaw),
    ];
  }

  String get selectedStateDisplayName {
    if (_selectedState == 'All') return 'All States';
    if (_selectedState == 'Pulau Pinang') return 'Penang';
    return _selectedState;
  }

  bool _matchesState(String guideState, String selectedState) {
    if (selectedState == 'All') return true;
    if (selectedState == 'Penang' || selectedState == 'Pulau Pinang') {
      return guideState == 'Pulau Pinang' || guideState == 'Penang';
    }
    return guideState.trim().toLowerCase() ==
        selectedState.trim().toLowerCase();
  }

  List<String> get availableNeighbourhoods {
    final neighbourhoods = <String>{};
    for (final guide in _guides) {
      if (_matchesState(guide.state, _selectedState)) {
        final loc = guide.locationName.trim();
        if (loc.isNotEmpty) {
          neighbourhoods.add(loc);
        }
      }
    }
    final sorted = neighbourhoods.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['All', ...sorted];
  }

  List<GuideModel> get approvedGuides => _guides.where((guide) {
        if (!_matchesState(guide.state, _selectedState)) return false;

        final matchesNeighbourhood = _selectedNeighbourhood == 'All' ||
            guide.locationName.trim().toLowerCase() ==
                _selectedNeighbourhood.trim().toLowerCase();
        if (!matchesNeighbourhood) return false;

        final q = _searchQuery.trim().toLowerCase();
        if (q.isEmpty) return true;

        final titleMatch = guide.title.toLowerCase().contains(q);
        final locMatch = guide.locationName.toLowerCase().contains(q);
        final stateMatch = guide.state.toLowerCase().contains(q);
        final overviewMatch = guide.routeOverview.toLowerCase().contains(q);

        return titleMatch || locMatch || stateMatch || overviewMatch;
      }).toList();

  List<GuideModel> get pendingGuides => adminDrafts;

  Future<void> loadGuides() async {
    await _run(() async {
      _guides = await _repository.fetchPublishedGuides();
      if (_selectedState != 'All' &&
          !availableStates.any((s) =>
              s.rawValue == _selectedState ||
              s.displayName == _selectedState)) {
        _selectedState = 'All';
      }
      if (!availableNeighbourhoods.contains(_selectedNeighbourhood)) {
        _selectedNeighbourhood = 'All';
      }
    });
  }

  Future<void> loadAdminDrafts() async {
    _isLoadingAdminDrafts = true;
    _adminDraftsErrorMessage = null;
    notifyListeners();
    try {
      _adminDrafts = await _repository.fetchAdminDrafts();
    } catch (error) {
      _adminDraftsErrorMessage = error is AppException
          ? error.userMessage
          : 'Guide submissions could not be loaded.';
    } finally {
      _isLoadingAdminDrafts = false;
      notifyListeners();
    }
  }

  Future<void> loadMySubmissions() async {
    await _run(
      () async => _mySubmissions = await _repository.fetchMySubmissions(),
    );
  }

  Future<bool> submitGuide(GuideDraftInput input) async {
    var saved = false;
    await _run(() async {
      await _repository.submitGuide(input);
      _mySubmissions = await _repository.fetchMySubmissions();
      saved = true;
    });
    return saved;
  }

  void setStateFilter(String state) {
    _selectedState = state;
    if (!availableNeighbourhoods.contains(_selectedNeighbourhood)) {
      _selectedNeighbourhood = 'All';
    }
    notifyListeners();
  }

  void setNeighbourhoodFilter(String neighbourhood) {
    _selectedNeighbourhood = neighbourhood;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void resetFilters() {
    _selectedState = 'All';
    _selectedNeighbourhood = 'All';
    _searchQuery = '';
    notifyListeners();
  }

  Future<bool> createDraft(
    GuideDraftInput input, {
    GuideModel? guide,
  }) async {
    var saved = false;
    await _run(() async {
      await _repository.saveAdminDraft(input, guide: guide);
      _adminDrafts = await _repository.fetchAdminDrafts();
      saved = true;
    });
    return saved;
  }

  Future<bool> archiveGuide(GuideModel guide, String reason) async {
    var saved = false;
    await _run(() async {
      await _repository.archiveGuide(guide, reason);
      _guides = await _repository.fetchPublishedGuides();
      saved = true;
    });
    return saved;
  }

  Future<bool> publishDraft(GuideModel draft, String reason) async {
    var saved = false;
    await _run(() async {
      await _repository.publishAdminDraft(draft, reason);
      final results = await Future.wait([
        _repository.fetchAdminDrafts(),
        _repository.fetchPublishedGuides(),
      ]);
      _adminDrafts = results[0];
      _guides = results[1];
      saved = true;
    });
    return saved;
  }

  Future<bool> moderateSubmission(
    GuideModel guide,
    String decision,
    String reason,
  ) async {
    var saved = false;
    await _run(() async {
      await _repository.moderateSubmission(guide, decision, reason);
      final results = await Future.wait([
        _repository.fetchAdminDrafts(),
        _repository.fetchPublishedGuides(),
      ]);
      _adminDrafts = results[0];
      _guides = results[1];
      saved = true;
    });
    return saved;
  }

  Future<void> _run(Future<void> Function() operation) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await operation();
    } catch (error) {
      _errorMessage = error is AppException
          ? error.userMessage
          : 'The guide operation could not be completed.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
