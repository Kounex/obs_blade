import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/shared/general/base_card.dart';
import 'package:obs_blade/shared/general/themed_cupertino_switch.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

class ThemeActive extends StatelessWidget {
  final Box settingsBox;

  ThemeActive({@required this.settingsBox});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Use Custom Theme',
          style: Theme.of(context).textTheme.button.copyWith(fontSize: 16),
        ),
        ThemedCupertinoSwitch(
          value: this
              .settingsBox
              .get(SettingsKeys.CustomTheme.name, defaultValue: false),
          onChanged: (customTheme) =>
              this.settingsBox.put(SettingsKeys.CustomTheme.name, customTheme),
        )
      ],
    );
  }
}
