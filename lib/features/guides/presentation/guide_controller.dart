import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/guide_model.dart';
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
  String _selectedState = 'All';
  String _selectedNeighbourhood = 'All';
  String _searchQuery = '';
  String? _errorMessage;

  List<GuideModel> get guides => List.unmodifiable(_guides);
  List<GuideModel> get adminDrafts => List.unmodifiable(_adminDrafts);
  List<GuideModel> get mySubmissions => List.unmodifiable(_mySubmissions);
  bool get isLoading => _isLoading;
  String get selectedState => _selectedState;
  String get selectedNeighbourhood => _selectedNeighbourhood;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  bool get hasActiveFilters =>
      _selectedState != 'All' ||
      _selectedNeighbourhood != 'All' ||
      _searchQuery.trim().isNotEmpty;

  List<String> get availableNeighbourhoods {
    final neighbourhoods = <String>{};
    for (final guide in _guides) {
      final matchesState = _selectedState == 'All' ||
          guide.state.trim().toLowerCase() ==
              _selectedState.trim().toLowerCase();
      if (matchesState) {
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
        final matchesState = _selectedState == 'All' ||
            guide.state.trim().toLowerCase() ==
                _selectedState.trim().toLowerCase();
        if (!matchesState) return false;

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
      if (!availableNeighbourhoods.contains(_selectedNeighbourhood)) {
        _selectedNeighbourhood = 'All';
      }
    });
  }

  Future<void> loadAdminDrafts() async {
    await _run(() async => _adminDrafts = await _repository.fetchAdminDrafts());
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
