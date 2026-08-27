import '../../../models/notification_model.dart';

abstract interface class NotificationRepository {
  Future<List<NotificationModel>> fetchMine({
    required int offset,
    required int limit,
  });
  Future<void> markRead(String? notificationId);
}
