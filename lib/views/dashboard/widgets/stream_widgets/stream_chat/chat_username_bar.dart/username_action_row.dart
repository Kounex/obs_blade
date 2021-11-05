import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/general/themed/cupertino_button.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/modal_handler.dart';
import 'add_edit_username_dialog.dart';
import 'delete_username_dialog.dart';

class UsernameActionRow extends StatelessWidget {
  final Box settingsBox;

  const UsernameActionRow({Key? key, required this.settingsBox})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? selectedChatUsername = this.settingsBox.get(
                SettingsKeys.SelectedChatType.name,
                defaultValue: ChatType.Twitch) ==
            ChatType.Twitch
        ? this.settingsBox.get(SettingsKeys.SelectedTwitchUsername.name)
        : this.settingsBox.get(SettingsKeys.SelectedYoutubeUsername.name);

    return Row(
      children: [
        ThemedCupertinoButton(
          padding: const EdgeInsets.all(0),
          text: 'Add',
          onPressed: () => ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: AddEditUsernameDialog(settingsBox: this.settingsBox),
          ),
        ),
        const SizedBox(height: 15.0, child: VerticalDivider()),
        ThemedCupertinoButton(
          padding: const EdgeInsets.all(0),
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
        const SizedBox(height: 15.0, child: VerticalDivider()),
        ThemedCupertinoButton(
          padding: const EdgeInsets.all(0),
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
