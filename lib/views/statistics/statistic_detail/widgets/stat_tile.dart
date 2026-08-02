import 'package:flutter/material.dart';

import '../../../../shared/design/design.dart';

/// Big tabular numeral + caption label tile used for the aggregate numbers
/// on the statistics detail view (replaces the disabled-TextField look of
/// [FormattedText] there - values stay identical)
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;

  /// Optional value tint (ties a tile to its chart's metric color identity)
  final Color? valueColor;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              this.value,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: this.valueColor,
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                  ),
            ),
            if (this.unit != null)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: Text(
                  this.unit!.trim(),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          this.label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).textTheme.bodySmall!.color,
              ),
        ),
      ],
    );
  }
}
