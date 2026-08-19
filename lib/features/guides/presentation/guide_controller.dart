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
  String? _errorMessage;

  List<GuideModel> get guides => List.unmodifiable(_guides);
  List<GuideModel> get adminDrafts => List.unmodifiable(_adminDrafts);
  List<GuideModel> get mySubmissions => List.unmodifiable(_mySubmissions);
  bool get isLoading => _isLoading;
  String get selectedState => _selectedState;
  String? get errorMessage => _errorMessage;

  List<GuideModel> get approvedGuides => _guides.where((guide) {
        return _selectedState == 'All' ||
            guide.state.toLowerCase() == _selectedState.toLowerCase();
      }).toList();

  List<GuideModel> get pendingGuides => adminDrafts;

  Future<void> loadGuides() async {
    await _run(() async => _guides = await _repository.fetchPublishedGuides());
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
