import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../stores/views/twitch_chat.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import '../dialogs/add_chat_sheet.dart';

/// Multi-chat channel picker for the native chat bar, in the
/// [UsernameDropdown] idiom: the user's own channel first (marked "You"),
/// then the added channels (shield when the user moderates them), and an
/// "Add chat…" entry at the bottom (an action, not a selection).
/// Long-pressing an added channel offers removal (the selected channel
/// falls back to own). Disabled while a switch is in flight.
class NativeChannelDropdown extends StatelessWidget {
  /// Dropdown values are channel ids; own channel is the empty string and
  /// the "Add chat…" entry is an action sentinel (never a selection).
  static const String _kOwnValue = '';
  static const String _kAddChatValue = '__add_chat__';

  const NativeChannelDropdown({super.key});

  void _confirmRemove(BuildContext context, String channelId) {
    /// Close the open dropdown menu first, then confirm — [context] is
    /// the Observer-captured one (still mounted under the dropdown, not
    /// the menu route), so it survives the pop.
    Navigator.of(context).pop();
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: ConfirmationDialog(
        title: 'Remove chat?',
        body: 'The channel is removed from your list — its chat history '
            'in this session is dropped.',
        okText: 'Remove',
        isYesDestructive: true,
        onOk: (_) =>
            GetIt.instance<TwitchChatStore>().removeChannel(channelId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final store = GetIt.instance<TwitchChatStore>();
        final switching = store.chatConnection ==
            TwitchChatConnectionState.connecting;

        final items = <DropdownMenuItem<String>>[
          DropdownMenuItem<String>(
            value: _kOwnValue,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    store.user?.displayName ??
                        store.user?.login ??
                        'Own channel',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'You',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          for (final ref in store.channels)
            DropdownMenuItem<String>(
              value: ref.id,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => this._confirmRemove(context, ref.id),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        ref.displayName,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                    if (store.moderatedChannelIds.contains(ref.id)) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.shield,
                        size: 14.0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ],
                ),
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

        return Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 100.0),
            child: Container(
              /// 44pt touch target ([kMinInteractiveDimensionCupertino]) —
              /// same bar-control idiom as [UsernameDropdown].
              constraints: const BoxConstraints(
                  minHeight: kMinInteractiveDimensionCupertino),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: StylingHelper.lightenDarkenColor(
                    Theme.of(context).cardColor),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color:
                      Theme.of(context).dividerColor.withValues(alpha: 0.4),
                  width: 0.0,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: DropdownButton<String>(
                    value: store.selectedChannelId ?? _kOwnValue,
                    isExpanded: true,
                    isDense: true,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: items,
                    onChanged: switching
                        ? null
                        : (value) {
                            if (value == _kAddChatValue) {
                              showAddChatSheet(context);
                              return;
                            }
                            store.selectChannel(
                                value == _kOwnValue ? null : value);
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
