import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/influencer_application_repository.dart';

class InfluencerApplicationController with ChangeNotifier {
  InfluencerApplicationController({
    required InfluencerApplicationRepository repository,
  }) : _repository = repository;

  final InfluencerApplicationRepository _repository;
  InfluencerApplication? _mine;
  List<InfluencerApplication> _pending = [];
  bool _isLoading = false;
  bool _isLoadingPending = false;
  String? _errorMessage;
  String? _pendingErrorMessage;

  InfluencerApplication? get mine => _mine;
  List<InfluencerApplication> get pending => List.unmodifiable(_pending);
  bool get isLoading => _isLoading;
  bool get isLoadingPending => _isLoadingPending;
  String? get errorMessage => _errorMessage;
  String? get pendingErrorMessage => _pendingErrorMessage;

  void reset() {
    _mine = null;
    _pending = [];
    _isLoading = false;
    _isLoadingPending = false;
    _errorMessage = null;
    _pendingErrorMessage = null;
    notifyListeners();
  }

  Future<void> loadMine() async {
    await _run(() async => _mine = await _repository.fetchMine());
  }

  Future<void> loadPending() async {
    _isLoadingPending = true;
    _pendingErrorMessage = null;
    notifyListeners();
    try {
      _pending = await _repository.fetchPendingForAdmin();
    } catch (error) {
      _pendingErrorMessage = error is AppException
          ? error.userMessage
          : 'Creator applications could not be loaded.';
    } finally {
      _isLoadingPending = false;
      notifyListeners();
    }
  }

  Future<bool> saveAndSubmit(InfluencerApplicationDraft draft) async {
    var successful = false;
    await _run(() async {
      final existing =
          ['draft', 'needs_information'].contains(_mine?.status) ? _mine : null;
      final saved =
          await _repository.saveDraft(existing: existing, draft: draft);
      _mine = await _repository.submit(saved);
      successful = true;
    });
    return successful;
  }

  Future<bool> withdraw() async {
    final current = _mine;
    if (current == null) return false;
    var successful = false;
    await _run(() async {
      await _repository.withdraw(current);
      _mine = await _repository.fetchMine();
      successful = true;
    });
    return successful;
  }

  Future<bool> decide(
    InfluencerApplication application,
    String decision,
    String reason,
  ) async {
    var successful = false;
    await _run(() async {
      await _repository.decide(
        application: application,
        decision: decision,
        reason: reason,
      );
      _pending = await _repository.fetchPendingForAdmin();
      successful = true;
    });
    return successful;
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
          : 'The creator application could not be updated.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
