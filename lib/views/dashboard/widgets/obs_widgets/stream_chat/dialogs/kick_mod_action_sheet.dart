import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../stores/views/kick_chat.dart';
import '../../../../../../types/classes/kick/kick_chat_message.dart';
import '../../../../../../utils/icons/jam_icons.dart';
import '../../../../../../utils/modal_handler.dart';
import '../native_chat_chrome.dart';
import 'mod_action_sheet.dart';
import 'chat_user_list_actions.dart';

/// Opens the Kick mod action sheet for [message] — shown on long-press
/// when signed in. Kick has no "am I a mod" lookup, so the actions are
/// offered to any signed-in user and a non-mod's action 403s into the
/// failure snackbar (the documented honest-403 model,
/// docs/kick-chat-audit.md).
///
/// [onReply] adds a non-destructive Reply row above the moderation
/// actions (runs after the sheet pops).
///
/// Failures surface as a snackbar hosted by [context] (the chat view's) —
/// the sheet route is already popped by then, so its own context can't
/// host it. Same idiom as [showYouTubeModActionSheet].
/// Returns when the sheet is dismissed (so callers can clear selection
/// chrome on the target message).
Future<void> showKickModActionSheet(
  BuildContext context,
  KickChatMessage message, {
  VoidCallback? onReply,
}) => ModalHandler.showBaseBottomSheet(
  context: context,
  barrierDismissible: true,
  enableDrag: true,
  maxHeightFraction: 0.72,
  builder: (_) => KickModActionSheet(
    message: message,
    onReply: onReply,
    hostContext: context,
    onCopy: () => copyMessageTextAndNotify(context, message.content),
    onFailure: (message) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message))),
  ),
);

/// Timeout presets (label → minutes) — Kick bans take a duration in
/// minutes (1..10080, omitted = permanent); these cover the common
/// moderator ladder.
const List<(String, int)> kKickTimeoutPresets = [
  ('1 minute', 1),
  ('5 minutes', 5),
  ('10 minutes', 10),
  ('30 minutes', 30),
  ('1 hour', 60),
  ('12 hours', 720),
  ('24 hours', 1440),
  ('1 week', 10080),
];

/// Mod actions for one Kick chat message: reply to it, delete it, or
/// timeout/ban its author. "Timeout…" swaps to a preset step. Final
/// actions (delete / timeout duration / ban) ask for confirmation first.
/// On failure the local state is untouched (the Pusher lifecycle events
/// reconcile on success) and [onFailure] explains via snackbar.
class KickModActionSheet extends StatefulWidget {
  final KickChatMessage message;

  /// Failure snackbar hook — hosted by the caller's context (see
  /// [showKickModActionSheet]).
  final void Function(String message) onFailure;

  /// When the account may write chat: Reply row above the moderation
  /// actions. Runs after the sheet pops.
  final VoidCallback? onReply;

  /// Copies the message text and confirms via snackbar. Always available
  /// — offered to any signed-in user, same as the moderation rows.
  final VoidCallback onCopy;

  /// Chat view context — when set, "Highlight / Ignore user" rows appear
  /// under Copy (their snackbar is hosted here).
  final BuildContext? hostContext;

  const KickModActionSheet({
    super.key,
    required this.message,
    required this.onFailure,
    required this.onCopy,
    this.onReply,
    this.hostContext,
  });

  @override
  State<KickModActionSheet> createState() => _KickModActionSheetState();
}

class _KickModActionSheetState extends State<KickModActionSheet> {
  bool _timeoutStep = false;

  /// Re-entrancy guard — a double-tap must not fire two API calls.
  bool _running = false;

  KickChatStore get _store => GetIt.instance<KickChatStore>();

  Future<void> _run(Future<bool> Function() action, String failureText) async {
    if (this._running) return;
    this.setState(() => this._running = true);
    final ok = await action();
    if (!this.mounted) return;
    Navigator.of(context).pop();
    if (!ok) this.widget.onFailure(this._store.modActionError ?? failureText);
  }

  /// Confirm before an API call — cancel leaves the sheet open.
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
    final name = this.widget.message.authorName;
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          nativeChatSheetDragHandle(context),
          this._titleRow(context, name),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: SingleChildScrollView(
              child: AnimatedSwitcher(
                duration: AppMotion.medium,
                transitionBuilder: (child, animation) =>
                    chatSheetPaneTransition(context, child, animation),
                child: KeyedSubtree(
                  key: ValueKey<bool>(this._timeoutStep),
                  child: this._timeoutStep
                      ? this._buildTimeoutPresets(context)
                      : this._buildRootActions(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeoutPresets(BuildContext context) {
    final name = this.widget.message.authorName;
    final senderId = this.widget.message.sender?.id;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final preset in kKickTimeoutPresets)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: this._actionRow(
              context,
              icon: CupertinoIcons.timer,
              label: preset.$1,
              onTap: senderId == null
                  ? null
                  : () => this._confirmThenRun(
                      title: 'Timeout $name?',
                      body:
                          'Timeout $name for ${preset.$1}? They can\'t '
                          'chat until it expires.',
                      okText: 'Timeout',
                      action: () =>
                          this._store.timeoutUser(senderId, preset.$2),
                      failureText: 'Could not time out the user',
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildRootActions(BuildContext context) {
    final name = this.widget.message.authorName;
    final senderId = this.widget.message.sender?.id;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: chatActionRowCard(
            context,
            icon: JamIcons.clipboard,
            label: 'Copy message',
            onTap: () {
              Navigator.of(context).pop();
              this.widget.onCopy();
            },
          ),
        ),
        if (this.widget.hostContext case final host?)
          ChatUserListActions(userName: name, hostContext: host),
        if (this.widget.onReply != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: this._actionRow(
              context,
              icon: CupertinoIcons.reply,
              label: 'Reply',
              onTap: () {
                Navigator.of(context).pop();
                this.widget.onReply?.call();
              },
            ),
          ),
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
              action: () =>
                  this._store.deleteChatMessage(this.widget.message.id),
              failureText: 'Could not delete the message',
            ),
          ),
        ),
        if (senderId != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: this._actionRow(
              context,
              icon: CupertinoIcons.timer,
              label: 'Timeout…',
              onTap: () => this.setState(() => this._timeoutStep = true),
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
                  'Ban $name from this channel? They won\'t be '
                  'able to chat until unbanned.',
              okText: 'Ban',
              action: () => this._store.banUser(senderId),
              failureText: 'Could not ban the user',
            ),
          ),
        ],
      ],
    );
  }

  /// Same header idiom as the YouTube/Twitch mod sheets: chevron left of
  /// the title on the timeout step.
  Widget _titleRow(BuildContext context, String authorName) {
    final title = this._timeoutStep
        ? 'Timeout $authorName'
        : 'Moderate $authorName';
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
          child: Padding(
            padding: const EdgeInsets.only(
              right: AppSpacing.sm,
              top: AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            child: Icon(
              CupertinoIcons.chevron_back,
              size: 20.0,
              color:
                  (Theme.of(context).extension<AppTextColors>() ??
                          AppTextColors.standard)
                      .highlightText,
            ),
          ),
        ),
        Expanded(child: Text(title, style: nativeChatSheetTitleStyle(context))),
      ],
    );
  }

  Widget _actionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool destructive = false,
  }) => chatActionRowCard(
    context,
    icon: icon,
    label: label,
    destructive: destructive,
    onTap: this._running ? null : onTap,
  );
}
