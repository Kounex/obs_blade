import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../stores/views/twitch_chat.dart';
import '../../../../../../types/classes/twitch/eventsub/automod_events.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import '../native_chat_chrome.dart';

/// Opens the AutoMod queue sheet (held messages awaiting review) for the
/// effective channel. Failures surface as a snackbar on the caller's
/// [context].
void showAutoModQueueSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.72,
      builder: (_) => AutoModQueueSheet(
        onFailure: (message) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message))),
      ),
    );

/// AutoMod queue: messages held by AutoMod (or public blocked terms),
/// delivered live via `automod.message.hold` v2 — there is no Helix list
/// endpoint, so the sheet is a pure Observer over
/// [TwitchChatStore.autoModQueue] (no refresh lifecycle like the bans
/// sheet). Allow posts the message to chat; Deny drops it. Resolutions by
/// other mods (or expiry) arrive via `automod.message.update` and simply
/// remove the row.
class AutoModQueueSheet extends StatefulWidget {
  /// Failure snackbar hook — hosted by the caller's context.
  final void Function(String message) onFailure;

  const AutoModQueueSheet({super.key, required this.onFailure});

  @override
  State<AutoModQueueSheet> createState() => _AutoModQueueSheetState();
}

class _AutoModQueueSheetState extends State<AutoModQueueSheet> {
  /// Re-entrancy guard — the message id currently being resolved.
  String? _runningMessageId;

  TwitchChatStore get _store => GetIt.instance<TwitchChatStore>();

  String _formatHeldAt(DateTime heldAt) =>
      DateFormat.jm().format(heldAt.toLocal());

  void _confirmResolve(AutoModMessageHoldEvent held, {required bool allow}) {
    if (this._runningMessageId != null) return;
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: ConfirmationDialog(
        title: allow ? 'Allow this message?' : 'Deny this message?',
        body: allow
            ? 'The message from ${held.userName} is posted to chat for '
                'everyone.'
            : 'The message never appears in chat.',
        okText: allow ? 'Allow' : 'Deny',
        noText: 'Cancel',
        isYesDestructive: !allow,
        onOk: (_) async {
          this.setState(() => this._runningMessageId = held.messageId);
          final ok = await this._store.resolveAutoModMessage(
            held.messageId,
            allow: allow,
          );
          if (!this.mounted) return;
          this.setState(() => this._runningMessageId = null);
          if (!ok) this.widget.onFailure('Could not resolve the message');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.55;
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
          Text('AutoMod queue', style: nativeChatSheetTitleStyle(context)),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: SingleChildScrollView(
              child: Observer(
                builder: (context) => this._buildBody(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final queue = this._store.autoModQueue;
    if (queue.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          'No held messages',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final held in queue) this._heldRow(context, held),
      ],
    );
  }

  Widget _heldRow(BuildContext context, AutoModMessageHoldEvent held) {
    final running = this._runningMessageId == held.messageId;
    final busy = this._runningMessageId != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            width: 0.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    held.userName,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    held.message.text,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    this._metaLine(held),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (running)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: StylingHelper.isApple(context)
                    ? const CupertinoActivityIndicator(radius: 7.0)
                    : const SizedBox(
                        width: 14.0,
                        height: 14.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: Colors.white,
                        ),
                      ),
              )
            else ...[
              this._pill(
                context,
                label: 'Deny',
                filled: false,
                onTap: busy
                    ? null
                    : () => this._confirmResolve(held, allow: false),
              ),
              const SizedBox(width: AppSpacing.xs),
              this._pill(
                context,
                label: 'Allow',
                filled: true,
                onTap: busy
                    ? null
                    : () => this._confirmResolve(held, allow: true),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// "AutoMod · aggressive · level 3 · 2:35 PM" — or "Blocked term · …"
  /// when a public term list caught it (private terms never notify).
  String _metaLine(AutoModMessageHoldEvent held) {
    final parts = <String>[
      if (held.reason == 'blocked_term')
        'Blocked term'
      else ...[
        'AutoMod',
        ?held.automod?.category,
        if (held.automod?.level case final level?) 'level $level',
      ],
      if (held.heldAt case final heldAt?) this._formatHeldAt(heldAt),
    ];
    return parts.join(' · ');
  }

  /// Trailing pill button — same idiom as the bans sheet (filled = accent
  /// primary action, bordered = neutral).
  Widget _pill(
    BuildContext context, {
    required String label,
    required bool filled,
    required VoidCallback? onTap,
  }) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Pressable(
      haptic: true,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: filled ? accent : Colors.transparent,
          borderRadius: AppRadius.pill,
          border: filled
              ? null
              : Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: filled
                    ? Colors.white
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
        ),
      ),
    );
  }
}
