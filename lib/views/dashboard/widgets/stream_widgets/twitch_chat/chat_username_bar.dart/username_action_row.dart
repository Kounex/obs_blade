import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/models/settings.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/shared/dialogs/input.dart';
import 'package:obs_blade/utils/dialog_handler.dart';

class UsernameActionRow extends StatelessWidget {
  final Settings settings;
  final Box<String> twitchUsernamesBox;

  UsernameActionRow(
      {@required this.settings, @required this.twitchUsernamesBox})
      : assert(settings != null && twitchUsernamesBox != null);

  @override
  Widget build(BuildContext context) {
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
                      : this
                              .twitchUsernamesBox
                              .values
                              .contains(enteredTwitchUsername)
                          ? 'Username already added!'
                          : null,
              onSave: (newTwitchUsername) {
                this.twitchUsernamesBox.add(newTwitchUsername);
                this.settings.selectedTwitchUsername = newTwitchUsername;
                this.settings.save();
              },
            ),
          ),
        ),
        SizedBox(height: 15.0, child: VerticalDivider()),
        CupertinoButton(
          padding: EdgeInsets.all(0),
          child: Text('Edit'),
          onPressed: () => DialogHandler.showBaseDialog(
            context: context,
            dialogWidget: InputDialog(
              title: 'Edit Twitch Username',
              body: 'Change the currently selected Twitch Username',
              inputPlaceholder: settings.selectedTwitchUsername,
              inputCheck: (enteredTwitchUsername) =>
                  enteredTwitchUsername.length == 0
                      ? 'Please enter a username!'
                      : enteredTwitchUsername !=
                                  settings.selectedTwitchUsername &&
                              this
                                  .twitchUsernamesBox
                                  .values
                                  .contains(enteredTwitchUsername)
                          ? 'Username already added!'
                          : null,
              onSave: (editedTwitchUsername) {
                // this.twitchUsernamesBox.values.firstWhere((twitchUserName) =>
                //     twitchUserName == settings.selectedTwitchUsername);
                // this.twitchUsernamesBox.add(twitchUsername);
                // this.settings.selectedTwitchUsername = twitchUsername;
                // this.settings.save();
              },
            ),
          ),
        ),
        SizedBox(height: 15.0, child: VerticalDivider()),
        CupertinoButton(
          padding: EdgeInsets.all(0),
          child: Text(
            'Delete',
            style: TextStyle(color: CupertinoColors.destructiveRed),
          ),
          onPressed: () => DialogHandler.showBaseDialog(
            context: context,
            dialogWidget: ConfirmationDialog(
              title: 'Delete Twitch Username',
              body:
                  'Are you sure you want to delete the currently selected Twitch Username? This action can\'t be undone!',
              isYesDestructive: true,
              onOk: () {
                twitchUsernamesBox.deleteAt(twitchUsernamesBox.values
                    .toList()
                    .indexOf(settings.selectedTwitchUsername));
                settings.selectedTwitchUsername =
                    twitchUsernamesBox.values.length > 0
                        ? twitchUsernamesBox
                            .get(twitchUsernamesBox.values.length - 1)
                        : null;
              },
            ),
          ),
        ),
      ],
    );
  }
}
