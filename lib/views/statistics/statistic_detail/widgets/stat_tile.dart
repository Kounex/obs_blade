import 'package:flutter/material.dart';

import '../../../../shared/design/design.dart';
import '../../../../utils/styling_helper.dart';

/// Carded caption + big-numeral tile for the aggregate numbers on the
/// statistics detail view - mirrors the dashboard stats pager's tile
/// anatomy (even-width grid, [CountUpText] value) and keeps the optional
/// [valueColor] tie to a chart's metric color identity.
///
/// Numeric values count up once on entrance; non-numeric values (durations)
/// snap, same as [CountUpText] does for live cadence updates.
class StatTile extends StatefulWidget {
  final String label;
  final String value;
  final String? unit;

  /// Optional value tint (ties a tile to its chart's metric color identity)
  final Color? valueColor;

  /// Content width estimate - only used by [StatTileGrid] to derive the
  /// column count (every tile renders at the computed even width)
  final double width;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.valueColor,
    this.width = 100.0,
  });

  @override
  State<StatTile> createState() => _StatTileState();
}

class _StatTileState extends State<StatTile> {
  /// One-shot entrance: numeric values start at 0 for a frame so
  /// [CountUpText] tweens to the real value exactly once
  late String _shownValue;

  @override
  void initState() {
    super.initState();
    _shownValue = double.tryParse(this.widget.value) != null
        ? '0'
        : this.widget.value;
    if (_shownValue != this.widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (this.mounted) {
          setState(() => _shownValue = this.widget.value);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: this.widget.width,
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
            this.widget.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall!.copyWith(
              /// Stat keys sit at the dim text level (token-delta §2.1)
              color: Theme.of(
                context,
              ).extension<AppTextColors>()!.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: CountUpText(
                  value: _shownValue,
                  maxLines: 1,
                  style: textTheme.titleLarge!.copyWith(
                    color: this.widget.valueColor,
                  ),
                ),
              ),
              if (this.widget.unit != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(this.widget.unit!.trim(), style: textTheme.bodySmall),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Even-width wrap layout for [StatTile]s - same math as the dashboard's
/// tile grid (all tiles as wide as the widest tile allows per row), plus a
/// one-shot staggered entrance.
class StatTileGrid extends StatelessWidget {
  final List<StatTile> tiles;

  const StatTileGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int amountInRow =
            constraints.maxWidth ~/
            (this.tiles
                    .reduce(
                      (value, current) =>
                          value.width >= current.width ? value : current,
                    )
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
                scaleFrom: 0.985,
                child: StatTile(
                  label: this.tiles[i].label,
                  value: this.tiles[i].value,
                  unit: this.tiles[i].unit,
                  valueColor: this.tiles[i].valueColor,
                  width: generalWidth,
                ),
              ),
          ],
        );
      },
    );
  }
}
