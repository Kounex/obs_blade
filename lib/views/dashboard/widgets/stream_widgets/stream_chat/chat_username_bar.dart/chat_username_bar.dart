import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import 'chat_type_dropdown.dart';
import 'username_action_row.dart';
import 'username_dropdown.dart';

class ChatUsernameBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box(HiveKeys.Settings.name).listenable(keys: [
        SettingsKeys.SelectedChatType.name,
        SettingsKeys.TwitchUsernames.name,
        SettingsKeys.SelectedTwitchUsername.name,
        SettingsKeys.YoutubeUsernames.name,
        SettingsKeys.SelectedYoutubeUsername.name,
      ]),
      builder: (context, Box settingsBox, child) => Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChatTypeDropdown(settingsBox: settingsBox),
            Row(
              children: [
                UsernameDropdown(
                  settingsBox: settingsBox,
                ),
                SizedBox(width: 32.0),
                UsernameActionRow(
                  settingsBox: settingsBox,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
