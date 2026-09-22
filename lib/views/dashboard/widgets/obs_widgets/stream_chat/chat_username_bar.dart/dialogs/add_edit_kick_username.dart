import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../../shared/general/base/adaptive_text_field.dart';
import '../../../../../../../types/enums/settings_keys.dart';
import '../../../../../../../utils/kick_channel_slug.dart';

class AddEditKickUsernameDialog extends StatefulWidget {
  final Box settingsBox;
  final String? username;

  const AddEditKickUsernameDialog({
    super.key,
    required this.settingsBox,
    this.username,
  });

  @override
  _AddEditKickUsernameDialogState createState() =>
      _AddEditKickUsernameDialogState();
}

class _AddEditKickUsernameDialogState
    extends State<AddEditKickUsernameDialog> {
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
      return 'Please provide a channel!';
    }
    final slug = extractKickChannelSlug(username);
    if (slug == null) {
      return 'Could not find a Kick channel in that value';
    }
    if (this.widget.username != null && slug == this.widget.username) {
      return null;
    }
    return this.widget.settingsBox
            .get(SettingsKeys.KickUsernames.name, defaultValue: <String>[])
            .contains(slug)
        ? 'Channel already exists'
        : null;
  }

  void _handleUsername() {
    final slug = extractKickChannelSlug(_usernameController.text)!;

    List<String> kickUsernames = List<String>.from(
      this.widget.settingsBox.get(
        SettingsKeys.KickUsernames.name,
        defaultValue: <String>[],
      ),
    );
    if (this.widget.username == null) {
      kickUsernames.add(slug);
    } else {
      kickUsernames[kickUsernames.indexOf(this.widget.username!)] = slug;
    }
    this.widget.settingsBox.put(SettingsKeys.KickUsernames.name, kickUsernames);
    this.widget.settingsBox.put(
      SettingsKeys.SelectedKickUsername.name,
      slug,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: '${(this.widget.username == null ? 'Add' : 'Edit')} Kick Channel',
      bodyWidget: Column(
        children: [
          const Text(
            'Add a Kick channel to view its chat. Paste the channel name or a kick.com link (channel page or pop-out chat) - the slug gets extracted either way.',
          ),
          const SizedBox(height: 12.0),
          BaseAdaptiveTextField(
            controller: _usernameController,
            placeholder: 'Channel or kick.com link',
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
