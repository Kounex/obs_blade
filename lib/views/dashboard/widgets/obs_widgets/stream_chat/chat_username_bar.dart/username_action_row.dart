import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/dialogs/add_edit_owncast_username.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/dialogs/add_edit_youtube_username.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import 'delete_username_dialog.dart';
import 'dialogs/add_edit_twitch_username.dart';

/// WebView-mode username actions (add / edit / delete) for the selected
/// chat platform. The Twitch account chip used to live here - it moved to
/// `twitch_account_control.dart`, which owns the native engine mode.
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

    return Container(
      decoration: BoxDecoration(
        color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: 0.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _UsernameAction(
            icon: CupertinoIcons.person_add,
            tooltip: 'Add',
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
          const SizedBox(
            height: 20.0,
            child: VerticalDivider(width: 1.0, thickness: 0.0),
          ),
          _UsernameAction(
            icon: CupertinoIcons.pencil,
            tooltip: 'Edit',
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
          const SizedBox(
            height: 20.0,
            child: VerticalDivider(width: 1.0, thickness: 0.0),
          ),
          _UsernameAction(
            icon: CupertinoIcons.trash,
            tooltip: 'Delete',
            isDestructive: selectedChatUsername != null,
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
      ),
    );
  }
}

/// One segment of the username action control - icon button with [Pressable]
/// feedback; keeps the enabled / destructive color semantics of the old
/// text buttons.
class _UsernameAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDestructive;

  final void Function()? onPressed;

  const _UsernameAction({
    required this.icon,
    required this.tooltip,
    this.isDestructive = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabledColor = this.isDestructive
        ? CupertinoColors.destructiveRed
        : Theme.of(context).cupertinoOverrideTheme!.primaryColor;

    return Tooltip(
      message: this.tooltip,
      child: Pressable(
        onTap: this.onPressed,
        haptic: this.onPressed != null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Icon(
            this.icon,
            size: 18.0,
            color: this.onPressed != null
                ? enabledColor
                : Theme.of(context).disabledColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
