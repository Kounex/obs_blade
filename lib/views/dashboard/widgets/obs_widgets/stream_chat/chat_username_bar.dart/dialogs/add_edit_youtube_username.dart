import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../../shared/general/base/adaptive_text_field.dart';
import '../../../../../../../types/enums/settings_keys.dart';
import '../../../../../../../utils/youtube_target.dart';

class AddEditYouTubeUsernameDialog extends StatefulWidget {
  final Box settingsBox;
  final String? username;

  const AddEditYouTubeUsernameDialog({
    super.key,
    required this.settingsBox,
    this.username,
  });

  @override
  _AddEditYouTubeUsernameDialogState createState() =>
      _AddEditYouTubeUsernameDialogState();
}

class _AddEditYouTubeUsernameDialogState
    extends State<AddEditYouTubeUsernameDialog> {
  late CustomValidationTextEditingController _usernameController;
  late CustomValidationTextEditingController _youtubeLinkController;

  @override
  void initState() {
    super.initState();

    _usernameController = CustomValidationTextEditingController(
      text: this.widget.username,
      check: _usernameValidation,
    );
    _youtubeLinkController = CustomValidationTextEditingController(
      text: this.widget.settingsBox.get(
        SettingsKeys.YouTubeUsernames.name,
      )?[this.widget.username],
      check: _youtubeLinkValidation,
    );
  }

  String? _usernameValidation(String? username) {
    if (username == null || username.isEmpty) {
      return 'Please provide a username!';
    }
    if (this.widget.username != null && username == this.widget.username) {
      return null;
    }
    return this.widget.settingsBox
            .get(
              SettingsKeys.YouTubeUsernames.name,
              defaultValue: <String, String>{},
            )
            .keys
            .contains(username)
        ? 'Username already exists'
        : null;
  }

  String? _youtubeLinkValidation(String? link) {
    if (link == null || link.isEmpty) {
      return 'A channel or livestream is required!';
    }
    if (parseYouTubeTarget(link) == null) {
      return 'Could not find a YouTube channel or video in that value';
    }
    return null;
  }

  void _handleUsername() {
    String username = _usernameController.text.trim();

    /// Persist the normalized form: `@handle` / `UC…` for channels, a bare
    /// video id for single streams (what older builds stored).
    final value = parseYouTubeTarget(_youtubeLinkController.text)!.storageValue;

    Map<String, String> youtubeUsernames = Map<String, String>.from(
      (this.widget.settingsBox.get(
        SettingsKeys.YouTubeUsernames.name,
        defaultValue: <String, String>{},
      )),
    );
    if (this.widget.username != null) {
      youtubeUsernames.remove(this.widget.username);
    }
    youtubeUsernames.putIfAbsent(username, () => value);

    this.widget.settingsBox.put(
      SettingsKeys.YouTubeUsernames.name,
      youtubeUsernames,
    );
    this.widget.settingsBox.put(
      SettingsKeys.SelectedYouTubeUsername.name,
      username,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title:
          '${(this.widget.username == null ? 'Add' : 'Edit')} YouTube Username',
      bodyWidget: Column(
        children: [
          const Text(
            'Add the name of a YouTube user to be able to view this user\'s chat',
          ),
          const SizedBox(height: 12.0),
          BaseAdaptiveTextField(
            controller: _usernameController,
            placeholder: 'Username',
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Enter the channel (@handle or channel link) to always follow its '
            'current livestream - the chat switches to the next stream on its '
            'own. A video ID or stream link pins one specific stream instead.',
          ),
          const SizedBox(height: 12.0),
          BaseAdaptiveTextField(
            controller: _youtubeLinkController,
            placeholder: '@handle, channel or stream link',
          ),
        ],
      ),
      noText: 'Cancel',
      okText: 'Save',
      popDialogOnOk: false,
      onOk: (_) {
        _usernameController.submit();
        _youtubeLinkController.submit();

        if (_usernameController.isValid && _youtubeLinkController.isValid) {
          _handleUsername();
          Navigator.of(context).pop();
        }
      },
    );
  }
}
