import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../../shared/general/base/adaptive_text_field.dart';
import '../../../../../../../types/enums/settings_keys.dart';
import '../../../../../../../utils/youtube/youtube_entry_name.dart';
import '../../../../../../../utils/youtube_target.dart';

class AddEditYouTubeUsernameDialog extends StatefulWidget {
  final Box settingsBox;
  final String? username;

  /// Derives the label when the name field is left empty (test seam).
  final YouTubeEntryNamer? namer;

  const AddEditYouTubeUsernameDialog({
    super.key,
    required this.settingsBox,
    this.username,
    this.namer,
  });

  @override
  _AddEditYouTubeUsernameDialogState createState() =>
      _AddEditYouTubeUsernameDialogState();
}

class _AddEditYouTubeUsernameDialogState
    extends State<AddEditYouTubeUsernameDialog> {
  late CustomValidationTextEditingController _usernameController;
  late CustomValidationTextEditingController _youtubeLinkController;

  /// Auto-name lookup in flight — Save is inert meanwhile.
  bool _saving = false;

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

  /// Optional: an empty name is derived from the channel / stream on
  /// save ([YouTubeEntryNamer]).
  String? _usernameValidation(String? username) {
    if (username == null || username.trim().isEmpty) return null;
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

  Future<void> _handleUsername() async {
    final target = parseYouTubeTarget(_youtubeLinkController.text)!;

    /// Persist the normalized form: `@handle` / `UC…` for channels, a bare
    /// video id for single streams (what older builds stored).
    final value = target.storageValue;

    Map<String, String> youtubeUsernames = Map<String, String>.from(
      (this.widget.settingsBox.get(
        SettingsKeys.YouTubeUsernames.name,
        defaultValue: <String, String>{},
      )),
    );
    if (this.widget.username != null) {
      youtubeUsernames.remove(this.widget.username);
    }

    var username = _usernameController.text.trim();
    if (username.isEmpty) {
      username = uniqueYouTubeEntryLabel(
        await (this.widget.namer ?? YouTubeEntryNamer()).nameFor(target),
        youtubeUsernames.keys,
      );
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
      title: '${(this.widget.username == null ? 'Add' : 'Edit')} YouTube Chat',
      bodyWidget: Column(
        children: [
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
          const SizedBox(height: 8.0),
          const Text('Name (optional) - leave empty to use the channel name.'),
          const SizedBox(height: 12.0),
          BaseAdaptiveTextField(
            controller: _usernameController,
            placeholder: 'Name (optional)',
          ),
        ],
      ),
      noText: 'Cancel',
      okText: 'Save',
      popDialogOnOk: false,
      onOk: (_) async {
        if (this._saving) return;
        _usernameController.submit();
        _youtubeLinkController.submit();

        if (_usernameController.isValid && _youtubeLinkController.isValid) {
          final navigator = Navigator.of(context);
          this._saving = true;
          await _handleUsername();
          navigator.pop();
        }
      },
    );
  }
}
