import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../stores/views/kick_chat.dart';
import '../../../../../../types/enums/hive_keys.dart';
import '../../../../../../types/enums/settings_keys.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import 'dialogs/add_edit_kick_username.dart';

/// Multi-chat channel picker for the native Kick chat bar — a fork of
/// [YouTubeNativeChannelDropdown] bound to [KickChatStore] (the slugs of
/// [SettingsKeys.KickUsernames]; slug == identity, shared with the WebView
/// path). No LIVE/Mod chips: the store only connects the selected
/// channel, so per-channel live status doesn't exist. "Add chat…" opens
/// the existing Kick username dialog. Long-press removes an entry.
/// Disabled while a switch is in flight.
class KickNativeChannelDropdown extends StatelessWidget {
  /// "Add chat…" is an action sentinel (never a selection).
  static const String _kAddChatValue = '__add_chat__';

  const KickNativeChannelDropdown({super.key});

  void _addChat(BuildContext context) {
    Navigator.of(context).pop();
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
            '"$slug" is removed from your Kick list — its chat '
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

  Widget _channelLabel(BuildContext context, String name) {
    return Text(
      name,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.fade,
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
          for (final slug in store.channels)
            DropdownMenuItem<String>(
              value: slug,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => this._confirmRemove(context, slug),
                child: this._channelLabel(context, slug),
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
          for (final slug in store.channels) this._channelLabel(context, slug),
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
