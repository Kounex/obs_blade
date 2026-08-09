import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../stores/views/twitch_chat.dart';
import '../../../../../../types/classes/twitch/eventsub/channel_chat_message.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';

/// Opens the mod action sheet for [event] (multi-chat) — shown when a live
/// message is tapped in a channel the user moderates
/// (`TwitchChatStore.canModerateSelectedChannel` gates the tap target).
///
/// Failures surface as a snackbar hosted by [context] (the chat view's) —
/// the sheet route is already popped by then, so its own context can't
/// host it.
void showModActionSheet(BuildContext context, ChatMessageEvent event) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      includeCloseButton: true,
      maxHeightFraction: 0.72,
      builder: (_) => ModActionSheet(
        event: event,
        onFailure: (message) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message))),
      ),
    );

/// Mod actions for one chat message: delete it, or timeout/ban its author.
/// "Timeout…" swaps to a preset step (10 min / 1 h / 24 h). Every action
/// closes the sheet; on failure the local state is untouched and
/// [onFailure] explains via snackbar.
class ModActionSheet extends StatefulWidget {
  final ChatMessageEvent event;

  /// Failure snackbar hook — hosted by the caller's context (see
  /// [showModActionSheet]).
  final void Function(String message) onFailure;

  const ModActionSheet({
    super.key,
    required this.event,
    required this.onFailure,
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

  @override
  Widget build(BuildContext context) {
    final event = this.widget.event;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            this._timeoutStep
                ? 'Timeout ${event.chatterUserName}'
                : 'Moderate ${event.chatterUserName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (this._timeoutStep) ...[
            for (final preset in const [
              ('10 minutes', 600),
              ('1 hour', 3600),
              ('24 hours', 86400),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: this._actionRow(
                  context,
                  icon: CupertinoIcons.timer,
                  label: preset.$1,
                  onTap: () => this._run(
                    () =>
                        this._store.timeoutUser(event.chatterUserId, preset.$2),
                    'Could not time out the user',
                  ),
                ),
              ),
            this._actionRow(
              context,
              icon: CupertinoIcons.chevron_left,
              label: 'Back',
              onTap: () => this.setState(() => this._timeoutStep = false),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: this._actionRow(
                context,
                icon: CupertinoIcons.trash,
                label: 'Delete message',
                onTap: () => this._run(
                  () => this._store.deleteMessage(event),
                  'Could not delete the message',
                ),
              ),
            ),
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
              onTap: () => this._run(
                () => this._store.banUser(event.chatterUserId),
                'Could not ban the user',
              ),
            ),
          ],
        ],
      ),
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
  }) {
    final Color color = destructive
        ? (Theme.of(context).extension<AppStatusColors>() ??
                AppStatusColors.standard)
            .unreachable
        : Theme.of(context).textTheme.bodyMedium?.color ??
            CupertinoColors.label;
    return Pressable(
      haptic: true,
      onTap: this._running ? null : onTap,
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
}
