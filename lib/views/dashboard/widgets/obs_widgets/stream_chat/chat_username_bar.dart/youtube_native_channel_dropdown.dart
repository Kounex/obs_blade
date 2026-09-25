import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../native_chat_chrome.dart';

import '../chat_type_brand.dart';

import '../../../../../../models/enums/chat_type.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../stores/views/youtube_chat.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import 'dialogs/add_edit_youtube_username.dart';

/// Multi-chat channel picker for the native YouTube chat bar — a fork of
/// [NativeChannelDropdown] bound to [YouTubeChatStore] (labels of the
/// [SettingsKeys.YouTubeUsernames] map). Own channel first, the rest A–Z;
/// the menu scrolls past [kChatChannelMenuMaxHeight]. Rows show LIVE /
/// OFFLINE from [YouTubeChatStore.liveStateForChannel] — channel entries
/// are checked quota-free when the menu opens (pinned videos stay
/// unknown). No Mod chip: the API has no cheap "am I a mod" lookup.
/// When signed in, the account's own channel leads the list, marked "You"
/// (native-only — [YouTubeChatStore.ownChannel], not part of the WebView
/// list, so it has no remove long-press). "Add chat…" opens the existing
/// YouTube username dialog (entries are per-entry — channel entries follow
/// their current stream). Long-press removes an added entry. Disabled
/// while a switch is in flight.
class YouTubeNativeChannelDropdown extends StatelessWidget {
  /// "Add chat…" is an action sentinel (never a selection).
  static const String _kAddChatValue = '__add_chat__';

  const YouTubeNativeChannelDropdown({super.key});

  void _addChat(BuildContext context) {
    /// The dropdown route has already popped itself by the time
    /// [onChanged] runs. Another pop here dismisses the page under the
    /// dialog.
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: AddEditYouTubeUsernameDialog(
        settingsBox: Hive.box(HiveKeys.Settings.name),
      ),
    ).then((_) {
      /// The dialog edited [SettingsKeys.YouTubeUsernames] — re-read so the
      /// new/changed entry appears (and its video id is re-resolved).
      final store = GetIt.instance<YouTubeChatStore>();
      store.reloadChannels();
    });
  }

  void _confirmRemove(BuildContext context, String label) {
    /// Close the open dropdown menu first, then confirm — [context] is
    /// the Observer-captured one (still mounted under the dropdown, not
    /// the menu route), so it survives the pop.
    Navigator.of(context).pop();
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: ConfirmationDialog(
        title: 'Remove chat?',
        body:
            '"$label" is removed from your YouTube list - its chat '
            'history in this session is dropped.',
        okText: 'Remove',
        isYesDestructive: true,
        onOk: (_) {
          final settingsBox = Hive.box(HiveKeys.Settings.name);
          final usernames = Map<String, String>.from(
            settingsBox.get(
              SettingsKeys.YouTubeUsernames.name,
              defaultValue: <String, String>{},
            ),
          );
          usernames.remove(label);
          settingsBox.put(SettingsKeys.YouTubeUsernames.name, usernames);
          if (settingsBox.get(SettingsKeys.SelectedYouTubeUsername.name) ==
              label) {
            settingsBox.delete(SettingsKeys.SelectedYouTubeUsername.name);
          }
          GetIt.instance<YouTubeChatStore>().reloadChannels();
        },
      ),
    );
  }

  /// Open-menu row: name (+ You) and the LIVE / OFFLINE tag once known.
  Widget _menuRow(
    BuildContext context,
    YouTubeChatStore store,
    YouTubeChatChannel channel,
  ) {
    final live = store.liveStateForChannel(channel.label);
    return Row(
      children: [
        Expanded(
          child: this._channelLabel(
            context,
            channel.displayName,
            own: channel.isOwn,
          ),
        ),
        if (live != null) ...[
          const SizedBox(width: AppSpacing.sm),
          NativeChatLiveTag(
            key: Key(
              'youtube-channel-dropdown-${live ? 'live' : 'offline'}-'
              '${channel.isOwn ? 'own' : channel.label}',
            ),
            live: live,
            viewerCount: channel.label == store.selectedChannelLabel
                ? store.selectedChannelViewerCount
                : null,
          ),
        ],
      ],
    );
  }

  /// Name, plus the "You" marker for the own channel (same idiom as the
  /// Twitch dropdown).
  Widget _channelLabel(BuildContext context, String name, {bool own = false}) {
    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
        ),
        if (own) ...[
          const SizedBox(width: AppSpacing.xs),
          NativeChatYouChip(color: ChatType.YouTube.brandColor!),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final store = GetIt.instance<YouTubeChatStore>();
        final switching =
            store.chatConnection == YouTubeChatConnectionState.connecting;

        /// Own channel first, the rest A–Z.
        final channels = [...store.nativeChannels]
          ..sort((a, b) {
            if (a.isOwn != b.isOwn) return a.isOwn ? -1 : 1;
            return compareChatChannelNames(a.displayName, b.displayName);
          });

        final items = <DropdownMenuItem<String>>[
          for (final channel in channels)
            DropdownMenuItem<String>(
              value: channel.label,
              child: channel.isOwn
                  ? this._menuRow(context, store, channel)
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPress: () =>
                          this._confirmRemove(context, channel.label),
                      child: this._menuRow(context, store, channel),
                    ),
            ),
          const DropdownMenuItem<String>(
            value: _kAddChatValue,
            child: Row(
              children: [
                Icon(CupertinoIcons.plus, size: 16.0),
                SizedBox(width: AppSpacing.xs),
                Text('Add chat…'),
              ],
            ),
          ),
        ];

        final selectedBuilders = <Widget>[
          for (final channel in channels)
            this._channelLabel(
              context,
              channel.displayName,
              own: channel.isOwn,
            ),
          this._channelLabel(context, 'Add chat…'),
        ];

        return Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 100.0),
            child: Container(
              /// 44pt touch target ([kMinInteractiveDimensionCupertino]) —
              /// same bar-control idiom as [UsernameDropdown].
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimensionCupertino,
              ),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: StylingHelper.lightenDarkenColor(
                  Theme.of(context).cardColor,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                  width: 0.0,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: DropdownButton<String>(
                    value: store.selectedChannelLabel,
                    isExpanded: true,
                    isDense: true,
                    menuMaxHeight: kChatChannelMenuMaxHeight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    icon: const Icon(Icons.arrow_drop_down),

                    /// Opening the menu refreshes the live tags (at most
                    /// once a minute, quota-free).
                    onTap: () => unawaited(store.refreshChannelLivePreviews()),
                    items: items,
                    selectedItemBuilder: (_) => selectedBuilders,
                    onChanged: switching
                        ? null
                        : (value) {
                            if (value == null) return;
                            if (value == _kAddChatValue) {
                              this._addChat(context);
                              return;
                            }
                            store.selectChannel(value);
                          },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
