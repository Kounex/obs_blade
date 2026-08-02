import 'package:flutter/material.dart';

/// Rounded-squircle icon tile derived from the active accent color slot -
/// the "On Air" replacement for the bare monochrome leading icons in
/// grouped settings rows (also used in subpage / dialog headers).
class AccentIconTile extends StatelessWidget {
  final IconData icon;

  /// Edge length of the tile
  final double size;

  /// Glyph size inside the tile
  final double iconSize;

  const AccentIconTile({
    super.key,
    required this.icon,
    this.size = 32.0,
    this.iconSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    /// Same accent slot [BaseButton] reads (red by default, the custom
    /// theme's accentColorHex when one is active)
    final Color accent = Theme.of(context).buttonTheme.colorScheme!.secondary;
    return Container(
      width: this.size,
      height: this.size,
      decoration: ShapeDecoration(
        color: accent.withValues(alpha: 0.15),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(this.size * 0.38),
        ),
      ),
      child: Icon(this.icon, size: this.iconSize, color: accent),
    );
  }
}
