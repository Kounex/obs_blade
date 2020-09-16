import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:obs_blade/shared/general/themed_cupertino_switch.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

class ThemeActive extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Use Custom Theme',
                style:
                    Theme.of(context).textTheme.button.copyWith(fontSize: 16),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Once active the selected theme below will be used for this app. If you don\'t have a custom theme yet, just create one at the bottom of this page!',
                  style: Theme.of(context).textTheme.caption,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 32.0,
        ),
        ThemedCupertinoSwitch(
          value: Hive.box(HiveKeys.Settings.name)
              .get(SettingsKeys.CustomTheme.name, defaultValue: false),
          onChanged: (customTheme) => Hive.box(HiveKeys.Settings.name).put(
            SettingsKeys.CustomTheme.name,
            customTheme,
          ),
        )
      ],
    );
  }
}
