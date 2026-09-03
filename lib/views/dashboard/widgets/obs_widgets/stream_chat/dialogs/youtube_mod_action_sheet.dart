import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../stores/views/youtube_chat.dart';
import '../../../../../../types/classes/youtube/youtube_chat_message.dart';
import '../../../../../../utils/modal_handler.dart';
import '../native_chat_chrome.dart';
import 'mod_action_sheet.dart';

/// Opens the YouTube mod action sheet for [message] — shown on long-press
/// when signed in (YouTube has no cheap "am I a mod" lookup; a 403 from a
/// non-mod surfaces via the failure snackbar, plan §7).
///
/// Failures surface as a snackbar hosted by [context] (the chat view's) —
/// the sheet route is already popped by then, so its own context can't
/// host it. Same idiom as [showModActionSheet].
/// Returns when the sheet is dismissed (so callers can clear selection
/// chrome on the target message).
Future<void> showYouTubeModActionSheet(
  BuildContext context,
  YouTubeChatMessage message,
) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.72,
      builder: (_) => YouTubeModActionSheet(
        message: message,
        onFailure: (message) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message))),
      ),
    );

/// Timeout presets (label → seconds) — YouTube bans take a duration in
/// seconds; these cover the common moderator ladder.
const List<(String, int)> kYouTubeTimeoutPresets = [
  ('1 minute', 60),
  ('5 minutes', 300),
  ('10 minutes', 600),
  ('1 hour', 3600),
  ('24 hours', 86400),
];

/// Mod actions for one YouTube chat message: delete it, or timeout/ban its
/// author. "Timeout…" swaps to a preset step. Final actions (delete /
/// timeout duration / ban) ask for confirmation first. On failure the local
/// state is untouched and [onFailure] explains via snackbar.
class YouTubeModActionSheet extends StatefulWidget {
  final YouTubeChatMessage message;

  /// Failure snackbar hook — hosted by the caller's context (see
  /// [showYouTubeModActionSheet]).
  final void Function(String message) onFailure;

  const YouTubeModActionSheet({
    super.key,
    required this.message,
    required this.onFailure,
  });

  @override
  State<YouTubeModActionSheet> createState() => _YouTubeModActionSheetState();
}

class _YouTubeModActionSheetState extends State<YouTubeModActionSheet> {
  bool _timeoutStep = false;

  /// Re-entrancy guard — a double-tap must not fire two API calls.
  bool _running = false;

  YouTubeChatStore get _store => GetIt.instance<YouTubeChatStore>();

  Future<void> _run(
    Future<bool> Function() action,
    String failureText,
  ) async {
    if (this._running) return;
    this.setState(() => this._running = true);
    final ok = await action();
    if (!this.mounted) return;
    Navigator.of(context).pop();
    if (!ok) this.widget.onFailure(this._store.moderationError ?? failureText);
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
    final name = this.widget.message.authorName ?? 'this user';
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
                    for (final preset in kYouTubeTimeoutPresets)
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
                            action: () => this._store.banUser(
                                  this.widget.message.authorChannelId ?? '',
                                  durationSeconds: preset.$2,
                                ),
                            failureText: 'Could not time out the user',
                          ),
                        ),
                      ),
                  ] else ...[
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
                              this._store.deleteMessage(this.widget.message.id),
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
                            'Ban $name from this live chat? They won\'t be '
                            'able to chat until unbanned.',
                        okText: 'Ban',
                        action: () => this._store.banUser(
                              this.widget.message.authorChannelId ?? '',
                            ),
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

  /// Same header idiom as the Twitch mod sheet: chevron left of the title
  /// on the timeout step.
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
