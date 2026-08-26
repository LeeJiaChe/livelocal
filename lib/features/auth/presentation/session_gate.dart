import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/routing/protected_navigation.dart';
import '../../../screens/main_navigation_screen.dart';
import '../../admin/presentation/screens/admin_dashboard_screen.dart';
import '../../profile/domain/account_repository.dart';
import '../../profile/presentation/account_controller.dart';
import 'auth_controller.dart';
import 'set_new_password_screen.dart';

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    switch (auth.status) {
      case AuthStatus.checking:
        return const _SessionLoadingScreen();
      case AuthStatus.failure:
        return _SessionFailureScreen(
          message: auth.errorMessage,
          onRetry: auth.retrySessionRestore,
        );
      case AuthStatus.verificationRequired:
        return const EmailVerificationScreen();
      case AuthStatus.restricted:
      case AuthStatus.banned:
      case AuthStatus.deletionPending:
        return const RestrictedAccountScreen();
      case AuthStatus.passwordRecovery:
        return const SetNewPasswordScreen();
      case AuthStatus.guest:
        return const MainNavigationScreen();
      case AuthStatus.authenticated:
        if (auth.currentUser?.role == 'admin') {
          context.read<ProtectedNavigation?>()?.clearPending();
          return const AdminDashboardScreen();
        }
        final protectedNav =
            Provider.of<ProtectedNavigation?>(context, listen: false);
        if (protectedNav != null && protectedNav.hasPending && auth.canWrite) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            final pending = protectedNav.consumePending();
            if (pending != null && auth.canWrite) {
              Navigator.of(context).pushNamed(
                pending.routeName,
                arguments: pending.arguments,
              );
            }
          });
        }
        return const MainNavigationScreen();
    }
  }
}

class _SessionLoadingScreen extends StatelessWidget {
  const _SessionLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Semantics(
          label: 'Checking your session',
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _SessionFailureScreen extends StatelessWidget {
  const _SessionFailureScreen({required this.message, required this.onRetry});

  final String? message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'We could not check your account',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message ?? 'Check your connection and try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVerification();
    }
  }

  Future<void> _checkVerification() async {
    if (_isChecking || !mounted) return;
    final auth = context.read<AuthController>();
    if (auth.status != AuthStatus.verificationRequired) return;
    _isChecking = true;
    try {
      await auth.checkEmailVerification();
    } finally {
      if (mounted) {
        _isChecking = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final email = auth.pendingVerificationEmail ?? 'your email address';
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 56,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Check your inbox',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a verification link to $email. Open it on this device, then return to LiveLocal.',
                    textAlign: TextAlign.center,
                  ),
                  if (auth.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      auth.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            final sent = await auth.resendVerificationEmail();
                            if (!context.mounted || !sent) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Verification email sent.'),
                              ),
                            );
                          },
                    child: const Text('Resend email'),
                  ),
                  TextButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            context
                                .read<ProtectedNavigation?>()
                                ?.clearPending();
                            await auth.logout();
                            if (!context.mounted) return;
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          },
                    child: const Text('Use a different account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RestrictedAccountScreen extends StatefulWidget {
  const RestrictedAccountScreen({super.key});

  @override
  State<RestrictedAccountScreen> createState() =>
      _RestrictedAccountScreenState();
}

class _RestrictedAccountScreenState extends State<RestrictedAccountScreen> {
  String? _loadedDecisionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final decisionId =
        context.read<AuthController>().currentUser?.accessDecisionId;
    if (decisionId == null || decisionId == _loadedDecisionId) return;
    _loadedDecisionId = decisionId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AccountController>().loadAppeal(decisionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final accountController = context.watch<AccountController>();
    final account = auth.currentUser;
    final configuration = context.read<AppConfiguration>();
    final isDeletionPending = auth.status == AuthStatus.deletionPending;
    final appeal = accountController.submittedAppeal;
    final appealIsActive = appeal?.status == AppealStatus.submitted ||
        appeal?.status == AppealStatus.underReview;
    final title = switch (auth.status) {
      AuthStatus.restricted => 'Account temporarily restricted',
      AuthStatus.deletionPending => 'Account deletion scheduled',
      _ => 'Account unavailable',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Account status')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Icon(
                  isDeletionPending
                      ? Icons.schedule_outlined
                      : Icons.gpp_maybe_outlined,
                  size: 56,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  account?.accessReason ??
                      (isDeletionPending
                          ? 'You cannot create content while deletion is pending.'
                          : 'Protected actions are unavailable for this account.'),
                  textAlign: TextAlign.center,
                ),
                if (account?.accessEndsAt case final endsAt?) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Restriction ends: ${MaterialLocalizations.of(context).formatMediumDate(endsAt)}',
                    textAlign: TextAlign.center,
                  ),
                ],
                if (account?.deletionScheduledFor case final deletionDate?) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Deletion scheduled: ${MaterialLocalizations.of(context).formatMediumDate(deletionDate)}',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                if (isDeletionPending)
                  FilledButton.icon(
                    onPressed: accountController.isLoading
                        ? null
                        : () => _showRecoveryDialog(
                              context,
                              accountController,
                            ),
                    icon: const Icon(Icons.restore),
                    label: const Text('Recover my account'),
                  )
                else
                  FilledButton.icon(
                    onPressed: account?.accessDecisionId == null ||
                            accountController.isLoading ||
                            appealIsActive
                        ? null
                        : () => _showAppealDialog(
                              context,
                              accountController,
                              account!.accessDecisionId!,
                            ),
                    icon: const Icon(Icons.support_agent_outlined),
                    label: Text(
                      appealIsActive
                          ? 'Appeal under review'
                          : 'Submit an appeal',
                    ),
                  ),
                if (!isDeletionPending && appeal != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'Appeal status: ${_appealStatusLabel(appeal.status)}'
                      '${appeal.outcomeReason == null ? '' : '\n${appeal.outcomeReason}'}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                if (!isDeletionPending &&
                    account?.accessDecisionId == null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'An in-app appeal is unavailable because this account state has no auditable decision record.',
                    textAlign: TextAlign.center,
                  ),
                ],
                if (accountController.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    accountController.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),
                SelectableText(
                  'If app access fails, contact ${configuration.supportEmail}.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: auth.isLoading ? null : auth.logout,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _appealStatusLabel(AppealStatus status) => switch (status) {
        AppealStatus.submitted => 'Submitted',
        AppealStatus.underReview => 'Under review',
        AppealStatus.upheld => 'Accepted',
        AppealStatus.dismissed => 'Not accepted',
        AppealStatus.withdrawn => 'Withdrawn',
      };

  Future<void> _showRecoveryDialog(
    BuildContext context,
    AccountController controller,
  ) async {
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recover this account?'),
        content: TextField(
          controller: password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: context.tr('Current password'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm recovery'),
          ),
        ],
      ),
    );
    final enteredPassword = password.text;
    password.dispose();
    if (confirmed != true || enteredPassword.isEmpty) return;
    final recovered = await controller.cancelDeletion(enteredPassword);
    if (!context.mounted || !recovered) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your deletion request was cancelled.')),
    );
  }

  Future<void> _showAppealDialog(
    BuildContext context,
    AccountController controller,
    String decisionId,
  ) async {
    var reason = 'mistake';
    final explanation = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Appeal this decision'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  decoration: InputDecoration(
                    labelText: context.tr('Reason'),
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'mistake',
                      child: Text('I believe this is a mistake'),
                    ),
                    DropdownMenuItem(
                      value: 'context',
                      child: Text('Important context is missing'),
                    ),
                    DropdownMenuItem(
                      value: 'account_compromised',
                      child: Text('My account was compromised'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text('Another reason'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => reason = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: explanation,
                  maxLength: 2000,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: context.tr('Optional explanation'),
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const Text(
                  'We will review your appeal as soon as reasonably possible.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit appeal'),
            ),
          ],
        ),
      ),
    );
    final enteredExplanation = explanation.text.trim();
    explanation.dispose();
    if (submitted != true) return;
    final success = await controller.submitAppeal(
      decisionId: decisionId,
      reason: reason,
      explanation: enteredExplanation.isEmpty ? null : enteredExplanation,
    );
    if (!context.mounted || !success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Appeal submitted for review.')),
    );
  }
}
