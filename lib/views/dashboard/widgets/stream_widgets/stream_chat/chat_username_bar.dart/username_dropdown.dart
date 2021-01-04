import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../../types/enums/settings_keys.dart';

class UsernameDropdown extends StatelessWidget {
  final Box settingsBox;

  UsernameDropdown({@required this.settingsBox});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 100.0),
        child: DropdownButton<String>(
          value: settingsBox.get(SettingsKeys.SelectedTwitchUsername.name),
          isExpanded: true,
          disabledHint: Text(
            'No usernames',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
          items: settingsBox
              .get(SettingsKeys.TwitchUsernames.name, defaultValue: <String>[])
              .map<DropdownMenuItem<String>>(
                (twitchUsername) => DropdownMenuItem<String>(
                  value: twitchUsername,
                  child: Text(
                    twitchUsername,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                ),
              )
              .toList(),
          onChanged: (twitchUsername) {
            settingsBox.put(
                SettingsKeys.SelectedTwitchUsername.name, twitchUsername);
          },
        ),
      ),
    );
  }
}
