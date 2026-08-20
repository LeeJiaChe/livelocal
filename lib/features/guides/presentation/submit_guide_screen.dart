import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../moderation/presentation/ugc_consent_dialog.dart';
import '../domain/guide_repository.dart';
import 'guide_controller.dart';

class SubmitGuideScreen extends StatefulWidget {
  const SubmitGuideScreen({super.key});

  @override
  State<SubmitGuideScreen> createState() => _SubmitGuideScreenState();
}

class _SubmitGuideScreenState extends State<SubmitGuideScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _state = TextEditingController();
  final _overview = TextEditingController();
  final _duration = TextEditingController();
  final _stops = <_StopDraft>[_StopDraft()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GuideController>().loadMySubmissions();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _state.dispose();
    _overview.dispose();
    _duration.dispose();
    for (final stop in _stops) {
      stop.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<GuideController>();
    if (!auth.canWrite) {
      return Scaffold(
        appBar: AppBar(title: const Text('Submit a guide')),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('Sign in to submit a guide'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Submit a neighbourhood guide')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            Text('Share a route locals love',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Your guide stays private while an administrator checks every stop. Only approved guides become public.',
            ),
            const SizedBox(height: 20),
            _field(_title, 'Guide title', 3, 160),
            _field(_overview, 'Description and route summary', 20, 3000,
                maxLines: 5),
            _field(_location, 'Neighbourhood or area', 2, 120),
            _field(_state, 'State or territory', 2, 80),
            _field(_duration, 'Estimated duration', 2, 80),
            const SizedBox(height: 8),
            Text('Ordered stops',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...List.generate(_stops.length, (index) {
              final stop = _stops[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(child: Text('${index + 1}')),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Stop ${index + 1}')),
                          if (_stops.length > 1)
                            IconButton(
                              tooltip: 'Remove stop',
                              onPressed: () => setState(() {
                                _stops.removeAt(index).dispose();
                              }),
                              icon: const Icon(Icons.delete_outline),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _field(stop.name, 'Place or stop name', 2, 300),
                      _field(
                          stop.instruction, 'Description / directions', 2, 500,
                          maxLines: 3),
                    ],
                  ),
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _stops.length >= 30
                  ? null
                  : () => setState(() => _stops.add(_StopDraft())),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add stop'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.isLoading ? null : _submit,
              icon: const Icon(Icons.send_outlined),
              label: Text(
                  controller.isLoading ? 'Submitting…' : 'Submit for review'),
            ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(controller.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            if (controller.mySubmissions.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text('Your submissions',
                  style: Theme.of(context).textTheme.titleLarge),
              ...controller.mySubmissions.map(
                (guide) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(guide.title),
                  subtitle: Text(_statusMessage(guide.status)),
                  trailing:
                      Chip(label: Text(guide.status.replaceAll('_', ' '))),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    int min,
    int max, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLength: max,
        maxLines: maxLines,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: (value) => (value?.trim().length ?? 0) < min
            ? 'Enter at least $min characters.'
            : null,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final input = GuideDraftInput(
      title: _title.text.trim(),
      locationName: _location.text.trim(),
      state: _state.text.trim(),
      routeOverview: _overview.text.trim(),
      stops: _stops.map((stop) => stop.name.text.trim()).toList(),
      walkingSequence:
          _stops.map((stop) => stop.instruction.text.trim()).toList(),
      estimatedDuration: _duration.text.trim(),
    );
    final controller = context.read<GuideController>();
    var saved = await controller.submitGuide(input);
    if (!saved && controller.errorMessage == 'UGC_RULES_ACCEPTANCE_REQUIRED') {
      if (!mounted) return;
      final accepted = await showUgcConsentDialog(context);
      if (accepted) saved = await controller.submitGuide(input);
    }
    if (!mounted) return;
    if (!saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guide submitted for admin review.')),
    );
    Navigator.pop(context);
  }

  String _statusMessage(String status) => switch (status) {
        'approved' => 'Approved and publicly browsable.',
        'rejected' => 'Rejected and not public.',
        'under_review' => 'An administrator is reviewing this guide.',
        _ => 'Pending administrator review.',
      };
}

class _StopDraft {
  final name = TextEditingController();
  final instruction = TextEditingController();

  void dispose() {
    name.dispose();
    instruction.dispose();
  }
}
