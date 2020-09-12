import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../types/enums/settings_keys.dart';
import 'color_row.dart';

class ThemeColors extends StatelessWidget {
  final Box settingsBox;

  ThemeColors({@required this.settingsBox});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ColorRow(
          settingsBox: this.settingsBox,
          colorKey: SettingsKeys.CustomPrimaryColor,
        )
      ],
    );
  }
}
