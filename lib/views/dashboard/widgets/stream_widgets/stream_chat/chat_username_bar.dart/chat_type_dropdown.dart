import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/icons/jam_icons.dart';

class ChatTypeDropdown extends StatelessWidget {
  final Box settingsBox;

  ChatTypeDropdown({@required this.settingsBox});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: this
          .settingsBox
          .get(SettingsKeys.SelectedChatType.name, defaultValue: 'Twitch'),
      items: [
        DropdownMenuItem(
          value: 'Twitch',
          child: Row(
            children: [
              Icon(JamIcons.twitch),
              SizedBox(width: 12.0),
              Text('Twitch'),
              SizedBox(width: 8.0),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'Youtube',
          child: Row(
            children: [
              Icon(JamIcons.youtube),
              SizedBox(width: 12.0),
              Text('Youtube'),
              SizedBox(width: 8.0),
            ],
          ),
        ),
      ],
      onChanged: (chatType) =>
          this.settingsBox.put(SettingsKeys.SelectedChatType.name, chatType),
    );
  }
}
