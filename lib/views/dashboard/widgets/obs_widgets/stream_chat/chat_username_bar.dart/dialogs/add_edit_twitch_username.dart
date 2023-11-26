import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../../shared/general/base/adaptive_text_field.dart';
import '../../../../../../../types/enums/settings_keys.dart';

class AddEditTwitchUsernameDialog extends StatefulWidget {
  final Box settingsBox;
  final String? username;

  const AddEditTwitchUsernameDialog({
    Key? key,
    required this.settingsBox,
    this.username,
  }) : super(key: key);

  @override
  _AddEditTwitchUsernameDialogState createState() =>
      _AddEditTwitchUsernameDialogState();
}

class _AddEditTwitchUsernameDialogState
    extends State<AddEditTwitchUsernameDialog> {
  late CustomValidationTextEditingController _usernameController;

  @override
  void initState() {
    super.initState();

    _usernameController = CustomValidationTextEditingController(
      text: this.widget.username,
      check: _usernameValidation,
    );
  }

  String? _usernameValidation(String? username) {
    if (username == null || username.isEmpty) {
      return 'Please provide a username!';
    }
    if (this.widget.username != null && username == this.widget.username) {
      return null;
    }
    return this.widget.settingsBox.get(SettingsKeys.TwitchUsernames.name,
            defaultValue: <String>[]).contains(username)
        ? 'Username already exists'
        : null;
  }

  void _handleUsername() {
    String username = _usernameController.text.trim();

    List<String> twitchUsernames = this.widget.settingsBox.get(
      SettingsKeys.TwitchUsernames.name,
      defaultValue: <String>[],
    );
    if (this.widget.username == null) {
      twitchUsernames.add(username);
    } else {
      twitchUsernames[twitchUsernames.indexOf(this.widget.username!)] =
          username;
    }
    this.widget.settingsBox.put(
          SettingsKeys.TwitchUsernames.name,
          twitchUsernames,
        );
    this.widget.settingsBox.put(
          SettingsKeys.SelectedTwitchUsername.name,
          username,
        );
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title:
          '${(this.widget.username == null ? 'Add' : 'Edit')} Twitch Username',
      bodyWidget: Column(
        children: [
          const Text(
            'Add the name of a Twitch user to be able to view this user\'s chat. Make sure the name is spelled correctly because the name will be used to map it to the actual stream.',
          ),
          const SizedBox(height: 12.0),
          BaseAdaptiveTextField(
            controller: _usernameController,
            placeholder: 'Username',
          ),
        ],
      ),
      noText: 'Cancel',
      okText: 'Save',
      popDialogOnOk: false,
      onOk: (_) {
        _usernameController.submit();
        if (_usernameController.isValid) {
          _handleUsername();
          Navigator.of(context).pop();
        }
      },
    );
  }
}
