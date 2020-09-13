import 'package:flutter/material.dart';
import 'package:obs_blade/models/custom_theme.dart';
import '../../../../../types/extensions/string.dart';

class ThemeColorsRow extends StatelessWidget {
  final CustomTheme customTheme;

  ThemeColorsRow({@required this.customTheme});

  Widget _colorContainer(String colorHex) => Container(
        height: 24.0,
        width: 24.0,
        decoration: BoxDecoration(
          color: colorHex.hexToColor(),
          border: Border.all(
            color: Colors.black,
            width: 1.0,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _colorContainer(customTheme.primaryColorHex),
        _colorContainer(customTheme.accentColorHex),
        _colorContainer(customTheme.highlightColorHex),
        _colorContainer(customTheme.backgroundColorHex),
        // _colorContainer(customTheme.textColorHex),
      ],
    );
  }
}
