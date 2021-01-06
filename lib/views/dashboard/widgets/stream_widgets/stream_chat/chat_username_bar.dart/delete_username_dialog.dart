import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

class DeleteUsernameDialog extends StatelessWidget {
  final Box settingsBox;
  final String username;

  DeleteUsernameDialog({@required this.settingsBox, @required this.username});

  @override
  Widget build(BuildContext context) {
    String chatType = this
        .settingsBox
        .get(SettingsKeys.SelectedChatType.name, defaultValue: 'twitch');

    String chatTypeText = chatType == 'twitch'
        ? 'Twitch'
        : chatType == 'youtube'
            ? 'YouTube'
            : 'unknown';

    return ConfirmationDialog(
      title: 'Delete $chatTypeText Username',
      body:
          'Are you sure you want to delete the currently selected $chatTypeText username? This action can\'t be undone!',
      isYesDestructive: true,
      onOk: (_) {
        if (chatType.toLowerCase() == 'twitch') {
          List<String> twitchUsernames = this
              .settingsBox
              .get(SettingsKeys.TwitchUsernames.name, defaultValue: <String>[]);
          twitchUsernames.removeAt(twitchUsernames.indexOf(this.username));
          this
              .settingsBox
              .put(SettingsKeys.TwitchUsernames.name, twitchUsernames);
          this.settingsBox.put(SettingsKeys.SelectedTwitchUsername.name,
              twitchUsernames.length > 0 ? twitchUsernames.last : null);
        } else if (chatType.toLowerCase() == 'youtube') {
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
              youtubeUsernames.length > 0
                  ? youtubeUsernames[youtubeUsernames.keys.last]
                  : null);
        }
      },
    );
  }
}
