import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/shared/dialogs/input.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/dialog_handler.dart';

class UsernameActionRow extends StatelessWidget {
  final Box settingsBox;

  UsernameActionRow({@required this.settingsBox}) : assert(settingsBox != null);

  @override
  Widget build(BuildContext context) {
    List<String> twitchUsernames = this
        .settingsBox
        .get(SettingsKeys.TwitchUsernames.name, defaultValue: <String>[]);

    String selectedTwitchUsername =
        this.settingsBox.get(SettingsKeys.SelectedTwitchUsername.name);

    return Row(
      children: [
        CupertinoButton(
          padding: EdgeInsets.all(0),
          child: Text('Add'),
          onPressed: () => DialogHandler.showBaseDialog(
            context: context,
            dialogWidget: InputDialog(
              title: 'New Twitch Username',
              body:
                  'Add the name of a Twitch user to be able to view this user\'s chat',
              inputPlaceholder: 'Twitch Username',
              inputCheck: (enteredTwitchUsername) =>
                  enteredTwitchUsername.length == 0
                      ? 'Please enter a username!'
                      : twitchUsernames.contains(enteredTwitchUsername)
                          ? 'Username already added!'
                          : null,
              onSave: (newTwitchUsername) {
                this.settingsBox.put(SettingsKeys.TwitchUsernames.name,
                    [...twitchUsernames, newTwitchUsername]);
                this.settingsBox.put(SettingsKeys.SelectedTwitchUsername.name,
                    newTwitchUsername);
              },
            ),
          ),
        ),
        SizedBox(height: 15.0, child: VerticalDivider()),
        CupertinoButton(
          padding: EdgeInsets.all(0),
          child: Text('Edit'),
          onPressed: selectedTwitchUsername != null
              ? () => DialogHandler.showBaseDialog(
                    context: context,
                    dialogWidget: InputDialog(
                      title: 'Edit Twitch Username',
                      body: 'Change the currently selected Twitch Username',
                      inputText: selectedTwitchUsername,
                      inputCheck: (enteredTwitchUsername) =>
                          enteredTwitchUsername.length == 0
                              ? 'Please enter a username!'
                              : enteredTwitchUsername !=
                                          selectedTwitchUsername &&
                                      twitchUsernames
                                          .contains(enteredTwitchUsername)
                                  ? 'Username already added!'
                                  : null,
                      onSave: (editedTwitchUsername) {
                        if (editedTwitchUsername != selectedTwitchUsername) {
                          twitchUsernames[twitchUsernames.indexOf(
                              selectedTwitchUsername)] = editedTwitchUsername;
                          this.settingsBox.put(
                              SettingsKeys.TwitchUsernames.name,
                              twitchUsernames);
                          this.settingsBox.put(
                              SettingsKeys.SelectedTwitchUsername.name,
                              editedTwitchUsername);
                        }
                      },
                    ),
                  )
              : null,
        ),
        SizedBox(height: 15.0, child: VerticalDivider()),
        CupertinoButton(
          padding: EdgeInsets.all(0),
          child: Text(
            'Delete',
            style: selectedTwitchUsername != null
                ? TextStyle(color: CupertinoColors.destructiveRed)
                : null,
          ),
          onPressed: selectedTwitchUsername != null
              ? () => DialogHandler.showBaseDialog(
                    context: context,
                    dialogWidget: ConfirmationDialog(
                      title: 'Delete Twitch Username',
                      body:
                          'Are you sure you want to delete the currently selected Twitch Username? This action can\'t be undone!',
                      isYesDestructive: true,
                      onOk: () {
                        twitchUsernames.removeAt(
                            twitchUsernames.indexOf(selectedTwitchUsername));
                        this.settingsBox.put(
                            SettingsKeys.TwitchUsernames.name, twitchUsernames);
                        this.settingsBox.put(
                            SettingsKeys.SelectedTwitchUsername.name,
                            twitchUsernames.length > 0
                                ? twitchUsernames[twitchUsernames.length - 1]
                                : null);
                      },
                    ),
                  )
              : null,
        ),
      ],
    );
  }
}
