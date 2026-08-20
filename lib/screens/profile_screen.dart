import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../core/config/legal_urls.dart';
import '../features/auth/domain/account_identity.dart';
import '../features/moderation/presentation/moderation_controller.dart';
import '../features/profile/presentation/account_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.launcher});
  final AppLauncher? launcher;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    if (user == null) {
      return _GuestProfileView(launcher: launcher);
    }
    return _AuthenticatedProfileView(launcher: launcher);
  }
}

class _AuthenticatedProfileView extends StatelessWidget {
  const _AuthenticatedProfileView({this.launcher});
  final AppLauncher? launcher;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = context.watch<AuthController>();
    final account = context.watch<AccountController>();
    final moderation = context.watch<ModerationController>();
    final user = auth.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // 1. HERO SECTION
                _ProfileHeroSection(
                  user: user,
                  isLoading: account.isLoading,
                  onEditPhoto: () => _chooseAvatar(context, account),
                  onEditProfile: () =>
                      _openEditProfileSheet(context, user, account),
                ),
                const SizedBox(height: 20),

                if (account.errorMessage != null) ...[
                  _InlineError(message: account.errorMessage!),
                  const SizedBox(height: 16),
                ],

                // 2. CREATOR CALLOUT (Tourist only)
                if (user.role == 'tourist') ...[
                  _CreatorCalloutCard(
                    onApply: () =>
                        Navigator.pushNamed(context, '/creator-application'),
                  ),
                  const SizedBox(height: 20),
                ],

                // 3. YOUR ACTIVITY
                Text(
                  'Your activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        minTileHeight: 60,
                        leading: const Icon(Icons.fact_check_outlined),
                        title: const Text('Your submissions'),
                        subtitle:
                            const Text('Drafts, review status and revisions'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            Navigator.pushNamed(context, '/my-submissions'),
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                      ListTile(
                        minTileHeight: 60,
                        leading: const Icon(Icons.notifications_outlined),
                        title: const Text('Notifications'),
                        subtitle: const Text('View your in-app history'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            Navigator.pushNamed(context, '/notifications'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. PRIVACY & SAFETY
                Text(
                  'Privacy & safety',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (moderation.supportsUserBlocking) ...[
                        ListTile(
                          minTileHeight: 60,
                          leading: const Icon(Icons.person_off_outlined),
                          title: const Text('Blocked accounts'),
                          subtitle:
                              const Text('Review or undo hidden accounts'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              Navigator.pushNamed(context, '/blocked-users'),
                        ),
                        Divider(
                          height: 1,
                          indent: 56,
                          color:
                              colorScheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ],
                      ListTile(
                        minTileHeight: 60,
                        leading: Icon(
                          Icons.delete_outline,
                          color: colorScheme.error,
                        ),
                        title: Text(
                          'Delete account',
                          style: TextStyle(color: colorScheme.error),
                        ),
                        subtitle: const Text(
                          'Schedule permanent account deletion',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: account.isLoading
                            ? null
                            : () => _showDeletionDialog(context, account),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 5. SIGN OUT
                OutlinedButton.icon(
                  onPressed: auth.isLoading ? null : auth.logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 6. LEGAL FOOTER
                _LegalFooter(launcher: launcher),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _chooseAvatar(
    BuildContext context,
    AccountController controller,
  ) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
    );
    if (image == null || !context.mounted) return;
    final bytes = await image.readAsBytes();
    final mimeType = image.mimeType ?? _mimeFromName(image.name);
    final uploaded = await controller.uploadAvatar(bytes, mimeType);
    if (!context.mounted || !uploaded) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo updated.')),
    );
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _openEditProfileSheet(
    BuildContext context,
    AccountIdentity user,
    AccountController controller,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _EditProfileBottomSheet(
        initialDisplayName: user.fullName,
        email: user.email,
        controller: controller,
      ),
    );
  }

  Future<void> _showDeletionDialog(
    BuildContext context,
    AccountController controller,
  ) async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    var obscure = true;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule account deletion?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your account will be disabled now and scheduled for permanent deletion after 14 days. You can recover your account during this grace period by signing in and confirming recovery.\n\n'
                  'If the deletion is completed:\n\n'
                  'Deleted:\n'
                  'Your profile information, saved places, itineraries, and unapproved submissions will be permanently removed.\n\n'
                  'Anonymized:\n'
                  'To preserve community history, your published reviews and approved submissions may remain visible but will be anonymized and unlinked from you.\n\n'
                  'Retained:\n'
                  'Moderation cases, safety reports, and audit logs related to your account may be retained for trust and safety purposes.\n\n'
                  'For full details, please review our Privacy Policy.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: password,
                  obscureText: obscure,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setDialogState(() => obscure = !obscure),
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmation,
                  decoration: const InputDecoration(
                    labelText: 'Type DELETE to confirm',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep account'),
            ),
            FilledButton(
              onPressed: () {
                if (password.text.isEmpty || confirmation.text != 'DELETE') {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Enter your password and type DELETE.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Schedule deletion'),
            ),
          ],
        ),
      ),
    );
    final enteredPassword = password.text;
    password.dispose();
    confirmation.dispose();
    if (shouldDelete != true || !context.mounted) return;
    final requested = await controller.requestDeletion(enteredPassword);
    if (!context.mounted || !requested) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deletion scheduled.')),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.fullName,
    required this.avatarUrl,
    this.radius = 46,
  });

  final String fullName;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trimmedName = fullName.trim();
    final initial = trimmedName.isEmpty ? 'L' : trimmedName[0].toUpperCase();

    final fallback = Center(
      child: Text(
        initial,
        style: theme.textTheme.headlineLarge?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
          ? Image.network(
              avatarUrl!.trim(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallback,
            )
          : fallback,
    );
  }
}

class _ProfileHeroSection extends StatelessWidget {
  const _ProfileHeroSection({
    required this.user,
    required this.isLoading,
    required this.onEditPhoto,
    required this.onEditProfile,
  });

  final AccountIdentity user;
  final bool isLoading;
  final VoidCallback onEditPhoto;
  final VoidCallback onEditProfile;

  String _roleLabel(AppRole role) {
    return switch (role) {
      AppRole.admin => 'Administrator',
      AppRole.influencer => 'Creator',
      AppRole.tourist => 'Tourist',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fullName = user.fullName;
    final email = user.email;
    final avatarUrl = user.avatarUrl;
    final appRole = user.appRole;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // AVATAR WITH CAMERA BUTTON
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                _UserAvatar(
                  fullName: fullName,
                  avatarUrl: avatarUrl,
                  radius: 46,
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: IconButton.filledTonal(
                    tooltip: 'Change profile photo',
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                    onPressed: isLoading ? null : onEditPhoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // FULL NAME
            Text(
              fullName.isEmpty ? 'LiveLocal Member' : fullName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // EMAIL
            Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // ROLE & VERIFIED BADGES
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: colorScheme.secondaryContainer,
                  side: BorderSide.none,
                  avatar: Icon(
                    appRole == AppRole.admin
                        ? Icons.admin_panel_settings_outlined
                        : (appRole == AppRole.influencer
                            ? Icons.stars_outlined
                            : Icons.explore_outlined),
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  label: Text(
                    _roleLabel(appRole),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                if (user.emailVerified)
                  Chip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                    side: BorderSide.none,
                    avatar: Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    label: Text(
                      'Verified',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // EDIT PROFILE BUTTON
            OutlinedButton.icon(
              onPressed: isLoading ? null : onEditProfile,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit profile'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileBottomSheet extends StatefulWidget {
  const _EditProfileBottomSheet({
    required this.initialDisplayName,
    required this.email,
    required this.controller,
  });

  final String initialDisplayName;
  final String email;
  final AccountController controller;

  @override
  State<_EditProfileBottomSheet> createState() =>
      _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<_EditProfileBottomSheet> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialDisplayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    final name = _nameController.text.trim();
    setState(() => _isSaving = true);
    final saved = await widget.controller.updateDisplayName(name);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit profile',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Display name',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.length < 2 || trimmed.length > 80) {
                  return 'Use a display name between 2 and 80 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Email (${widget.email}) changes are not currently available here.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorCalloutCard extends StatelessWidget {
  const _CreatorCalloutCard({required this.onApply});
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                color: colorScheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Become a local creator',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share trusted local food recommendations and creator-led discoveries.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: onApply,
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Apply as creator'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView({this.launcher});
  final AppLauncher? launcher;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      size: 44,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign in to make LiveLocal yours',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Save places, build itineraries, review local favourites and manage your submissions.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Sign in'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Create account'),
                ),
                const SizedBox(height: 16),
                _LegalFooter(launcher: launcher),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({this.launcher});
  final AppLauncher? launcher;

  Future<void> _launchUrl(BuildContext context, Uri url) async {
    final activeLauncher = launcher ?? const DefaultAppLauncher();
    try {
      final success = await activeLauncher.launch(url);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open the link. Please visit livelocal.app/support',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An error occurred while opening the link. Please visit livelocal.app/support',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = LegalUrls.fromCompileTime();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          TextButton(
            key: const Key('legal_terms'),
            onPressed: () => _launchUrl(context, urls.terms),
            child: Semantics(
              label: 'Terms of Service',
              child: const Text('Terms'),
            ),
          ),
          const Text('·'),
          TextButton(
            key: const Key('legal_privacy'),
            onPressed: () => _launchUrl(context, urls.privacy),
            child: Semantics(
              label: 'Privacy Policy',
              child: const Text('Privacy'),
            ),
          ),
          const Text('·'),
          TextButton(
            key: const Key('legal_rules'),
            onPressed: () => _launchUrl(context, urls.communityRules),
            child: Semantics(
              label: 'Community Rules',
              child: const Text('Community Rules'),
            ),
          ),
          const Text('·'),
          TextButton(
            key: const Key('legal_support'),
            onPressed: () => _launchUrl(context, urls.support),
            child: Semantics(
              label: 'Support',
              child: const Text('Support'),
            ),
          ),
        ],
      ),
    );
  }
}
