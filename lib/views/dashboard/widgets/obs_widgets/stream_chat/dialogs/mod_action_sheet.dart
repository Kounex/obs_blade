import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../stores/views/twitch_chat.dart';
import '../../../../../../types/classes/twitch/eventsub/channel_chat_message.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import '../native_chat_chrome.dart';

/// Opens the mod action sheet for [event] (multi-chat) — shown when a live
/// message is tapped in a channel the user moderates
/// (`TwitchChatStore.canModerateSelectedChannel` gates the tap target).
///
/// [onReply] (when the account may write chat) adds a non-destructive
/// Reply row above the moderation actions.
///
/// Failures surface as a snackbar hosted by [context] (the chat view's) —
/// the sheet route is already popped by then, so its own context can't
/// host it.
/// Returns when the sheet is dismissed (so callers can clear selection
/// chrome on the target message).
Future<void> showModActionSheet(
  BuildContext context,
  ChatMessageEvent event, {
  VoidCallback? onReply,
}) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.72,
      builder: (_) => ModActionSheet(
        event: event,
        onReply: onReply,
        onFailure: (message) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message))),
      ),
    );

/// Opens the lightweight message sheet for non-moderators: just the Reply
/// action (mod users get [showModActionSheet] instead). [onReply] runs
/// after the sheet pops.
Future<void> showMessageActionSheet(
  BuildContext context, {
  required String authorName,
  required VoidCallback onReply,
}) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.72,
      builder: (_) =>
          MessageActionSheet(authorName: authorName, onReply: onReply),
    );

/// Timeout presets (label → seconds). Twitch caps at 2 weeks; these cover
/// the common moderator ladder including a 1-minute quick hit.
const List<(String, int)> kModTimeoutPresets = [
  ('1 minute', 60),
  ('5 minutes', 300),
  ('10 minutes', 600),
  ('30 minutes', 1800),
  ('1 hour', 3600),
  ('12 hours', 43200),
  ('24 hours', 86400),
  ('1 week', 604800),
];

/// Mod actions for one chat message: delete it, or timeout/ban its author.
/// "Timeout…" swaps to a preset step. Final actions (delete / timeout
/// duration / ban) ask for confirmation first. On failure the local state
/// is untouched and [onFailure] explains via snackbar.
class ModActionSheet extends StatefulWidget {
  final ChatMessageEvent event;

  /// Failure snackbar hook — hosted by the caller's context (see
  /// [showModActionSheet]).
  final void Function(String message) onFailure;

  /// When the account may write chat: Reply row above the moderation
  /// actions. Runs after the sheet pops.
  final VoidCallback? onReply;

  const ModActionSheet({
    super.key,
    required this.event,
    required this.onFailure,
    this.onReply,
  });

  @override
  State<ModActionSheet> createState() => _ModActionSheetState();
}

class _ModActionSheetState extends State<ModActionSheet> {
  bool _timeoutStep = false;

  /// Re-entrancy guard — a double-tap must not fire two Helix calls.
  bool _running = false;

  TwitchChatStore get _store => GetIt.instance<TwitchChatStore>();

  Future<void> _run(
    Future<bool> Function() action,
    String failureText,
  ) async {
    if (this._running) return;
    this.setState(() => this._running = true);
    final ok = await action();
    if (!this.mounted) return;
    Navigator.of(context).pop();
    if (!ok) this.widget.onFailure(failureText);
  }

  /// Confirm before a Helix call — cancel leaves the sheet open.
  void _confirmThenRun({
    required String title,
    required String body,
    required String okText,
    required Future<bool> Function() action,
    required String failureText,
    bool destructive = true,
  }) {
    if (this._running) return;
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: ConfirmationDialog(
        title: title,
        body: body,
        okText: okText,
        noText: 'Cancel',
        isYesDestructive: destructive,
        onOk: (_) {
          this._run(action, failureText);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = this.widget.event;
    final name = event.chatterUserName;
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.5;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          this._titleRow(context, name),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (this._timeoutStep) ...[
                    for (final preset in kModTimeoutPresets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: this._actionRow(
                          context,
                          icon: CupertinoIcons.timer,
                          label: preset.$1,
                          onTap: () => this._confirmThenRun(
                            title: 'Timeout $name?',
                            body:
                                'Timeout $name for ${preset.$1}? They can\'t '
                                'chat until it expires.',
                            okText: 'Timeout',
                            action: () => this
                                ._store
                                .timeoutUser(event.chatterUserId, preset.$2),
                            failureText: 'Could not time out the user',
                          ),
                        ),
                      ),
                  ] else ...[
                    if (this.widget.onReply != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: chatActionRowCard(
                          context,
                          icon: CupertinoIcons.reply,
                          label: 'Reply',
                          onTap: this._running
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  this.widget.onReply!();
                                },
                        ),
                      ),
                    this._pinRow(context, event),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: this._actionRow(
                        context,
                        icon: CupertinoIcons.trash,
                        label: 'Delete message',
                        onTap: () => this._confirmThenRun(
                          title: 'Delete message?',
                          body:
                              'Remove this message from $name in chat? '
                              'This can\'t be undone.',
                          okText: 'Delete',
                          action: () => this._store.deleteMessage(event),
                          failureText: 'Could not delete the message',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: this._actionRow(
                        context,
                        icon: CupertinoIcons.timer,
                        label: 'Timeout…',
                        onTap: () =>
                            this.setState(() => this._timeoutStep = true),
                      ),
                    ),
                    this._actionRow(
                      context,
                      icon: CupertinoIcons.hand_raised,
                      label: 'Ban',
                      destructive: true,
                      onTap: () => this._confirmThenRun(
                        title: 'Ban $name?',
                        body:
                            'Ban $name from this channel? They won\'t be able '
                            'to chat until unbanned.',
                        okText: 'Ban',
                        action: () => this._store.banUser(event.chatterUserId),
                        failureText: 'Could not ban the user',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pin row between Reply and Delete: "Unpin message" when [event] is
  /// the pinned one, else "Pin message" — replacing a different active pin
  /// asks for confirmation first (Helix auto-replaces). [pinnedMessage] is
  /// read once at build; the banner refreshes from the store afterwards.
  Widget _pinRow(BuildContext context, ChatMessageEvent event) {
    final pinned = this._store.pinnedMessage;
    if (pinned?.messageId == event.messageId) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: this._actionRow(
          context,
          icon: CupertinoIcons.pin_slash,
          label: 'Unpin message',
          onTap: () => this._run(
            () => this._store.unpinMessage(),
            'Could not unpin the message',
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: this._actionRow(
        context,
        icon: CupertinoIcons.pin,
        label: 'Pin message',
        onTap: pinned == null
            ? () => this._run(
                  () => this._store.pinMessage(event),
                  'Could not pin the message',
                )
            : () => this._confirmThenRun(
                  title: 'Pin this message?',
                  body: 'Replace the currently pinned message?',
                  okText: 'Pin',
                  destructive: false,
                  action: () => this._store.pinMessage(event),
                  failureText: 'Could not pin the message',
                ),
      ),
    );
  }

  /// Same header idiom as native chat options: chevron left of the title
  /// on the timeout step (not an action-row "Back" card).
  Widget _titleRow(BuildContext context, String chatterName) {
    final title = this._timeoutStep
        ? 'Timeout $chatterName'
        : 'Moderate $chatterName';
    if (!this._timeoutStep) {
      return Text(title, style: nativeChatSheetTitleStyle(context));
    }
    return Row(
      children: [
        Pressable(
          haptic: true,
          onTap: this._running
              ? null
              : () => this.setState(() => this._timeoutStep = false),
          child: const Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: Icon(CupertinoIcons.chevron_back, size: 20.0),
          ),
        ),
        Expanded(
          child: Text(title, style: nativeChatSheetTitleStyle(context)),
        ),
      ],
    );
  }

  /// Same idiom as the connection sheet's action rows (container card,
  /// 44pt target, destructive in the unreachable red).
  Widget _actionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) =>
      chatActionRowCard(
        context,
        icon: icon,
        label: label,
        destructive: destructive,
        onTap: this._running ? null : onTap,
      );
}

/// Shared action-row card idiom (connection sheet / mod sheet): container
/// card, 44pt target, destructive in the unreachable red. Null [onTap]
/// renders it disabled.
Widget chatActionRowCard(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback? onTap,
  bool destructive = false,
}) {
  final Color color = destructive
      ? (Theme.of(context).extension<AppStatusColors>() ??
              AppStatusColors.standard)
          .unreachable
      : Theme.of(context).textTheme.bodyMedium?.color ??
          CupertinoColors.label;
  return Pressable(
    haptic: true,
    onTap: onTap,
    child: Container(
      constraints: const BoxConstraints(
        minHeight: kMinInteractiveDimensionCupertino,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: 0.0,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.0, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: color),
          ),
        ],
      ),
    ),
  );
}

/// Lightweight message sheet for non-moderators — just the Reply action
/// (mod users get [ModActionSheet] with Reply on top instead). Same card
/// idiom via [chatActionRowCard].
class MessageActionSheet extends StatelessWidget {
  final String authorName;

  /// Runs after the sheet pops (set reply target + focus the input).
  final VoidCallback onReply;

  const MessageActionSheet({
    super.key,
    required this.authorName,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message from @${this.authorName}',
            style: nativeChatSheetTitleStyle(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          chatActionRowCard(
            context,
            icon: CupertinoIcons.reply,
            label: 'Reply',
            onTap: () {
              Navigator.of(context).pop();
              this.onReply();
            },
          ),
        ],
      ),
    );
  }
}
