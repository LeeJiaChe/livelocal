import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_controller.dart';

/// Coordinates global, top-level navigation changes in response to auth events,
/// specifically ensuring password recovery transitions reliably reset the root
/// navigator to '/home' where SessionGate displays the SetNewPasswordScreen
/// regardless of what route was active on top.
class AuthNavigationCoordinator extends StatefulWidget {
  const AuthNavigationCoordinator({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AuthNavigationCoordinator> createState() =>
      _AuthNavigationCoordinatorState();
}

class _AuthNavigationCoordinatorState extends State<AuthNavigationCoordinator> {
  AuthStatus? _previousStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthController>();
    final currentStatus = auth.status;

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
