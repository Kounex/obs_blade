import 'package:flutter/material.dart';

import '../../../shared/design/design.dart';

/// Rounded-squircle tile carrying the purely decorative leading icons in
/// grouped settings rows (also used in subpage / dialog headers).
///
/// Token-delta rule 5: decorative icon tiles are neutral (white 7% tile +
/// dim glyph) - they don't spend the accent.
class DecorativeIconTile extends StatelessWidget {
  final IconData icon;

  /// Edge length of the tile
  final double size;

  /// Glyph size inside the tile
  final double iconSize;

  const DecorativeIconTile({
    super.key,
    required this.icon,
    this.size = 32.0,
    this.iconSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: this.size,
      height: this.size,
      decoration: ShapeDecoration(
        color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.07),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(this.size * 0.38),
        ),
      ),
      child: Icon(
        this.icon,
        size: this.iconSize,
        color: Theme.of(context).extension<AppTextColors>()!.textSecondary,
      ),
    );
  }
}
