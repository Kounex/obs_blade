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
import '../native_chat_chrome.dart';

/// Multi-chat channel picker for the native chat bar, in the
/// [UsernameDropdown] idiom: the user's own channel first (marked "You"),
/// then the added channels, and an "Add chat…" entry at the bottom (an
/// action, not a selection). Open-menu rows show LIVE / Mod status chips
/// (closed/selected value stays name-only — the header already mirrors
/// the effective channel). Long-pressing an added channel offers removal
/// (the selected channel falls back to own). Disabled while a switch is
/// in flight.
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

  Widget _channelLabel(
    BuildContext context, {
    required String name,
    String? trailingLabel,
  }) {
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
        if (trailingLabel != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            trailingLabel,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _menuRow(
    BuildContext context, {
    required TwitchChatStore store,
    required String? channelId,
    required String name,
    String? trailingLabel,
  }) {
    final statusColors = Theme.of(context).extension<AppStatusColors>() ??
        AppStatusColors.standard;
    final live = store.isChannelLive(channelId);
    final mod = store.canModerateChannel(channelId);

    /// Menu width is locked to the dropdown button (not the screen), so
    /// [Expanded] pushes chips to that trailing edge without a fixed size.
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
              ),
              if (trailingLabel != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  trailingLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (live || mod) const SizedBox(width: AppSpacing.sm),
        if (live)
          NativeChatStatusChip.live(
            key: Key('channel-dropdown-live-${channelId ?? 'own'}'),
            color: statusColors.live,
            viewerCount: store.viewerCountForChannel(channelId),
          ),
        if (live && mod) const SizedBox(width: AppSpacing.xs),
        if (mod)
          NativeChatStatusChip.mod(
            key: Key('channel-dropdown-mod-${channelId ?? 'own'}'),
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final store = GetIt.instance<TwitchChatStore>();
        final switching = store.chatConnection ==
            TwitchChatConnectionState.connecting;

        final ownName = store.user?.displayName ??
            store.user?.login ??
            'Own channel';

        final items = <DropdownMenuItem<String>>[
          DropdownMenuItem<String>(
            value: _kOwnValue,
            child: this._menuRow(
              context,
              store: store,
              channelId: null,
              name: ownName,
              trailingLabel: 'You',
            ),
          ),
          for (final ref in store.channels)
            DropdownMenuItem<String>(
              value: ref.id,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => this._confirmRemove(context, ref.id),
                child: this._menuRow(
                  context,
                  store: store,
                  channelId: ref.id,
                  name: ref.displayName,
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

        /// Closed value: name (+ You) only — LIVE/Mod live on the header
        /// for the effective channel, so they stay off the compact control.
        final selectedBuilders = <Widget>[
          this._channelLabel(
            context,
            name: ownName,
            trailingLabel: 'You',
          ),
          for (final ref in store.channels)
            this._channelLabel(context, name: ref.displayName),
          this._channelLabel(context, name: 'Add chat…'),
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
                    selectedItemBuilder: (_) => selectedBuilders,
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
