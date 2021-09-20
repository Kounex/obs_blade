import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../types/enums/settings_keys.dart';

class DeleteUsernameDialog extends StatelessWidget {
  final Box settingsBox;
  final String username;

  const DeleteUsernameDialog(
      {Key? key, required this.settingsBox, required this.username})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    ChatType chatType = this
        .settingsBox
        .get(SettingsKeys.SelectedChatType.name, defaultValue: ChatType.Twitch);

    return ConfirmationDialog(
      title: 'Delete ${chatType.text} Username',
      body:
          'Are you sure you want to delete the currently selected ${chatType.text} username? This action can\'t be undone!',
      isYesDestructive: true,
      onOk: (_) {
        if (chatType == ChatType.Twitch) {
          List<String> twitchUsernames = this
              .settingsBox
              .get(SettingsKeys.TwitchUsernames.name, defaultValue: <String>[]);
          twitchUsernames.removeAt(twitchUsernames.indexOf(this.username));
          this
              .settingsBox
              .put(SettingsKeys.TwitchUsernames.name, twitchUsernames);
          this.settingsBox.put(SettingsKeys.SelectedTwitchUsername.name,
              twitchUsernames.isNotEmpty ? twitchUsernames.last : null);
        } else if (chatType == ChatType.YouTube) {
          Map<String, String> youtubeUsernames = Map<String, String>.from((this
              .settingsBox
              .get(SettingsKeys.YoutubeUsernames.name,
                  defaultValue: <String, String>{})));
          youtubeUsernames.remove(this.username);
          this
              .settingsBox
              .put(SettingsKeys.YoutubeUsernames.name, youtubeUsernames);
          this.settingsBox.put(
              SettingsKeys.SelectedYoutubeUsername.name,
              youtubeUsernames.isNotEmpty
                  ? youtubeUsernames[youtubeUsernames.keys.last]
                  : null);
        }
      },
    );
  }
}
