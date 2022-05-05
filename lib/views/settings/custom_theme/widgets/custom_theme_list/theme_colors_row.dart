import 'package:flutter/material.dart';
import '../../../../../models/custom_theme.dart';
import '../../../../../utils/styling_helper.dart';
import '../color_picker/color_bubble.dart';

import '../../../../../types/extensions/string.dart';

class ThemeColorsRow extends StatelessWidget {
  final CustomTheme customTheme;

  const ThemeColorsRow({Key? key, required this.customTheme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        ColorBubble(color: customTheme.cardColorHex.hexToColor()),
        ColorBubble(
            color: customTheme.cardBorderColorHex?.hexToColor() ??
                Colors.transparent),
        ColorBubble(
            color: customTheme.dividerColorHex?.hexToColor() ??
                StylingHelper.light_divider_color),
        ColorBubble(color: customTheme.tabBarColorHex.hexToColor()),
        ColorBubble(color: customTheme.highlightColorHex.hexToColor()),
        ColorBubble(color: customTheme.accentColorHex.hexToColor()),
        ColorBubble(color: customTheme.backgroundColorHex.hexToColor()),
        // ColorBubble(color: customTheme.textColorHex.hexToColor()),
      ],
    );
  }
}
