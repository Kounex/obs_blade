import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../types/enums/settings_keys.dart';

class UsernameDropdown extends StatelessWidget {
  final Box settingsBox;

  const UsernameDropdown({Key? key, required this.settingsBox})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    ChatType chatType = this
        .settingsBox
        .get(SettingsKeys.SelectedChatType.name, defaultValue: ChatType.Twitch);

    return Flexible(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 100.0),
        child: DropdownButton<String>(
          value: chatType == ChatType.Twitch
              ? settingsBox.get(SettingsKeys.SelectedTwitchUsername.name)
              : settingsBox.get(SettingsKeys.SelectedYoutubeUsername.name),
          isExpanded: true,
          disabledHint: const Text(
            'No usernames',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
          items: (chatType == ChatType.Twitch
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
                chatType == ChatType.Twitch
                    ? SettingsKeys.SelectedTwitchUsername.name
                    : SettingsKeys.SelectedYoutubeUsername.name,
                chatUsername);
          },
        ),
      ),
    );
  }
}
