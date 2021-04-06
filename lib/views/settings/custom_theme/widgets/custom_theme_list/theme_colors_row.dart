import 'package:flutter/material.dart';
import 'package:obs_blade/models/custom_theme.dart';
import 'package:obs_blade/views/settings/custom_theme/widgets/color_picker/color_bubble.dart';
import '../../../../../types/extensions/string.dart';

class ThemeColorsRow extends StatelessWidget {
  final CustomTheme customTheme;

  ThemeColorsRow({required this.customTheme});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        ColorBubble(color: customTheme.cardColorHex.hexToColor()),
        ColorBubble(color: customTheme.appBarColorHex.hexToColor()),
        ColorBubble(color: customTheme.tabBarColorHex.hexToColor()),
        ColorBubble(color: customTheme.accentColorHex.hexToColor()),
        ColorBubble(color: customTheme.highlightColorHex.hexToColor()),
        ColorBubble(color: customTheme.backgroundColorHex.hexToColor()),
        // ColorBubble(color: customTheme.textColorHex.hexToColor()),
      ],
    );
  }
}
