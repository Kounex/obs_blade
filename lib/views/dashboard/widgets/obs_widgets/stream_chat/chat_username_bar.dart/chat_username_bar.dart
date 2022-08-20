import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../../shared/general/hive_builder.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import 'chat_type_dropdown.dart';
import 'username_action_row.dart';
import 'username_dropdown.dart';

class ChatUsernameBar extends StatelessWidget {
  const ChatUsernameBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.SelectedChatType,
        SettingsKeys.TwitchUsernames,
        SettingsKeys.SelectedTwitchUsername,
        SettingsKeys.YoutubeUsernames,
        SettingsKeys.SelectedYoutubeUsername,
      ],
      builder: (context, settingsBox, child) => Padding(
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
                const SizedBox(width: 32.0),
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
