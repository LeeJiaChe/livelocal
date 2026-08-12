import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_spacing.dart';
import '../controllers/auth_controller.dart';
import '../core/routing/protected_navigation.dart';
import '../features/moderation/presentation/content_report_dialog.dart';
import '../models/guide_model.dart';

class GuideDetailArguments {
  const GuideDetailArguments({required this.guide, this.pendingReport = false});

  final GuideModel guide;
  final bool pendingReport;
}

class GuideDetailScreen extends StatefulWidget {
  const GuideDetailScreen({
    super.key,
    required this.guide,
    this.pendingReport = false,
  });

  final GuideModel guide;
  final bool pendingReport;

  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.pendingReport) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _requestReport();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final guide = widget.guide;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neighbourhood guide'),
        actions: [
          IconButton(
            tooltip: 'Report this guide',
            onPressed: _requestReport,
            icon: const Icon(Icons.flag_outlined),
          ),
          const SizedBox(width: AppSpacing.x1),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x2,
          AppSpacing.x2,
          AppSpacing.x2,
          AppSpacing.x5,
        ),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.route_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 32,
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    guide.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.x1),
                  Text('${guide.locationName}, ${guide.state}'),
                  const SizedBox(height: AppSpacing.x2),
                  Wrap(
                    spacing: AppSpacing.x1,
                    runSpacing: AppSpacing.x1,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.schedule_outlined, size: 18),
                        label: Text(guide.estimatedDuration),
                      ),
                      Chip(
                        avatar: const Icon(Icons.pin_drop_outlined, size: 18),
                        label: Text('${guide.stops.length} stops'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          Text('About this route',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.x1),
          Text(guide.routeOverview),
          const SizedBox(height: AppSpacing.x3),
          Text('Route steps', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.x1),
          _GuideStopMap(stops: guide.stops),
          const SizedBox(height: AppSpacing.x2),
          const SizedBox(height: AppSpacing.x1),
          Text(
            'Follow the order below and check current local conditions before setting out.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.x2),
          ...List.generate(
            guide.stops.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x2),
              child: _RouteStep(
                number: index + 1,
                stop: guide.stops[index],
                instruction: index < guide.walkingSequence.length
                    ? guide.walkingSequence[index]
                    : 'Continue to this stop.',
              ),
            ),
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.x2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: AppSpacing.x1),
                  Expanded(
                    child: Text(
                      'LiveLocal does not currently provide turn-by-turn navigation. This curated route is a planning guide, not a live safety or accessibility guarantee.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestReport() async {
    if (!context.read<AuthController>().canWrite) {
      context.read<ProtectedNavigation>().open(
            context,
            '/guide-detail',
            arguments: GuideDetailArguments(
              guide: widget.guide,
              pendingReport: true,
            ),
          );
      return;
    }
    await showContentReportDialog(
      context,
      targetType: 'guide',
      targetId: widget.guide.id,
    );
  }
}

class _GuideStopMap extends StatelessWidget {
  const _GuideStopMap({required this.stops});

  final List<String> stops;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Route map with ${stops.length} ordered stop markers',
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
                child: CustomPaint(painter: _RouteMapPainter())),
            ...List.generate(stops.length, (index) {
              final usableWidth = MediaQuery.sizeOf(context).width - 80;
              final step = stops.length == 1 ? 0.5 : index / (stops.length - 1);
              return Positioned(
                left: 16 + usableWidth * step,
                top: index.isEven ? 42 : 112,
                child: Tooltip(
                  message: stops[index],
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: Text('${index + 1}'),
                  ),
                ),
              );
            }),
            const Positioned(
              left: 12,
              bottom: 8,
              child: Text('Ordered route overview'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteMapPainter extends CustomPainter {
  const _RouteMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFB7C8B4)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(28, 60)
      ..cubicTo(
          size.width * .32, 25, size.width * .56, 155, size.width - 28, 122);
    canvas.drawPath(path, road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RouteStep extends StatelessWidget {
  const _RouteStep({
    required this.number,
    required this.stop,
    required this.instruction,
  });

  final int number;
  final String stop;
  final String instruction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              child: Text('$number'),
            ),
            const SizedBox(width: AppSpacing.x2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stop, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.x1),
                  Text(instruction),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
