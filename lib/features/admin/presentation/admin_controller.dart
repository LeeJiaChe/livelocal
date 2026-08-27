import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/admin_repository.dart';

class AdminController with ChangeNotifier {
  AdminController({required AdminRepository repository})
      : _repository = repository;

  final AdminRepository _repository;
  List<AdminAccountSummary> _accounts = [];
  List<AdminModerationCase> _cases = [];
  List<AdminAuditEvent> _auditEvents = [];
  List<AdminAppealCase> _appeals = [];
  AdminStatistics? _statistics;
  bool _isRefreshing = false;
  bool _isMutating = false;
  bool _isLoadingModerationCases = false;
  bool _isLoadingAppeals = false;
  String? _mutationErrorMessage;
  String? _accountsErrorMessage;
  String? _moderationCasesErrorMessage;
  String? _statisticsErrorMessage;
  String? _auditErrorMessage;
  String? _appealsErrorMessage;
  DateTime? _lastUpdatedAt;

  List<AdminAccountSummary> get accounts => List.unmodifiable(_accounts);
  List<AdminModerationCase> get moderationCases => List.unmodifiable(_cases);
  List<AdminAuditEvent> get auditEvents => List.unmodifiable(_auditEvents);
  List<AdminAppealCase> get appeals => List.unmodifiable(_appeals);
  AdminStatistics? get statistics => _statistics;
  bool get isRefreshing => _isRefreshing;
  bool get isMutating => _isMutating;
  bool get isLoading => _isRefreshing || _isMutating;
  bool get isLoadingModerationCases => _isLoadingModerationCases;
  bool get isLoadingAppeals => _isLoadingAppeals;
  String? get accountsErrorMessage => _accountsErrorMessage;
  String? get moderationCasesErrorMessage => _moderationCasesErrorMessage;
  String? get statisticsErrorMessage => _statisticsErrorMessage;
  String? get auditErrorMessage => _auditErrorMessage;
  String? get appealsErrorMessage => _appealsErrorMessage;
  String? get errorMessage =>
      _mutationErrorMessage ??
      _accountsErrorMessage ??
      _moderationCasesErrorMessage ??
      _statisticsErrorMessage ??
      _auditErrorMessage ??
      _appealsErrorMessage;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;
  int get totalUsers => _statistics?.accountsTotal ?? _accounts.length;
  int get suspendedUsersCount =>
      _statistics?.accountsRestricted ??
      _accounts.where((account) => account.accessStatus != 'active').length;

  Future<void> loadDashboard() async {
    _isRefreshing = true;
    _mutationErrorMessage = null;
    notifyListeners();
    try {
      await Future.wait([
        loadAccounts(),
        loadModerationCases(),
        loadStatistics(),
        loadAuditEvents(),
        loadAppeals(),
      ]);
      _lastUpdatedAt = DateTime.now();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadAccounts() async {
    _accountsErrorMessage = null;
    notifyListeners();
    try {
      _accounts = await _repository.fetchAccounts();
    } catch (error) {
      _accountsErrorMessage = _message(error, 'Users could not be loaded.');
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadModerationCases() async {
    _isLoadingModerationCases = true;
    _moderationCasesErrorMessage = null;
    notifyListeners();
    try {
      _cases = await _repository.fetchModerationCases();
    } catch (error) {
      _moderationCasesErrorMessage =
          _message(error, 'Content reports could not be loaded.');
    } finally {
      _isLoadingModerationCases = false;
      notifyListeners();
    }
  }

  Future<void> loadStatistics() async {
    _statisticsErrorMessage = null;
    notifyListeners();
    try {
      _statistics = await _repository.fetchStatistics();
    } catch (error) {
      _statisticsErrorMessage =
          _message(error, 'Overview metrics could not be loaded.');
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadAuditEvents() async {
    _auditErrorMessage = null;
    notifyListeners();
    try {
      _auditEvents = await _repository.fetchAuditEvents();
    } catch (error) {
      _auditErrorMessage =
          _message(error, 'Audit history could not be loaded.');
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadAppeals() async {
    _isLoadingAppeals = true;
    _appealsErrorMessage = null;
    notifyListeners();
    try {
      _appeals = await _repository.fetchAppeals();
    } catch (error) {
      _appealsErrorMessage =
          _message(error, 'Account appeals could not be loaded.');
    } finally {
      _isLoadingAppeals = false;
      notifyListeners();
    }
  }

  Future<bool> setAccountAccess({
    required AdminAccountSummary account,
    required String status,
    required String publicMessage,
    required String internalReason,
    DateTime? endsAt,
  }) async {
    return _runMutation(() => _repository.setAccountAccess(
          account: account,
          status: status,
          publicMessage: publicMessage,
          internalReason: internalReason,
          endsAt: endsAt,
        ));
  }

  Future<bool> decideModerationCase({
    required AdminModerationCase moderationCase,
    required String decision,
    required String reason,
  }) async {
    return _runMutation(() => _repository.decideModerationCase(
          moderationCase: moderationCase,
          decision: decision,
          reason: reason,
        ));
  }

  Future<bool> decideAppeal({
    required AdminAppealCase appeal,
    required String decision,
    required String reason,
  }) {
    return _runMutation(() => _repository.decideAppeal(
          appeal: appeal,
          decision: decision,
          reason: reason,
        ));
  }

  Future<bool> _runMutation(Future<void> Function() operation) async {
    _isMutating = true;
    _mutationErrorMessage = null;
    notifyListeners();
    try {
      await operation();
      await loadDashboard();
      return true;
    } catch (error) {
      _mutationErrorMessage =
          _message(error, 'The administrator action could not be completed.');
      return false;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  String _message(Object error, String fallback) {
    return error is AppException ? error.userMessage : fallback;
  }
}
