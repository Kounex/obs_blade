import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/dialogs/add_edit_owncast_username.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/dialogs/add_edit_youtube_username.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/general/themed/cupertino_button.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/modal_handler.dart';
import 'delete_username_dialog.dart';
import 'dialogs/add_edit_twitch_username.dart';

class UsernameActionRow extends StatelessWidget {
  final Box settingsBox;

  const UsernameActionRow({super.key, required this.settingsBox});

  @override
  Widget build(BuildContext context) {
    ChatType chatType = this.settingsBox.get(
          SettingsKeys.SelectedChatType.name,
          defaultValue: ChatType.Twitch,
        );
    String? selectedChatUsername = switch (chatType) {
      ChatType.Twitch =>
        this.settingsBox.get(SettingsKeys.SelectedTwitchUsername.name),
      ChatType.YouTube =>
        this.settingsBox.get(SettingsKeys.SelectedYouTubeUsername.name),
      ChatType.Owncast =>
        this.settingsBox.get(SettingsKeys.SelectedOwncastUsername.name),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ThemedCupertinoButton(
          padding: const EdgeInsets.all(0),
          text: 'Add',
          onPressed: () => ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: switch (chatType) {
              ChatType.Twitch =>
                AddEditTwitchUsernameDialog(settingsBox: this.settingsBox),
              ChatType.YouTube =>
                AddEditYouTubeUsernameDialog(settingsBox: this.settingsBox),
              ChatType.Owncast =>
                AddEditOwncastUsernameDialog(settingsBox: this.settingsBox),
            },
          ),
        ),
        const SizedBox(height: 15.0, child: VerticalDivider()),
        ThemedCupertinoButton(
          padding: const EdgeInsets.all(0),
          text: 'Edit',
          onPressed: selectedChatUsername != null
              ? () => ModalHandler.showBaseDialog(
                    context: context,
                    dialogWidget: switch (chatType) {
                      ChatType.Twitch => AddEditTwitchUsernameDialog(
                          settingsBox: this.settingsBox,
                          username: selectedChatUsername,
                        ),
                      ChatType.YouTube => AddEditYouTubeUsernameDialog(
                          settingsBox: this.settingsBox,
                          username: selectedChatUsername,
                        ),
                      ChatType.Owncast => AddEditOwncastUsernameDialog(
                          settingsBox: this.settingsBox,
                          username: selectedChatUsername,
                        ),
                    },
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
