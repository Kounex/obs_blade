import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../utils/styling_helper.dart';

/// A single telemetry readout of the dashboard stats pager - replaces the
/// old disabled-`TextField` display ([FormattedText]) with a designed tile:
/// caption label + value that count-up tweens on the 1s stats cadence.
///
/// Mirrors the [FormattedText] API (`label` / `text` / `width` / `unit`) so
/// call sites migrate 1:1 - [text] being null renders a placeholder dash and
/// hides the unit, same as before.
class StatTile extends StatelessWidget {
  final String label;
  final String? text;
  final double width;
  final String? unit;

  const StatTile({
    super.key,
    required this.label,
    this.text,
    this.width = 50.0,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: this.width,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: 0.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            this.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: textTheme.bodySmall!.color,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: CountUpText(
                  value: this.text ?? '–',
                  maxLines: 1,
                  style: textTheme.titleLarge,
                ),
              ),
              if (this.text != null && this.unit != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  this.unit!.trim(),
                  style: textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Even-width wrap layout for [StatTile]s - same math as the legacy
/// `StatsContainer` [FormattedText] wrap (all tiles as wide as the widest
/// tile allows per row), plus a one-shot staggered entrance.
class StatTileGrid extends StatelessWidget {
  final List<StatTile> tiles;

  const StatTileGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int amountInRow = constraints.maxWidth ~/
            (this
                    .tiles
                    .reduce((value, current) =>
                        value.width >= current.width ? value : current)
                    .width +
                AppSpacing.xl);
        double generalWidth =
            (constraints.maxWidth - (amountInRow - 1) * AppSpacing.xl) /
                amountInRow;
        return Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.xl,
          children: [
            for (int i = 0; i < this.tiles.length; i++)
              StaggeredEntrance(
                index: i,
                child: StatTile(
                  label: this.tiles[i].label,
                  text: this.tiles[i].text,
                  unit: this.tiles[i].unit,
                  width: generalWidth,
                ),
              ),
          ],
        );
      },
    );
  }
}
