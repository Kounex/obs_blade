import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../../types/enums/settings_keys.dart';

class UsernameDropdown extends StatelessWidget {
  final Box settingsBox;

  UsernameDropdown({@required this.settingsBox});

  @override
  Widget build(BuildContext context) {
    String chatType = this
        .settingsBox
        .get(SettingsKeys.SelectedChatType.name, defaultValue: 'twitch');

    return Flexible(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 100.0),
        child: DropdownButton<String>(
          value: chatType.toLowerCase() == 'twitch'
              ? settingsBox.get(SettingsKeys.SelectedTwitchUsername.name)
              : settingsBox.get(SettingsKeys.SelectedYoutubeUsername.name),
          isExpanded: true,
          disabledHint: Text(
            'No usernames',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
          items: (chatType.toLowerCase() == 'twitch'
                  ? settingsBox.get(SettingsKeys.TwitchUsernames.name,
                      defaultValue: <String>[])
                  : settingsBox.get(SettingsKeys.YoutubeUsernames.name,
                      defaultValue: <String, String>{}).keys)
              .map<DropdownMenuItem<String>>(
                (chatUsername) => DropdownMenuItem<String>(
                  value: chatUsername,
                  child: Text(
                    chatUsername,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                ),
              )
              .toList(),
          onChanged: (chatUsername) {
            settingsBox.put(
                chatType.toLowerCase() == 'twitch'
                    ? SettingsKeys.SelectedTwitchUsername.name
                    : SettingsKeys.SelectedYoutubeUsername.name,
                chatUsername);
          },
        ),
      ),
    );
  }
}
