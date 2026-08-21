import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/validation/social_url_validator.dart';
import '../../../shared/presentation/contributions/contribution_header.dart';
import '../../../shared/presentation/contributions/contribution_review_summary.dart';
import '../../../shared/presentation/contributions/contribution_scaffold.dart';
import '../../../shared/presentation/contributions/contribution_section.dart';
import '../../../shared/presentation/contributions/contribution_status_chip.dart';
import '../../../shared/presentation/contributions/contribution_success_view.dart';
import '../domain/influencer_application_repository.dart';
import 'influencer_application_controller.dart';

class CreatorApplicationScreen extends StatefulWidget {
  const CreatorApplicationScreen({super.key});

  @override
  State<CreatorApplicationScreen> createState() =>
      _CreatorApplicationScreenState();
}

class _CreatorApplicationScreenState extends State<CreatorApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _profileUrl = TextEditingController();
  final _followerCount = TextEditingController();
  final _category = TextEditingController();
  final _message = TextEditingController();
  String _platform = 'instagram';
  bool _agreed = false;
  bool _initializedFields = false;
  bool _submittedSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InfluencerApplicationController>().loadMine();
    });
  }

  @override
  void dispose() {
    _displayName.dispose();
    _profileUrl.dispose();
    _followerCount.dispose();
    _category.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = context.watch<InfluencerApplicationController>();
    final application = controller.mine;

    if (!_initializedFields && application != null) {
      _initialize(application);
    }

    final isLocked = application != null &&
        ['submitted', 'under_review', 'approved'].contains(application.status);

    if (_submittedSuccess) {
      return Scaffold(
        appBar: AppBar(title: const Text('Application sent')),
        body: ContributionSuccessView(
          title: 'Application submitted',
          message:
              'Thanks for applying to become a LiveLocal Creator. Your account remains a Tourist while our team reviews your profile. Once approved, restaurant recommendations and Creator badges will be unlocked.',
          primaryActionLabel: 'Back to Profile',
          onPrimaryAction: () {
            Navigator.pop(context);
          },
          secondaryActionLabel: 'View my submissions',
          onSecondaryAction: () {
            Navigator.pushReplacementNamed(context, '/my-submissions');
          },
        ),
      );
    }

    return ContributionScaffold(
      appBarTitle: 'Become a Creator',
      isLoading: controller.isLoading && application == null,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x2,
            AppSpacing.x2,
            AppSpacing.x2,
            AppSpacing.x4,
          ),
          children: [
            ContributionHeader(
              icon: Icons.auto_awesome,
              title: 'Become a LiveLocal Creator',
              subtitle:
                  'Creators share trusted restaurant recommendations and help travellers discover great local food.',
              badge: application != null
                  ? ContributionStatusChip(status: application.status)
                  : null,
            ),
            const SizedBox(height: AppSpacing.x2),
            if (isLocked) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.x3),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.hourglass_top_outlined,
                          size: 20,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Application in progress',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      'Your application is currently being reviewed by LiveLocal moderators. We will notify you once a decision is made.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    OutlinedButton(
                      onPressed: controller.isLoading
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final withdrawn = await controller.withdraw();
                              if (!mounted || !withdrawn) return;
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Application withdrawn.'),
                                ),
                              );
                            },
                      child: const Text('Withdraw application'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // CREATOR PROFILE SECTION
              ContributionSection(
                title: 'Creator profile',
                subtitle: 'Your public name and primary social platform',
                children: [
                  _field(
                    _displayName,
                    'Creator display name',
                    hintText: 'e.g. Penang Foodie Guide, Alex Eats',
                    minLength: 2,
                    maxLength: 80,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  DropdownButtonFormField<String>(
                    initialValue: _platform,
                    decoration: const InputDecoration(
                      labelText: 'Primary social platform',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'instagram',
                        child: Text('Instagram'),
                      ),
                      DropdownMenuItem(
                        value: 'tiktok',
                        child: Text('TikTok'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _platform = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  TextFormField(
                    controller: _profileUrl,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: 'HTTPS profile URL',
                      hintText: _platform == 'instagram'
                          ? 'https://www.instagram.com/yourhandle'
                          : 'https://www.tiktok.com/@yourhandle',
                    ),
                    validator: (value) => SocialUrlValidator.isSupported(
                      value ?? '',
                      platform: _platform,
                    )
                        ? null
                        : 'Use a matching ${_platform == "instagram" ? "instagram.com" : "tiktok.com"} HTTPS URL.',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  TextFormField(
                    controller: _followerCount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Approximate follower count',
                      hintText: 'e.g. 5000',
                    ),
                    validator: (value) {
                      final count = int.tryParse(value?.trim() ?? '');
                      return count == null || count < 0
                          ? 'Enter a non-negative whole number.'
                          : null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  _field(
                    _category,
                    'Content focus / category',
                    hintText:
                        'e.g. Street food, Heritage cafes, Local hidden gems',
                    minLength: 2,
                    maxLength: 80,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x2),

              // MOTIVATION & RULES SECTION
              ContributionSection(
                title: 'Motivation & guidelines',
                subtitle: 'Tell us why you would like to contribute',
                children: [
                  _field(
                    _message,
                    'Why do you want to contribute to LiveLocal?',
                    hintText:
                        'Tell us about your local discoveries, culinary background, or passion for sharing Malaysian food...',
                    minLength: 20,
                    maxLength: 2000,
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _agreed,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'I agree to the Creator and Community Rules',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: InkWell(
                        onTap: _showRulesSummary,
                        child: Text(
                          'Read the current creator rules summary',
                          style: TextStyle(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => _agreed = value ?? false),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x2),

              // REVIEW SUMMARY SECTION
              ContributionReviewSummary(
                items: [
                  MapEntry('Display name', _displayName.text.trim()),
                  MapEntry('Platform', _platform.toUpperCase()),
                  MapEntry('Followers', _followerCount.text.trim()),
                  MapEntry('Focus', _category.text.trim()),
                ],
                moderationNotice:
                    'Applications are reviewed manually. Submitting does not immediately change your role.',
              ),
              if (controller.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.x2),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.errorMessage!,
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      bottomAction: isLocked
          ? null
          : SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: controller.isLoading ? null : _submit,
                child: controller.isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Apply to become a Creator'),
              ),
            ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hintText,
    required int minLength,
    required int maxLength,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        alignLabelWithHint: maxLines > 1,
      ),
      validator: (value) => (value?.trim().length ?? 0) < minLength
          ? 'Enter at least $minLength characters.'
          : null,
      onChanged: (_) => setState(() {}),
    );
  }

  void _initialize(InfluencerApplication application) {
    _initializedFields = true;
    _displayName.text = application.displayName ?? '';
    _platform = application.socialPlatform ?? 'instagram';
    _profileUrl.text = application.profileUrl ?? '';
    _followerCount.text = application.followerCount?.toString() ?? '';
    _category.text = application.contentCategory ?? '';
    _message.text = application.applicationMessage ?? '';
    _agreed = application.rulesAgreed;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review and accept the rules to apply.')),
      );
      return;
    }
    final saved =
        await context.read<InfluencerApplicationController>().saveAndSubmit(
              InfluencerApplicationDraft(
                displayName: _displayName.text.trim(),
                socialPlatform: _platform,
                profileUrl: _profileUrl.text.trim(),
                followerCount: int.parse(_followerCount.text.trim()),
                contentCategory: _category.text.trim(),
                applicationMessage: _message.text.trim(),
                rulesAgreed: _agreed,
              ),
            );
    if (!mounted) return;
    if (saved) {
      setState(() => _submittedSuccess = true);
    }
  }

  void _showRulesSummary() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Creator & Community Guidelines',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const Text(
                '1. Authenticity: Only recommend places you have personally visited and genuinely recommend.\n\n'
                '2. Transparency: Disclose any promotional discounts or partner relationships accurately.\n\n'
                '3. Respect & Safety: Follow community standards and avoid abusive, misleading, or plagiarized content.\n\n'
                '4. Moderation: All submissions undergo administrator review before being published.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetCtx),
                  child: const Text('I understand'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
