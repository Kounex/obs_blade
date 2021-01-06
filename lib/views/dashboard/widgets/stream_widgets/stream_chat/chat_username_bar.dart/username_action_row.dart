import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';
import 'package:obs_blade/shared/dialogs/input.dart';
import 'package:obs_blade/shared/general/themed/themed_cupertino_button.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/dashboard/widgets/stream_widgets/stream_chat/chat_username_bar.dart/add_edit_username_dialog.dart';
import 'package:obs_blade/views/dashboard/widgets/stream_widgets/stream_chat/chat_username_bar.dart/delete_username_dialog.dart';

class UsernameActionRow extends StatelessWidget {
  final Box settingsBox;

  UsernameActionRow({@required this.settingsBox}) : assert(settingsBox != null);

  @override
  Widget build(BuildContext context) {
    // List<String> twitchUsernames = this
    //     .settingsBox
    //     .get(SettingsKeys.TwitchUsernames.name, defaultValue: <String>[]);

    String selectedChatUsername = this.settingsBox.get(
                SettingsKeys.SelectedChatType.name,
                defaultValue: 'twitch') ==
            'twitch'
        ? this.settingsBox.get(SettingsKeys.SelectedTwitchUsername.name)
        : this.settingsBox.get(SettingsKeys.SelectedYoutubeUsername.name);

    return Row(
      children: [
        ThemedCupertinoButton(
          padding: EdgeInsets.all(0),
          text: 'Add',
          onPressed: () => ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: AddEditUsernameDialog(settingsBox: this.settingsBox),
          ),
        ),
        SizedBox(height: 15.0, child: VerticalDivider()),
        ThemedCupertinoButton(
          padding: EdgeInsets.all(0),
          text: 'Edit',
          onPressed: selectedChatUsername != null
              ? () => ModalHandler.showBaseDialog(
                    context: context,
                    dialogWidget: AddEditUsernameDialog(
                      settingsBox: this.settingsBox,
                      username: selectedChatUsername,
                    ),
                  )
              : null,
        ),
        SizedBox(height: 15.0, child: VerticalDivider()),
        ThemedCupertinoButton(
          padding: EdgeInsets.all(0),
          isDestructive: selectedChatUsername != null,
          text: 'Delete',
          onPressed: selectedChatUsername != null
              ? () => ModalHandler.showBaseDialog(
                    context: context,
                    dialogWidget: DeleteUsernameDialog(
                      settingsBox: settingsBox,
                      username: selectedChatUsername,
                    ),
                  )
              : null,
        ),
      ],
    );
  }
}
