import 'package:flutter/material.dart';

import '../../../../../models/custom_theme.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../types/extensions/string.dart';
import '../../../../../utils/styling_helper.dart';
import '../color_picker/color_bubble.dart';

/// Strip of [ColorBubble]s - one per editable color slot of the theme,
/// in the editor's order (Navigation Bars is the merged appBar/tabBar
/// slot). Bubbles carry a tooltip naming their slot so the order is not
/// the only thing telling them apart.
class ThemeColorsRow extends StatelessWidget {
  final CustomTheme customTheme;

  const ThemeColorsRow({super.key, required this.customTheme});

  Widget _bubble(String slot, Color color) => Tooltip(
    message: slot,
    child: ColorBubble(color: color, size: 20.0),
  );

  @override
  Widget build(BuildContext context) {
    /// 20pt bubbles with 8pt gaps fit the text column next to the preview
    /// thumbnail in one row (24pt bubbles with 8pt gaps needed 248pt and
    /// wrapped raggedly).
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _bubble('App Background', customTheme.backgroundColorHex.hexToColor()),
        _bubble('Cards & Sheets', customTheme.cardColorHex.hexToColor()),
        _bubble('Navigation Bars', customTheme.appBarColorHex.hexToColor()),
        _bubble('Brand Accent', customTheme.accentColorHex.hexToColor()),
        _bubble('Controls & Links', customTheme.highlightColorHex.hexToColor()),
        _bubble(
          'Card Border',
          customTheme.cardBorderColorHex?.hexToColor() ?? Colors.transparent,
        ),
        _bubble(
          'Divider',
          customTheme.dividerColorHex?.hexToColor() ??
              StylingHelper.light_divider_color,
        ),
      ],
    );
  }
}
