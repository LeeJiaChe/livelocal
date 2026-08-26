import 'package:flutter/material.dart' hide Text;
import 'package:live_local/core/localization/localized_text.dart';

import '../../../app/theme/app_spacing.dart';

class ContributionScaffold extends StatelessWidget {
  const ContributionScaffold({
    super.key,
    required this.appBarTitle,
    required this.body,
    this.bottomAction,
    this.maxWidth = 640,
    this.isLoading = false,
  });

  final String appBarTitle;
  final Widget body;
  final Widget? bottomAction;
  final double maxWidth;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(child: body),
                      if (bottomAction != null)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.x3),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            border: Border(
                              top: BorderSide(
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          child: bottomAction!,
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
