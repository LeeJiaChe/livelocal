import '../../../core/errors/app_exception.dart';
import '../../../models/guide_model.dart';
import '../../../services/seed_data_service.dart';
import '../../auth/data/demo_auth_repository.dart';
import '../../auth/domain/account_identity.dart';
import '../domain/guide_repository.dart';

class DemoGuideRepository implements GuideRepository {
  DemoGuideRepository(
    this._authRepository, {
    bool seedAdminWorkload = false,
  }) : _guides = List.of([
          ...SeedDataService.getInitialGuides(),
          if (seedAdminWorkload) ...[
            GuideModel(
              id: 'demo-guide-submitted-1',
              revisionId: 'demo-rev-g1',
              title: 'Jonker Street Evening Food Trail',
              locationName: 'Jonker Walk',
              state: 'Melaka',
              routeOverview:
                  'Evening walking food tour hitting the best roadside stalls in Jonker Street.',
              stops: const [
                'Cendol stall',
                'Chicken rice ball',
                'Night market snacks'
              ],
              walkingSequence: const [
                'Start at entrance',
                'Walk along main street'
              ],
              estimatedDuration: '1.5 hours',
              status: 'submitted',
            ),
            GuideModel(
              id: 'demo-guide-draft-1',
              revisionId: 'demo-rev-g2',
              title: 'George Town Heritage & Murals Draft',
              locationName: 'George Town',
              state: 'Penang',
              routeOverview:
                  'Curated draft exploring Armenian Street murals and hidden heritage shophouses.',
              stops: const ['Street Art Alley', 'Clan Jetties'],
              walkingSequence: const [
                'Start at Armenian St',
                'Walk to Clan Jetties'
              ],
              estimatedDuration: '2 hours',
              status: 'draft',
            ),
          ],
        ]);

  final DemoAuthRepository _authRepository;
  final List<GuideModel> _guides;

  @override
  Future<List<GuideModel>> fetchPublishedGuides() async {
    return _guides.where((guide) => guide.status == 'approved').toList();
  }

  @override
  Future<List<GuideModel>> fetchAdminDrafts() async {
    _requireAdmin();
    return _guides
        .where((guide) =>
            {'draft', 'submitted', 'under_review'}.contains(guide.status))
        .toList();
  }

  @override
  Future<List<GuideModel>> fetchMySubmissions() async {
    final account = _authRepository.currentAccountForDemo;
    if (account == null) return const [];
    return _guides
        .where((guide) => guide.id.startsWith('${account.id}-'))
        .toList();
  }

  @override
  Future<GuideModel> submitGuide(GuideDraftInput input) async {
    final account = _authRepository.currentAccountForDemo;
    if (account == null || account.accessStatus != AccountAccessStatus.active) {
      throw const AppException(
        code: AppErrorCode.authentication,
        userMessage: 'Sign in with an active account to submit a guide.',
      );
    }
    _validate(input);
    final now = DateTime.now().microsecondsSinceEpoch;
    final guide = GuideModel(
      id: '${account.id}-guide-$now',
      revisionId: 'demo-guide-revision-$now',
      title: input.title.trim(),
      locationName: input.locationName.trim(),
      state: input.state.trim(),
      routeOverview: input.routeOverview.trim(),
      stops: input.stops,
      walkingSequence: input.walkingSequence,
      estimatedDuration: input.estimatedDuration.trim(),
      status: 'submitted',
      authorDisplayName: account.fullName,
      authorIsCreator: account.appRole == AppRole.influencer,
    );
    _guides.add(guide);
    return guide;
  }

  @override
  Future<GuideModel> saveAdminDraft(
    GuideDraftInput input, {
    GuideModel? guide,
  }) async {
    _requireAdmin();
    _validate(input);
    if (guide != null &&
        !_guides.any(
          (item) => item.id == guide.id && item.version == guide.version,
        )) {
      throw const AppException(
        code: AppErrorCode.conflict,
        userMessage: 'The guide changed. Refresh and try again.',
      );
    }
    final id =
        guide?.id ?? 'demo-guide-${DateTime.now().microsecondsSinceEpoch}';
    final saved = GuideModel(
      id: id,
      revisionId:
          'demo-guide-revision-${DateTime.now().microsecondsSinceEpoch}',
      title: input.title.trim(),
      locationName: input.locationName.trim(),
      state: input.state.trim(),
      routeOverview: input.routeOverview.trim(),
      stops: input.stops.map((item) => item.trim()).toList(),
      walkingSequence:
          input.walkingSequence.map((item) => item.trim()).toList(),
      estimatedDuration: input.estimatedDuration.trim(),
      status: 'draft',
      version: guide == null ? 1 : guide.version + 1,
    );
    _guides.add(saved);
    return saved;
  }

  @override
  Future<void> publishAdminDraft(GuideModel draft, String reason) async {
    _requireAdmin();
    if (reason.trim().length < 3) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Record a publication reason.',
      );
    }
    final index = _guides.indexWhere(
      (guide) => guide.revisionId == draft.revisionId,
    );
    if (index < 0 || _guides[index].status != 'draft') {
      throw const AppException(
        code: AppErrorCode.conflict,
        userMessage: 'The guide draft changed. Refresh and try again.',
      );
    }
    _guides.removeWhere(
      (guide) => guide.id == draft.id && guide.status == 'approved',
    );
    final draftIndex = _guides.indexWhere(
      (guide) => guide.revisionId == draft.revisionId,
    );
    _guides[draftIndex] = _copy(
      _guides[draftIndex],
      status: 'approved',
      version: draft.version + 1,
    );
  }

  @override
  Future<void> archiveGuide(GuideModel guide, String reason) async {
    _requireAdmin();
    if (reason.trim().length < 3) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Record an archive reason.',
      );
    }
    final index = _guides.indexWhere(
      (item) =>
          item.id == guide.id &&
          item.status == 'approved' &&
          item.version == guide.version,
    );
    if (index < 0) {
      throw const AppException(
        code: AppErrorCode.conflict,
        userMessage: 'The guide changed. Refresh and try again.',
      );
    }
    _guides[index] = _copy(
      _guides[index],
      status: 'archived',
      version: guide.version + 1,
    );
  }

  @override
  Future<void> moderateSubmission(
    GuideModel guide,
    String decision,
    String reason,
  ) async {
    _requireAdmin();
    final index =
        _guides.indexWhere((item) => item.revisionId == guide.revisionId);
    if (index < 0 ||
        !{'submitted', 'under_review'}.contains(_guides[index].status)) {
      throw const AppException(
        code: AppErrorCode.conflict,
        userMessage: 'The guide submission changed. Refresh and try again.',
      );
    }
    _guides[index] = _copy(
      _guides[index],
      status: decision,
      version: guide.version + 1,
      decisionReason: reason,
    );
  }

  void _requireAdmin() {
    final account = _authRepository.currentAccountForDemo;
    if (account?.appRole != AppRole.admin ||
        account?.accessStatus != AccountAccessStatus.active) {
      throw const AppException(
        code: AppErrorCode.forbidden,
        userMessage: 'Administrator permission is required.',
      );
    }
  }

  void _validate(GuideDraftInput input) {
    if (input.stops.length < 2) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'A travel guide requires at least 2 stops.',
      );
    }
    if (input.title.trim().length < 3 ||
        input.routeOverview.trim().length < 20 ||
        input.stops.length != input.walkingSequence.length ||
        input.stops.any((item) => item.trim().length < 2) ||
        input.walkingSequence.any((item) => item.trim().length < 2)) {
      throw const AppException(
        code: AppErrorCode.validation,
        userMessage: 'Complete the guide and provide matching route steps.',
      );
    }
  }

  GuideModel _copy(
    GuideModel value, {
    required String status,
    required int version,
    String? decisionReason,
  }) {
    return GuideModel(
      id: value.id,
      revisionId: value.revisionId,
      version: version,
      title: value.title,
      locationName: value.locationName,
      state: value.state,
      routeOverview: value.routeOverview,
      stops: value.stops,
      walkingSequence: value.walkingSequence,
      estimatedDuration: value.estimatedDuration,
      status: status,
      decisionReason: decisionReason,
      authorDisplayName: value.authorDisplayName,
      authorIsCreator: value.authorIsCreator,
    );
  }
}
