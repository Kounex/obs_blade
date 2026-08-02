import 'package:flutter/material.dart';

import '../../../../../models/custom_theme.dart';
import '../../../../../types/extensions/string.dart';
import '../../../../../utils/styling_helper.dart';
import '../color_picker/color_bubble.dart';

/// Strip of [ColorBubble]s - one per color slot of the theme (8 in total,
/// `textColorHex` stays dead). Bubbles carry a tooltip naming their slot
/// so the order is not the only thing telling them apart.
class ThemeColorsRow extends StatelessWidget {
  final CustomTheme customTheme;

  const ThemeColorsRow({super.key, required this.customTheme});

  Widget _bubble(String slot, Color color) => Tooltip(
        message: slot,
        child: ColorBubble(color: color, size: 20.0),
      );

  @override
  Widget build(BuildContext context) {
    /// 20pt bubbles with 6pt gaps need 202pt for all 8 slots - fits the
    /// text column next to the preview thumbnail in one row (24pt bubbles
    /// with 8pt gaps needed 248pt and wrapped raggedly 7+1).
    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      children: [
        _bubble('Card', customTheme.cardColorHex.hexToColor()),
        _bubble('App Bar', customTheme.appBarColorHex.hexToColor()),
        _bubble('Tab Bar', customTheme.tabBarColorHex.hexToColor()),
        _bubble('Background', customTheme.backgroundColorHex.hexToColor()),
        _bubble(
          'Card Border',
          customTheme.cardBorderColorHex?.hexToColor() ?? Colors.transparent,
        ),
        _bubble(
          'Divider',
          customTheme.dividerColorHex?.hexToColor() ??
              StylingHelper.light_divider_color,
        ),
        _bubble('Accent', customTheme.accentColorHex.hexToColor()),
        _bubble('Highlight', customTheme.highlightColorHex.hexToColor()),
        // _bubble('Text', customTheme.textColorHex.hexToColor()),
      ],
    );
  }
}
