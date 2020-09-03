import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

import '../../../../../../types/enums/hive_keys.dart';
import 'username_action_row.dart';

class ChatUsernameBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box(HiveKeys.Settings.name).listenable(keys: [
        SettingsKeys.TwitchUsernames.name,
        SettingsKeys.SelectedTwitchUsername.name
      ]),
      builder: (context, Box settingsBox, child) => Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Row(
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: 100.0),
                child: DropdownButton<String>(
                  value:
                      settingsBox.get(SettingsKeys.SelectedTwitchUsername.name),
                  isExpanded: true,
                  disabledHint: Text(
                    'No usernames',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                  items: settingsBox
                      .get(SettingsKeys.TwitchUsernames.name,
                          defaultValue: <String>[])
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
                    settingsBox.put(SettingsKeys.SelectedTwitchUsername.name,
                        twitchUsername);
                  },
                ),
              ),
            ),
            SizedBox(width: 32.0),
            UsernameActionRow(
              settingsBox: settingsBox,
            ),
          ],
        ),
      ),
    );
  }
}
