import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../../models/settings.dart';
import '../../../../../../types/enums/hive_keys.dart';
import 'username_action_row.dart';

class ChatUsernameBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Settings settings = Hive.box<Settings>(HiveKeys.Settings.name).get(0);
    Box<String> twitchUsernamesBox =
        Hive.box<String>(HiveKeys.TwitchUsernames.name);

    print(settings.selectedTwitchUsername);
    print(twitchUsernamesBox.values);

    return ValueListenableBuilder(
      valueListenable: twitchUsernamesBox.listenable(),
      builder: (context, Box<String> twitchUsernamesBox, child) => Row(
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: 100.0),
              child: DropdownButton<String>(
                value: settings.selectedTwitchUsername,
                isExpanded: true,
                disabledHint: Text(
                  'No usernames',
                  overflow: TextOverflow.ellipsis,
                ),
                items: twitchUsernamesBox.values
                    .map(
                      (twitchUsername) => DropdownMenuItem<String>(
                        value: twitchUsername,
                        child: Text(twitchUsername),
                      ),
                    )
                    .toList(),
                onChanged: (twitchUsername) {
                  settings.selectedTwitchUsername = twitchUsername;
                  settings.save();
                },
              ),
            ),
          ),
          SizedBox(width: 32.0),
          UsernameActionRow(
            settings: settings,
            twitchUsernamesBox: twitchUsernamesBox,
          ),
        ],
      ),
    );
  }
}
