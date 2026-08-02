import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import 'mock_parts.dart';

/// Minimal mock of the OBS Stats element: two telemetry tiles with a caption
/// line and a value readout each
class StatsPreview extends StatelessWidget {
  const StatsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).buttonTheme.colorScheme!.secondary;

    Widget tile({Color? valueColor}) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MockBar(height: 5.0, width: 36.0),
            const SizedBox(height: AppSpacing.xs),
            MockBar(
              height: 10.0,
              width: 26.0,
              color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ],
        ),
      ),
    );

    return Row(
      children: [
        tile(valueColor: accent),
        const SizedBox(width: AppSpacing.sm),
        tile(),
      ],
    );
  }
}
