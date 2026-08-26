import 'package:flutter_test/flutter_test.dart';
import 'package:live_local/features/notifications/domain/notification_repository.dart';
import 'package:live_local/features/notifications/presentation/notification_controller.dart';
import 'package:live_local/models/notification_model.dart';

void main() {
  test('notification history loads in stable pages and retains read state',
      () async {
    final repository = _PagedNotificationRepository(30);
    final controller = NotificationController(repository: repository);

    await controller.load();
    expect(controller.notifications, hasLength(25));
    expect(controller.hasMore, isTrue);

    await controller.loadMore();
    expect(controller.notifications, hasLength(30));
    expect(controller.hasMore, isFalse);

    await controller.markRead('notification-0');
    expect(controller.notifications.first.isRead, isTrue);
  });
}

class _PagedNotificationRepository implements NotificationRepository {
  _PagedNotificationRepository(int count)
      : _values = List.generate(
          count,
          (index) => NotificationModel(
            id: 'notification-$index',
            userId: 'tourist-a',
            title: 'Workflow update',
            message: 'Decision $index',
            type: 'spot_approved',
            createdAt: DateTime.utc(2026, 8, 26).subtract(
              Duration(minutes: index),
            ),
          ),
        );

  List<NotificationModel> _values;

  @override
  Future<List<NotificationModel>> fetchMine({
    required int offset,
    required int limit,
  }) async {
    if (offset >= _values.length) return const [];
    return _values.sublist(offset, (offset + limit).clamp(0, _values.length));
  }

  @override
  Future<void> markRead(String? notificationId) async {
    _values = _values
        .map(
          (value) => notificationId == null || value.id == notificationId
              ? NotificationModel(
                  id: value.id,
                  userId: value.userId,
                  title: value.title,
                  message: value.message,
                  type: value.type,
                  isRead: true,
                  createdAt: value.createdAt,
                  targetType: value.targetType,
                  targetId: value.targetId,
                  readAt: DateTime.utc(2026, 8, 26),
                )
              : value,
        )
        .toList();
  }
}
