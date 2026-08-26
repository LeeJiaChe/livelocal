import '../../../models/guide_model.dart';

class GuideDraftInput {
  const GuideDraftInput({
    required this.title,
    required this.locationName,
    required this.state,
    required this.routeOverview,
    required this.stops,
    required this.walkingSequence,
    required this.stopDetails,
    required this.estimatedDuration,
  });

  final String title;
  final String locationName;
  final String state;
  final String routeOverview;
  final List<String> stops;
  final List<String> walkingSequence;
  final List<GuideStopModel> stopDetails;
  final String estimatedDuration;
}

abstract interface class GuideRepository {
  Future<List<GuideModel>> fetchPublishedGuides();
  Future<List<GuideModel>> fetchAdminDrafts();
  Future<List<GuideModel>> fetchMySubmissions();
  Future<GuideModel> submitGuide(GuideDraftInput input);
  Future<GuideModel> saveAdminDraft(
    GuideDraftInput input, {
    GuideModel? guide,
  });
  Future<void> publishAdminDraft(GuideModel draft, String reason);
  Future<void> archiveGuide(GuideModel guide, String reason);
  Future<void> moderateSubmission(
    GuideModel guide,
    String decision,
    String reason,
  );
}
