import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../shared/general/validation_cupertino_textfield.dart';
import '../../../../../../types/enums/settings_keys.dart';

class AddEditUsernameDialog extends StatefulWidget {
  final Box settingsBox;
  final String username;

  AddEditUsernameDialog({
    @required this.settingsBox,
    this.username,
  });

  @override
  _AddEditUsernameDialogState createState() => _AddEditUsernameDialogState();
}

class _AddEditUsernameDialogState extends State<AddEditUsernameDialog> {
  CustomValidationTextEditingController _usernameController;
  CustomValidationTextEditingController _youtubeLinkController;

  String _chatType;

  @override
  void initState() {
    super.initState();

    _chatType = this
        .widget
        .settingsBox
        .get(SettingsKeys.SelectedChatType.name, defaultValue: 'twitch');

    _usernameController = CustomValidationTextEditingController(
      text: this.widget.username,
      check: (username) => _usernameValidation(_chatType, username),
    );
    _youtubeLinkController = CustomValidationTextEditingController(
      text: this.widget.settingsBox.get(SettingsKeys.SelectedChatType.name,
                      defaultValue: 'twitch') ==
                  'youtube' &&
              this.widget.username != null
          ? this
              .widget
              .settingsBox
              .get(SettingsKeys.YoutubeUsernames.name)[this.widget.username]
          : null,
      check: (link) => _youtubeLinkValidation(link),
    );
  }

  String _usernameValidation(String chatType, String username) {
    if (username == null || username.isEmpty)
      return 'Please provide a username!';
    if (this.widget.username != null && username == this.widget.username)
      return null;
    if (chatType.toLowerCase() == 'twitch') {
      return this.widget.settingsBox.get(SettingsKeys.TwitchUsernames.name,
              defaultValue: <String>[]).contains(username)
          ? 'Username already exists'
          : null;
    }
    if (chatType.toLowerCase() == 'youtube') {
      return this
              .widget
              .settingsBox
              .get(SettingsKeys.YoutubeUsernames.name,
                  defaultValue: <String, String>{})
              .keys
              .contains(username)
          ? 'Username already exists'
          : null;
    }
    return 'Unexpected Error';
  }

  String _youtubeLinkValidation(String link) {
    if (link == null || link.isEmpty) return 'Channel ID is required!';
    // if (link.contains('/watch?v=')) return 'Not a valid live stream link!';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    String chatTypeText = _chatType == 'twitch'
        ? 'Twitch'
        : _chatType == 'youtube'
            ? 'YouTube'
            : 'unknown';

    return ConfirmationDialog(
      title:
          '${(this.widget.username == null ? 'Add' : 'Edit')} $chatTypeText Username',
      bodyWidget: Column(
        children: [
          Text(
            'Add the name of a $chatTypeText user to be able to view this user\'s chat',
          ),
          SizedBox(height: 12.0),
          ValidationCupertinoTextfield(
            controller: _usernameController,
            placeholder: '$chatTypeText username',
          ),
          if (_chatType.toLowerCase() == 'youtube') ...[
            SizedBox(height: 8.0),
            Text(
                'For Youtube you also need to provide the Channel ID of the livestream - Usually at the end of the livestream link, for example:\n\nm-i_0DcfF1s'),
            SizedBox(height: 12.0),
            ValidationCupertinoTextfield(
              controller: _youtubeLinkController,
              placeholder: 'Youtube livestream link',
            ),
          ],
        ],
      ),
      noText: 'Cancel',
      okText: 'Save',
      popDialogOnOk: false,
      onOk: (_) {
        _usernameController.submit();
        _youtubeLinkController.submit();

        if (_usernameController.isValid &&
            (_chatType == 'youtube' ? _youtubeLinkController.isValid : true)) {
          if (_chatType.toLowerCase() == 'twitch') {
            List<String> twitchUsernames = this.widget.settingsBox.get(
                SettingsKeys.TwitchUsernames.name,
                defaultValue: <String>[]);
            if (this.widget.username == null) {
              twitchUsernames.add(_usernameController.text);
            } else {
              twitchUsernames[twitchUsernames.indexOf(this.widget.username)] =
                  _usernameController.text;
            }
            this
                .widget
                .settingsBox
                .put(SettingsKeys.TwitchUsernames.name, twitchUsernames);
            this.widget.settingsBox.put(
                SettingsKeys.SelectedTwitchUsername.name,
                _usernameController.text);
          } else if (_chatType.toLowerCase() == 'youtube') {
            Map<String, String> youtubeUsernames = Map<String, String>.from(
                (this.widget.settingsBox.get(SettingsKeys.YoutubeUsernames.name,
                    defaultValue: <String, String>{})));
            if (this.widget.username != null) {
              youtubeUsernames.remove(this.widget.username);
            }
            youtubeUsernames.putIfAbsent(
                _usernameController.text, () => _youtubeLinkController.text);
            this
                .widget
                .settingsBox
                .put(SettingsKeys.YoutubeUsernames.name, youtubeUsernames);
            this.widget.settingsBox.put(
                SettingsKeys.SelectedYoutubeUsername.name,
                _usernameController.text);
          }
          Navigator.of(context).pop();
        }
      },
    );
  }
}
