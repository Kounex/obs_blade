import 'package:flutter/material.dart';

import '../../../../shared/design/design.dart';
import 'header_decoration.dart';

class CardHeader extends StatelessWidget {
  final String title;
  final String description;

  final IconData? headerDecorationIcon;

  final List<Widget> additionalCardWidgets;

  const CardHeader({
    super.key,
    required this.title,
    this.description = '',
    this.headerDecorationIcon,
    this.additionalCardWidgets = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  left: AppSpacing.lg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      this.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Container(
                        width: 48.0,
                        height: 4.0,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.7),
                          borderRadius: AppRadius.pill,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.md,
                      ),
                      child: Text(
                        this.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            HeaderDecoration(
              icon: this.headerDecorationIcon,
            ),
          ],
        ),
        ...this.additionalCardWidgets,
      ],
    );
  }
}
