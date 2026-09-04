import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../admin/presentation/admin_controller.dart';
import '../../guides/presentation/guide_controller.dart';
import '../../influencer_applications/presentation/influencer_application_controller.dart';
import '../../itinerary/presentation/itinerary_controller.dart';
import '../../moderation/presentation/moderation_controller.dart';
import '../../notifications/presentation/notification_controller.dart';
import '../../profile/presentation/account_controller.dart';
import '../../restaurants/presentation/local_eats_controller.dart';
import '../../spots/presentation/spot_controller.dart';
import 'auth_controller.dart';

/// Coordinates global, top-level navigation changes in response to auth events,
/// specifically ensuring password recovery transitions reliably reset the root
/// navigator to '/home' where SessionGate displays the SetNewPasswordScreen
/// regardless of what route was active on top, and isolating private state
/// when the authenticated user identity changes.
class AuthNavigationCoordinator extends StatefulWidget {
  const AuthNavigationCoordinator({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  static void resetPrivateControllers(BuildContext context) {
    Provider.of<ItineraryController?>(context, listen: false)?.reset();
    Provider.of<NotificationController?>(context, listen: false)?.reset();
    Provider.of<SpotController?>(context, listen: false)?.resetPrivateState();
    Provider.of<LocalEatsController?>(context, listen: false)
        ?.resetPrivateState();
    Provider.of<GuideController?>(context, listen: false)?.resetPrivateState();
    Provider.of<InfluencerApplicationController?>(context, listen: false)
        ?.reset();
    Provider.of<ModerationController?>(context, listen: false)?.reset();
    Provider.of<AccountController?>(context, listen: false)?.reset();
    Provider.of<AdminController?>(context, listen: false)?.reset();
  }

  @override
  State<AuthNavigationCoordinator> createState() =>
      _AuthNavigationCoordinatorState();
}

class _AuthNavigationCoordinatorState extends State<AuthNavigationCoordinator> {
  AuthStatus? _previousStatus;
  String? _previousUserId;
  bool _hasTrackedUser = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthController>();
    final currentStatus = auth.status;
    final currentUserId = auth.currentUser?.id;

    if (!_hasTrackedUser) {
      _hasTrackedUser = true;
      _previousUserId = currentUserId;
    } else if (_previousUserId != currentUserId) {
      _previousUserId = currentUserId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AuthNavigationCoordinator.resetPrivateControllers(context);
      });
    }

    if (_previousStatus != currentStatus) {
      final prev = _previousStatus;
      _previousStatus = currentStatus;

      // When transitioning into passwordRecovery from a non-recovery state:
      if (currentStatus == AuthStatus.passwordRecovery &&
          prev != AuthStatus.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final navigator = widget.navigatorKey.currentState;
          if (navigator != null) {
            navigator.pushNamedAndRemoveUntil('/home', (route) => false);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
