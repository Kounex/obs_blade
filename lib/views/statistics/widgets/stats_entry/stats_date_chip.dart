import 'package:flutter/material.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import '../../../../shared/design/design.dart';

class StatsDateChip extends StatelessWidget {
  final String label;
  final String content;

  const StatsDateChip({super.key, required this.label, required this.content});

  @override
  Widget build(BuildContext context) {
    /// Session-time rows sit at the dim text level (token-delta §2.1: stat
    /// keys/values below the entry name)
    final Color dimText = Theme.of(
      context,
    ).extension<AppTextColors>()!.textSecondary;
    return SizedBox(
      height: 48.0,
      child: Chip(
        labelPadding: const EdgeInsets.all(2.0),
        backgroundColor: StylingHelper.lightenDarkenColor(
          Theme.of(context).cardColor,
          10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(64.0),
        ),
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
        label: Row(
          children: [
            SizedBox(
              height: 32.0,
              child: Chip(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(64.0),
                ),
                side: BorderSide.none,
                padding: const EdgeInsets.all(0),
                visualDensity: VisualDensity.compact,
                backgroundColor: Theme.of(context).cardColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: SizedBox(
                  width: 40.0,
                  child: Text(
                    this.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall!.copyWith(color: dimText),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                this.content,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: dimText,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
