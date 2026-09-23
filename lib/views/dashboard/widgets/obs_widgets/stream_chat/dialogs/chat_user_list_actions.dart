import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/chat_highlight_helper.dart';
import 'mod_action_sheet.dart';

/// "Highlight @user" / "Ignore @user" rows for every message sheet —
/// Chatterino's per-user highlight + ignore lists, one tap from a message.
/// Toggles [SettingsKeys.ChatHighlightUsers] / [SettingsKeys.ChatIgnoredUsers]
/// (shared across engines, editable in the options sheet); the timelines
/// rebuild on those keys. Pops the sheet, then confirms via snackbar on
/// the caller's [hostContext] (the sheet route is gone by then).
class ChatUserListActions extends StatelessWidget {
  /// Name written to the lists (Twitch login, Kick username, YouTube
  /// display name).
  final String userName;

  /// Context of the chat view that opened the sheet — hosts the snackbar.
  final BuildContext hostContext;

  const ChatUserListActions({
    super.key,
    required this.userName,
    required this.hostContext,
  });

  static bool _inList(SettingsKeys key, String name) => chatAuthorInList(
    parseChatUserList(
      Hive.box(HiveKeys.Settings.name).get(key.name, defaultValue: '')
          as String,
    ),
    [name],
  );

  void _toggle(BuildContext context, SettingsKeys key, String done) {
    final box = Hive.box(HiveKeys.Settings.name);
    box.put(
      key.name,
      toggleChatUserListEntry(
        box.get(key.name, defaultValue: '') as String,
        this.userName,
      ),
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.maybeOf(this.hostContext)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(done)));
  }

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen(HiveKeys.Settings.name) || this.userName.isEmpty) {
      return const SizedBox.shrink();
    }
    final name = this.userName;
    final highlighted = _inList(SettingsKeys.ChatHighlightUsers, name);
    final ignored = _inList(SettingsKeys.ChatIgnoredUsers, name);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: chatActionRowCard(
            context,
            icon: highlighted ? CupertinoIcons.star_slash : CupertinoIcons.star,
            label: highlighted ? 'Stop highlighting $name' : 'Highlight $name',
            onTap: () => this._toggle(
              context,
              SettingsKeys.ChatHighlightUsers,
              highlighted
                  ? 'No longer highlighting $name'
                  : 'Highlighting messages from $name',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: chatActionRowCard(
            context,
            icon: ignored ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
            label: ignored ? 'Unignore $name' : 'Ignore $name',
            onTap: () => this._toggle(
              context,
              SettingsKeys.ChatIgnoredUsers,
              ignored
                  ? 'Showing messages from $name again'
                  : 'Hiding messages from $name',
            ),
          ),
        ),
      ],
    );
  }
}
