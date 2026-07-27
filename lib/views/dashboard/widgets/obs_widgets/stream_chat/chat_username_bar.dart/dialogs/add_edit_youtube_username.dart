import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../../shared/general/base/adaptive_text_field.dart';
import '../../../../../../../types/enums/settings_keys.dart';
import '../../../../../../../utils/youtube_video_id.dart';

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
      text: this
          .widget
          .settingsBox
          .get(SettingsKeys.YouTubeUsernames.name)?[this.widget.username],
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
    return this
            .widget
            .settingsBox
            .get(SettingsKeys.YouTubeUsernames.name,
                defaultValue: <String, String>{})
            .keys
            .contains(username)
        ? 'Username already exists'
        : null;
  }

  String? _youtubeLinkValidation(String? link) {
    if (link == null || link.isEmpty) {
      return 'Livestream video ID or link is required!';
    }
    if (extractYouTubeVideoId(link) == null) {
      return 'Could not find a YouTube video ID in that value';
    }
    return null;
  }

  void _handleUsername() {
    String username = _usernameController.text.trim();
    // Persist a bare video id when possible so older/brittle consumers stay safe.
    final videoId = extractYouTubeVideoId(_youtubeLinkController.text)!;

    Map<String, String> youtubeUsernames = Map<String, String>.from(
      (this.widget.settingsBox.get(
        SettingsKeys.YouTubeUsernames.name,
        defaultValue: <String, String>{},
      )),
    );
    if (this.widget.username != null) {
      youtubeUsernames.remove(this.widget.username);
    }
    youtubeUsernames.putIfAbsent(username, () => videoId);

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
            'For YouTube, provide the livestream video ID or a full watch / live / live_chat link. Example ID:\n\nm-i_0DcfF1s',
          ),
          const SizedBox(height: 12.0),
          BaseAdaptiveTextField(
            controller: _youtubeLinkController,
            placeholder: 'Video ID or YouTube link',
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
