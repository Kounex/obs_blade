import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/dialogs/confirmation.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/styling_helper.dart';

/// Slim banner above a native chat timeline for the channel's single
/// pinned message. Platform-neutral: the caller supplies the visible
/// text and, when the user may unpin, [onUnpin].
///
/// Collapsed the banner stays muted and exactly one line — a pin sits
/// there passively and shouldn't draw focus. Tapping it anywhere toggles
/// the expanded state (even for one-liners): full message, active colors
/// (accent name, normal-contrast text). The ✕ unpin affordance only
/// renders when [onUnpin] is set and confirms first — pinning affects
/// the whole room; a failed unpin surfaces as a snackbar.
class PinnedChatBanner extends StatefulWidget {
  final String messageId;
  final String senderName;
  final String text;

  /// Confirmed unpin. Null hides the ✕ (the viewer cannot unpin).
  final Future<bool> Function()? onUnpin;

  const PinnedChatBanner({
    super.key,
    required this.messageId,
    required this.senderName,
    required this.text,
    this.onUnpin,
  });

  @override
  State<PinnedChatBanner> createState() => _PinnedChatBannerState();
}

class _PinnedChatBannerState extends State<PinnedChatBanner> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant PinnedChatBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// A different pinned message always starts collapsed.
    if (oldWidget.messageId != this.widget.messageId) {
      this._expanded = false;
    }
  }

  void _confirmUnpin(BuildContext context) {
    final unpin = this.widget.onUnpin;
    if (unpin == null) return;
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: ConfirmationDialog(
        title: 'Unpin this message?',
        body: 'Remove the pinned message from the top of chat?',
        okText: 'Unpin',
        noText: 'Cancel',
        onOk: (_) async {
          final ok = await unpin();
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('Could not unpin the message')),
              );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.textTheme.bodySmall?.color;
    final highlightText =
        (theme.extension<AppTextColors>() ?? AppTextColors.standard)
            .highlightText;

    Widget messageText(bool expanded) => Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${this.widget.senderName}: ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: expanded ? highlightText : mutedColor,
            ),
          ),
          TextSpan(
            text: this.widget.text,
            style: TextStyle(
              color: expanded ? theme.textTheme.bodyMedium?.color : mutedColor,
            ),
          ),
        ],
      ),
      style: theme.textTheme.bodySmall,
      maxLines: expanded ? null : 1,
      overflow: expanded ? null : TextOverflow.ellipsis,
    );

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
            Icon(
              CupertinoIcons.pin_fill,
              size: 14.0,
              color: this._expanded ? highlightText : mutedColor,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppMotion.reduce(context)
                  ? AnimatedSwitcher(
                      duration: AppMotion.medium,
                      child: KeyedSubtree(
                        key: ValueKey(this._expanded),
                        child: messageText(this._expanded),
                      ),
                    )
                  : AnimatedCrossFade(
                      firstChild: messageText(false),
                      secondChild: messageText(true),
                      crossFadeState: this._expanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: AppMotion.medium,
                      sizeCurve: AppMotion.emphasized,
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
            if (this.widget.onUnpin != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Pressable(
                haptic: true,
                onTap: () => this._confirmUnpin(context),
                child: Container(
                  /// Invisible hit widening to 44pt - the banner's height
                  /// must not grow, so the glyph keeps its spot
                  constraints: const BoxConstraints(
                    minWidth: kMinInteractiveDimensionCupertino,
                  ),
                  alignment: Alignment.centerRight,
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
