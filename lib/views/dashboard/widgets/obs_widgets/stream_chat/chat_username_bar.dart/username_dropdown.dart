import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/styling_helper.dart';

class UsernameDropdown extends StatelessWidget {
  final Box settingsBox;

  const UsernameDropdown({super.key, required this.settingsBox});

  @override
  Widget build(BuildContext context) {
    ChatType chatType = this.settingsBox.get(
          SettingsKeys.SelectedChatType.name,
          defaultValue: ChatType.Twitch,
        );

    final List<DropdownMenuItem<String>> usernameItems = switch (chatType) {
      ChatType.Twitch => settingsBox.get(SettingsKeys.TwitchUsernames.name,
          defaultValue: <String>[]),
      ChatType.YouTube => settingsBox.get(SettingsKeys.YouTubeUsernames.name,
          defaultValue: <String, String>{}).keys,
      ChatType.Owncast => settingsBox.get(SettingsKeys.OwncastUsernames.name,
          defaultValue: <String, String>{}).keys,
    }
        .map<DropdownMenuItem<String>>(
          (chatUsername) => DropdownMenuItem<String>(
            value: chatUsername,
            child: Text(
              chatUsername,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ),
        )
        .toList();

    return Flexible(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 100.0),
        child: Container(
          decoration: BoxDecoration(
            color:
                StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
              width: 0.0,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: DropdownButton<String>(
                value: switch (chatType) {
                  ChatType.Twitch =>
                    settingsBox.get(SettingsKeys.SelectedTwitchUsername.name),
                  ChatType.YouTube =>
                    settingsBox.get(SettingsKeys.SelectedYouTubeUsername.name),
                  ChatType.Owncast =>
                    settingsBox.get(SettingsKeys.SelectedOwncastUsername.name),
                },
                isExpanded: true,
                isDense: true,
                borderRadius: BorderRadius.circular(AppRadius.md),

                /// No chevron when there is nothing to pick
                icon: usernameItems.isEmpty
                    ? const SizedBox.shrink()
                    : const Icon(Icons.arrow_drop_down),
                disabledHint: const Text(
                  'No usernames',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
                items: usernameItems,
                onChanged: (chatUsername) {
                  settingsBox.put(
                    switch (chatType) {
                      ChatType.Twitch =>
                        SettingsKeys.SelectedTwitchUsername.name,
                      ChatType.YouTube =>
                        SettingsKeys.SelectedYouTubeUsername.name,
                      ChatType.Owncast =>
                        SettingsKeys.SelectedOwncastUsername.name,
                    },
                    chatUsername,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
