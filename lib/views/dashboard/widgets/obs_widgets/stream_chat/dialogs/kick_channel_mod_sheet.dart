import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../stores/views/kick_chat.dart';
import '../../../../../../types/classes/chat/chat_ban_entry.dart';
import '../../../../../../utils/modal_handler.dart';
import '../native_chat_chrome.dart';
import '../native_chat_text_field.dart';
import 'channel_mod_chrome.dart';

/// Opens the Kick channel mod sheet on [context] (toasts land there).
void showKickChannelModSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.72,
      builder: (_) => ChannelModSheetFrame(
        child: KickChannelModPanel(
          onToast: (message) => showChannelModToast(context, message),
        ),
      ),
    );

/// Kick channel moderation — what Kick's public API allows: the chat
/// modes as read-only status (no write endpoint), the bans seen this
/// session with Unban, and Unban by username. Offered to any signed-in
/// account (Kick has no "am I a mod" lookup); a 403 toasts
/// [chatNotModeratorText].
class KickChannelModPanel extends StatefulWidget {
  final void Function(String message) onToast;

  /// Title row on top (standalone); the combined sheet shows tabs instead.
  final bool showTitle;

  const KickChannelModPanel({
    super.key,
    required this.onToast,
    this.showTitle = true,
  });

  @override
  State<KickChannelModPanel> createState() => _KickChannelModPanelState();
}

class _KickChannelModPanelState extends State<KickChannelModPanel> {
  final TextEditingController _unbanName = TextEditingController();
  bool _running = false;

  KickChatStore get _store => GetIt.instance<KickChatStore>();

  @override
  void dispose() {
    this._unbanName.dispose();
    super.dispose();
  }

  Future<void> _run(Future<bool> Function() action, String success) async {
    if (this._running) return;
    this.setState(() => this._running = true);
    final ok = await action();
    if (!this.mounted) return;
    this.setState(() => this._running = false);
    this.widget.onToast(
      ok
          ? success
          : this._store.modActionForbidden
          ? chatNotModeratorText('Kick')
          : this._store.modActionError ?? 'Something went wrong',
    );
  }

  void _unban(ChatBanEntry ban) {
    final userId = int.tryParse(ban.userId);
    if (userId == null) return;
    final name = ban.userName ?? 'this user';
    ModalHandler.showBaseDialog(
      context: this.context,
      dialogWidget: ConfirmationDialog(
        title: ban.isTimeout ? 'Lift timeout?' : 'Unban $name?',
        body: '$name can chat again right away.',
        okText: ban.isTimeout ? 'Lift' : 'Unban',
        noText: 'Cancel',
        onOk: (_) => this._run(
          () => this._store.unbanUser(userId),
          ban.isTimeout ? 'Timeout lifted for $name' : '$name was unbanned',
        ),
      ),
    );
  }

  void _unbanByName() {
    final name = this._unbanName.text.trim();
    if (name.isEmpty) return;
    this._run(() => this._store.unbanUsername(name), '$name was unbanned');
    this._unbanName.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final chatroom = this._store.channelInfo?.chatroom;
        final bans = this._store.recentBans.toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (this.widget.showTitle)
              Text(
                'Moderate ${this._store.selectedChannelSlug ?? 'Kick'}',
                style: nativeChatSheetTitleStyle(context),
              ),
            const ChannelModSectionHeader('Chat modes'),
            if (chatroom == null)
              const ChannelModNote('Not connected to a Kick channel yet.')
            else ...[
              ChannelModStatusRow(
                icon: CupertinoIcons.timer,
                label: 'Slow mode',
                active: chatroom.slowMode,
                status: chatroom.slowMode
                    ? '${chatroom.messageInterval}s'
                    : 'Off',
              ),
              ChannelModStatusRow(
                icon: CupertinoIcons.person_2,
                label: 'Followers-only',
                active: chatroom.followersMode,
                status: chatroom.followersMode
                    ? (chatroom.followingMinDuration > 0
                          ? '${chatroom.followingMinDuration} min'
                          : 'On')
                    : 'Off',
              ),
              ChannelModStatusRow(
                icon: CupertinoIcons.star,
                label: 'Subscribers-only',
                active: chatroom.subscribersMode,
                status: chatroom.subscribersMode ? 'On' : 'Off',
              ),
              ChannelModStatusRow(
                icon: CupertinoIcons.smiley,
                label: 'Emote-only',
                active: chatroom.emotesMode,
                status: chatroom.emotesMode ? 'On' : 'Off',
              ),
              const ChannelModNote(
                'Kick\'s API can\'t change chat modes - use kick.com for that.',
              ),
            ],
            const ChannelModSectionHeader('Bans this session'),
            if (bans.isEmpty)
              const ChannelModNote(
                'No bans or timeouts seen yet. Kick has no ban list API, '
                'so this lists the ones that happen while you watch.',
              )
            else
              for (final ban in bans)
                ChannelModBanRow(
                  ban: ban,
                  onUnban: this._running ? null : () => this._unban(ban),
                ),
            const ChannelModSectionHeader('Unban by name'),
            Row(
              children: [
                Expanded(
                  child: NativeChatTextField(
                    key: const Key('kick-unban-name'),
                    controller: this._unbanName,
                    hintText: 'Kick username',
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => this._unbanByName(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ChannelModInlineButton(
                  key: const Key('kick-unban-name-submit'),
                  label: 'Unban',
                  onTap: this._running ? null : this._unbanByName,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
