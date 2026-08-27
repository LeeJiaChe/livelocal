import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../core/routing/protected_navigation.dart';
import '../features/notifications/presentation/notification_controller.dart';
import '../features/restaurants/presentation/local_eats_controller.dart';
import '../features/spots/presentation/spot_controller.dart';
import '../features/guides/presentation/guide_controller.dart';
import '../models/notification_model.dart';
import 'guide_detail_screen.dart';
import 'restaurant_detail_screen.dart';
import 'spot_detail_screen.dart';
import '../shared/presentation/app_state_view.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<AuthController>().canWrite) return;
      context.read<NotificationController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthController>().canWrite) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_none, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Your account updates in one place',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to view moderation decisions, creator application updates, and other personal notices.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.read<ProtectedNavigation>().open(
                        context,
                        '/notifications',
                      ),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final controller = context.watch<NotificationController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (controller.unreadCount > 0)
            TextButton(
              onPressed: controller.isLoading ? null : controller.markAllRead,
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: controller.isLoading && controller.notifications.isEmpty
            ? const AppLoadingList()
            : controller.errorMessage != null &&
                    controller.notifications.isEmpty
                ? AppStateView(
                    icon: Icons.wifi_off_outlined,
                    title: 'Notifications could not be loaded',
                    message: controller.errorMessage!,
                    actionLabel: context.tr('Try again'),
                    onAction: controller.load,
                    scrollable: true,
                  )
                : controller.notifications.isEmpty
                    ? const AppStateView(
                        icon: Icons.notifications_none,
                        title: 'No notifications yet',
                        message:
                            'Account and moderation updates will appear here.',
                        scrollable: true,
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: controller.notifications.length +
                            (controller.hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == controller.notifications.length) {
                            return Center(
                              child: OutlinedButton.icon(
                                onPressed: controller.isLoadingMore
                                    ? null
                                    : controller.loadMore,
                                icon: controller.isLoadingMore
                                    ? const SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.expand_more),
                                label: const Text('Load earlier notifications'),
                              ),
                            );
                          }
                          final notification = controller.notifications[index];
                          return _NotificationCard(
                            notification: notification,
                            onTap: () => _openNotification(notification),
                          );
                        },
                      ),
      ),
    );
  }

  Future<void> _openNotification(NotificationModel notification) async {
    final controller = context.read<NotificationController>();
    if (!notification.isRead) await controller.markRead(notification.id);
    if (!mounted) return;

    final targetId = notification.targetId;
    switch (notification.targetType) {
      case 'spot':
        if (targetId == null) break;
        final spot =
            await context.read<SpotController>().fetchSpotById(targetId);
        if (!mounted) return;
        if (spot != null) {
          await Navigator.pushNamed(
            context,
            '/spot-detail',
            arguments: SpotDetailArguments(spot: spot),
          );
          return;
        }
        break;
      case 'restaurant':
        if (targetId == null) break;
        final restaurant = await context
            .read<LocalEatsController>()
            .fetchRestaurantById(targetId);
        if (!mounted) return;
        if (restaurant != null) {
          await Navigator.pushNamed(
            context,
            '/restaurant-detail',
            arguments: RestaurantDetailArguments(restaurant: restaurant),
          );
          return;
        }
        break;
      case 'guide':
        if (targetId == null) break;
        final guideController = context.read<GuideController>();
        await guideController.loadGuides();
        if (!mounted) return;
        final matches =
            guideController.guides.where((item) => item.id == targetId);
        if (matches.isNotEmpty) {
          await Navigator.pushNamed(
            context,
            '/guide-detail',
            arguments: GuideDetailArguments(guide: matches.first),
          );
          return;
        }
        break;
      case 'influencer_application':
        await Navigator.pushNamed(context, '/creator-application');
        return;
      case 'account_access_decision':
      case 'account_appeal':
        await Navigator.pushNamed(context, '/account-deletion');
        return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('This notification’s destination is no longer available.'),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, this.onTap});

  final NotificationModel notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _color(notification.type);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: notification.isRead
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        minTileHeight: 88,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          child: Icon(_icon(notification.type)),
        ),
        title: Text(notification.title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${context.tr(notification.message)}\n${context.tr(_timeAgo(notification.createdAt))}',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        isThreeLine: true,
        trailing: notification.isRead
            ? null
            : Tooltip(
                message: context.tr('Unread'),
                child: const Icon(Icons.circle, size: 10),
              ),
        onTap: onTap,
      ),
    );
  }

  static Color _color(String type) {
    if (type.contains('approved')) return Colors.green.shade700;
    if (type.contains('rejected') || type.contains('moderated')) {
      return Colors.red.shade700;
    }
    if (type.contains('information')) return Colors.orange.shade800;
    return Colors.blueGrey.shade700;
  }

  static IconData _icon(String type) {
    if (type.contains('approved')) return Icons.check_circle_outline;
    if (type.contains('creator')) return Icons.verified_user_outlined;
    if (type.contains('report') || type.contains('moderated')) {
      return Icons.gavel_outlined;
    }
    return Icons.notifications_outlined;
  }

  static String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime.toLocal());
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}
