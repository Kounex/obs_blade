import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../chat_type_brand.dart';

import '../../../../../../models/enums/chat_type.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../stores/views/kick_chat.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import '../native_chat_chrome.dart';
import 'dialogs/add_edit_kick_username.dart';

/// Multi-chat channel picker for the native Kick chat bar — a fork of
/// [YouTubeNativeChannelDropdown] bound to [KickChatStore] (the slugs of
/// [SettingsKeys.KickUsernames]; slug == identity, shared with the WebView
/// path). Open-menu rows show a LIVE chip (+ viewer count) from
/// [KickChatStore.channelLivePreview] — a dedicated per-slug poll, since
/// Kick has no Helix-style batch "which of these are live" endpoint like
/// Twitch's. No Mod chip: Kick has no "am I a mod in this channel"
/// lookup. When signed in, the account's own channel leads the list,
/// marked "You" (native-only — [KickChatStore.ownChannelSlug], not part
/// of the WebView list, so it has no remove long-press). "Add chat…" opens
/// the existing Kick username dialog. Long-press removes an added entry.
/// Disabled while a switch is in flight.
class KickNativeChannelDropdown extends StatelessWidget {
  /// "Add chat…" is an action sentinel (never a selection).
  static const String _kAddChatValue = '__add_chat__';

  const KickNativeChannelDropdown({super.key});

  void _addChat(BuildContext context) {
    /// The dropdown route has already popped itself by the time
    /// [onChanged] runs. Another pop here dismisses the chat page and
    /// leaves an empty view under the dialog.
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: AddEditKickUsernameDialog(
        settingsBox: Hive.box(HiveKeys.Settings.name),
      ),
    ).then((_) {
      /// The dialog edited [SettingsKeys.KickUsernames] AND selected the
      /// new slug ([SettingsKeys.SelectedKickUsername] is shared with the
      /// native engine) — re-read, then follow the dialog's selection
      /// when nothing is selected yet.
      final store = GetIt.instance<KickChatStore>();
      store.reloadChannels();
      final selected = Hive.box(
        HiveKeys.Settings.name,
      ).get(SettingsKeys.SelectedKickUsername.name);
      if (store.selectedChannelSlug == null && selected is String) {
        store.selectChannel(selected);
      }
    });
  }

  void _confirmRemove(BuildContext context, String slug) {
    /// Close the open dropdown menu first, then confirm — [context] is
    /// the Observer-captured one (still mounted under the dropdown, not
    /// the menu route), so it survives the pop.
    Navigator.of(context).pop();
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: ConfirmationDialog(
        title: 'Remove chat?',
        body:
            '"$slug" is removed from your Kick list - its chat '
            'history in this session is dropped.',
        okText: 'Remove',
        isYesDestructive: true,
        onOk: (_) {
          final settingsBox = Hive.box(HiveKeys.Settings.name);
          final slugs = List<String>.from(
            settingsBox.get(
              SettingsKeys.KickUsernames.name,
              defaultValue: <String>[],
            ),
          );
          slugs.remove(slug);
          settingsBox.put(SettingsKeys.KickUsernames.name, slugs);
          if (settingsBox.get(SettingsKeys.SelectedKickUsername.name) == slug) {
            settingsBox.delete(SettingsKeys.SelectedKickUsername.name);
          }
          GetIt.instance<KickChatStore>().reloadChannels();
        },
      ),
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
          NativeChatYouChip(color: ChatType.Kick.brandColor!),
        ],
      ],
    );
  }

  /// Open-menu row: name + LIVE chip when [KickChatStore.channelLivePreview]
  /// has resolved [slug] as live. Menu width is locked to the dropdown
  /// button (not the screen), so [Expanded] pushes the chip to that
  /// trailing edge without a fixed size — same idiom as the Twitch
  /// dropdown's `_menuRow`.
  Widget _menuRow(BuildContext context, KickChatStore store, String slug) {
    final statusColors =
        Theme.of(context).extension<AppStatusColors>() ??
        AppStatusColors.standard;
    final live = store.isChannelLive(slug);
    return Row(
      children: [
        Expanded(
          child: this._channelLabel(
            context,
            slug,
            own: store.isOwnChannel(slug),
          ),
        ),
        if (live) const SizedBox(width: AppSpacing.sm),
        if (live)
          NativeChatStatusChip.live(
            key: Key('kick-channel-dropdown-live-$slug'),
            color: statusColors.live,
            viewerCount: store.viewerCountForChannel(slug),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final store = GetIt.instance<KickChatStore>();
        final switching =
            store.chatConnection == KickChatConnectionState.connecting;

        final items = <DropdownMenuItem<String>>[
          for (final slug in store.nativeChannels)
            DropdownMenuItem<String>(
              value: slug,
              child: store.isOwnChannel(slug)
                  ? this._menuRow(context, store, slug)
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPress: () => this._confirmRemove(context, slug),
                      child: this._menuRow(context, store, slug),
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
          for (final slug in store.nativeChannels)
            this._channelLabel(context, slug, own: store.isOwnChannel(slug)),
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
                    value: store.selectedChannelSlug,
                    isExpanded: true,
                    isDense: true,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    icon: const Icon(Icons.arrow_drop_down),
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
