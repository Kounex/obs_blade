import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../types/enums/settings_keys.dart';

class UsernameDropdown extends StatelessWidget {
  final Box settingsBox;

  const UsernameDropdown({super.key, required this.settingsBox});

  @override
  Widget build(BuildContext context) {
    ChatType chatType = this.settingsBox.get(
          SettingsKeys.SelectedChatType.name,
          defaultValue: ChatType.Twitch,
        );

    return Flexible(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 100.0),
        child: DropdownButton<String>(
          value: switch (chatType) {
            ChatType.Twitch =>
              settingsBox.get(SettingsKeys.SelectedTwitchUsername.name),
            ChatType.YouTube =>
              settingsBox.get(SettingsKeys.SelectedYouTubeUsername.name),
            ChatType.Owncast =>
              settingsBox.get(SettingsKeys.SelectedOwncastUsername.name),
          },
          isExpanded: true,
          disabledHint: const Text(
            'No usernames',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
          items: switch (chatType) {
            ChatType.Twitch => settingsBox.get(
                SettingsKeys.TwitchUsernames.name,
                defaultValue: <String>[]),
            ChatType.YouTube => settingsBox.get(
                SettingsKeys.YouTubeUsernames.name,
                defaultValue: <String, String>{}).keys,
            ChatType.Owncast => settingsBox.get(
                SettingsKeys.OwncastUsernames.name,
                defaultValue: <String, String>{}).keys,
          }
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
              switch (chatType) {
                ChatType.Twitch => SettingsKeys.SelectedTwitchUsername.name,
                ChatType.YouTube => SettingsKeys.SelectedYouTubeUsername.name,
                ChatType.Owncast => SettingsKeys.SelectedOwncastUsername.name,
              },
              chatUsername,
            );
          },
        ),
      ),
    );
  }
}
