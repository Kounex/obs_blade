import 'package:flutter/material.dart';

import '../../../../shared/design/design.dart';

/// Header for the statistics section cards (Latest / Previous).
///
/// Token-delta wave 3c (mock Statistics notes): the 20px/700 + accent
/// underline + decorative watermark treatment is retired - the header
/// tightens to the 17/w600 card-title slot ([TextTheme.headlineSmall]) and
/// hierarchy is carried by type/spacing alone.
class CardHeader extends StatelessWidget {
  final String title;
  final String description;

  final List<Widget> additionalCardWidgets;

  const CardHeader({
    super.key,
    required this.title,
    this.description = '',
    this.additionalCardWidgets = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.md,
                ),
                child: Text(
                  this.description,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(
                      context,
                    ).extension<AppTextColors>()!.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...this.additionalCardWidgets,
      ],
    );
  }
}
