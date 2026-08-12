import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/dialogs/confirmation.dart';
import '../../../../../stores/views/twitch_chat.dart';
import '../../../../../types/classes/twitch/twitch_pinned_message.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/styling_helper.dart';

/// Slim banner above the native Twitch chat timeline showing the channel's
/// currently pinned message (Helix pins — at most one per channel). The
/// store refetches on connect/switch and after local pin mutations (there
/// is no EventSub for pins).
///
/// Collapsed the banner stays muted and exactly one line — a pin sits
/// there passively and shouldn't draw focus. Tapping it anywhere toggles
/// the expanded state (even for one-liners): full message, active colors
/// (accent name, normal-contrast text). The ✕ unpin affordance only
/// renders for users who may moderate the selected channel and confirms
/// first — pinning affects the whole room; failures surface as a snackbar
/// hosted by the chat view's context.
class PinnedChatBanner extends StatefulWidget {
  final TwitchPinnedMessage pinned;

  const PinnedChatBanner({super.key, required this.pinned});

  @override
  State<PinnedChatBanner> createState() => _PinnedChatBannerState();
}

class _PinnedChatBannerState extends State<PinnedChatBanner> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant PinnedChatBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// A different pinned message always starts collapsed.
    if (oldWidget.pinned.messageId != this.widget.pinned.messageId) {
      this._expanded = false;
    }
  }

  void _confirmUnpin(BuildContext context) {
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: ConfirmationDialog(
        title: 'Unpin this message?',
        body: 'Remove the pinned message from the top of chat?',
        okText: 'Unpin',
        noText: 'Cancel',
        onOk: (_) async {
          final ok = await GetIt.instance<TwitchChatStore>().unpinMessage();
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Could not unpin the message'),
                ),
              );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = GetIt.instance<TwitchChatStore>();
    final theme = Theme.of(context);
    final mutedColor = theme.textTheme.bodySmall?.color;
    final activeColor = this._expanded
        ? theme.textTheme.bodyMedium?.color
        : mutedColor;
    final accentColor =
        this._expanded ? theme.colorScheme.secondary : mutedColor;

    return Pressable(
      haptic: true,
      onTap: () => setState(() => this._expanded = !this._expanded),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
          0.0,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: StylingHelper.lightenDarkenColor(theme.cardColor),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.4),
            width: 0.0,
          ),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.pin_fill, size: 14.0, color: accentColor),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${this.widget.pinned.senderUserName}: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    TextSpan(
                      text: this.widget.pinned.message.text,
                      style: TextStyle(color: activeColor),
                    ),
                  ],
                ),
                style: theme.textTheme.bodySmall,
                maxLines: this._expanded ? null : 1,
                overflow: this._expanded ? null : TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              this._expanded
                  ? CupertinoIcons.chevron_up
                  : CupertinoIcons.chevron_down,
              size: 12.0,
              color: mutedColor,
            ),
            if (store.canModerateSelectedChannel) ...[
              const SizedBox(width: AppSpacing.xs),
              Pressable(
                haptic: true,
                onTap: () => this._confirmUnpin(context),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 14.0,
                    color: mutedColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
