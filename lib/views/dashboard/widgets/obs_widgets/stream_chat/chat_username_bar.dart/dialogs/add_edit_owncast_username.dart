import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../../shared/general/base/adaptive_text_field.dart';
import '../../../../../../../types/enums/settings_keys.dart';

class AddEditOwncastUsernameDialog extends StatefulWidget {
  final Box settingsBox;
  final String? username;

  const AddEditOwncastUsernameDialog({
    super.key,
    required this.settingsBox,
    this.username,
  });

  @override
  _AddEditOwncastUsernameDialogState createState() =>
      _AddEditOwncastUsernameDialogState();
}

class _AddEditOwncastUsernameDialogState
    extends State<AddEditOwncastUsernameDialog> {
  late CustomValidationTextEditingController _usernameController;
  late CustomValidationTextEditingController _owncastDomainController;

  @override
  void initState() {
    super.initState();

    _usernameController = CustomValidationTextEditingController(
      text: this.widget.username,
      check: _usernameValidation,
    );
    _owncastDomainController = CustomValidationTextEditingController(
      text: this
          .widget
          .settingsBox
          .get(SettingsKeys.OwncastUsernames.name)?[this.widget.username],
      check: _owncastDomainValidation,
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
            .get(SettingsKeys.OwncastUsernames.name,
                defaultValue: <String, String>{})
            .keys
            .contains(username)
        ? 'Username already exists'
        : null;
  }

  String? _owncastDomainValidation(String? link) {
    if (link == null || link.isEmpty) return 'Domain is required!';
    return null;
  }

  void _handleUsername() {
    /// Trim and remove all trailing slashes
    String username = _usernameController.text.trim();
    String domain =
        _owncastDomainController.text.trim().replaceAll(RegExp(r'\/+$'), '');

    Map<String, String> owncastUsernames = Map<String, String>.from(
      (this.widget.settingsBox.get(
        SettingsKeys.OwncastUsernames.name,
        defaultValue: <String, String>{},
      )),
    );
    if (this.widget.username != null) {
      owncastUsernames.remove(this.widget.username);
    }
    owncastUsernames.putIfAbsent(username, () => domain);

    this.widget.settingsBox.put(
          SettingsKeys.OwncastUsernames.name,
          owncastUsernames,
        );
    this.widget.settingsBox.put(
          SettingsKeys.SelectedOwncastUsername.name,
          username,
        );
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title:
          '${(this.widget.username == null ? 'Add' : 'Edit')} Owncast Username',
      bodyWidget: Column(
        children: [
          const Text(
            'Add the name of a Owncast user to be able to view this user\'s chat',
          ),
          const SizedBox(height: 12.0),
          BaseAdaptiveTextField(
            controller: _usernameController,
            placeholder: 'Username',
          ),
          const SizedBox(height: 8.0),
          const Text(
              'For Owncast you need to provide the domain you are using, like\n"https://example.com"'),
          const SizedBox(height: 12.0),
          BaseAdaptiveTextField(
            controller: _owncastDomainController,
            placeholder: 'Owncast domain',
          ),
        ],
      ),
      noText: 'Cancel',
      okText: 'Save',
      popDialogOnOk: false,
      onOk: (_) {
        _usernameController.submit();
        _owncastDomainController.submit();

        if (_usernameController.isValid && _owncastDomainController.isValid) {
          _handleUsername();
          Navigator.of(context).pop();
        }
      },
    );
  }
}
