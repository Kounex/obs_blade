import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/dialogs/confirmation.dart';
import '../../../../../utils/modal_handler.dart';

/// Slim banner above a native chat timeline for the channel's single
/// pinned message. Platform-neutral: the caller supplies the visible
/// text and, when the user may unpin, [onUnpin].
///
/// Collapsed the banner stays muted and exactly one line — a pin sits
/// there passively and shouldn't draw focus. Tapping the message or the
/// chevron toggles the expanded state (even for one-liners): full
/// message, active colors (accent name, normal-contrast text). The ✕
/// tucks the banner into a pin button at the top-right. Both float over
/// [child] — they are not a row in the message list — and use the same
/// glass surface as the nav bars. Tapping the pin brings the banner
/// back. That close is local — the channel pin stays up. The unpin
/// affordance only renders when [onUnpin] is set and confirms first —
/// pinning affects the whole room; a failed unpin surfaces as a snackbar.
class PinnedChatBanner extends StatefulWidget {
  final String messageId;
  final String senderName;
  final String text;

  /// Confirmed unpin. Null hides the unpin control (the viewer cannot
  /// unpin). Distinct from the ✕, which only tucks the banner.
  final Future<bool> Function()? onUnpin;

  /// Timeline under the overlays. When set, the banner and the tucked
  /// pin both float on top of this child. When null, the banner is the
  /// whole widget (tests and any caller that only wants the card).
  final Widget? child;

  const PinnedChatBanner({
    super.key,
    required this.messageId,
    required this.senderName,
    required this.text,
    this.onUnpin,
    this.child,
  });

  @override
  State<PinnedChatBanner> createState() => _PinnedChatBannerState();
}

class _PinnedChatBannerState extends State<PinnedChatBanner>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  late final AnimationController _tuck;

  @override
  void initState() {
    super.initState();
    this._tuck = AnimationController(vsync: this, duration: AppMotion.medium);
  }

  @override
  void dispose() {
    this._tuck.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PinnedChatBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// A different pinned message always starts as a banner, collapsed.
    if (oldWidget.messageId != this.widget.messageId) {
      this._expanded = false;
      if (this._tuck.value != 0) this._tuck.value = 0;
    }
  }

  void _syncDuration() {
    this._tuck.duration = AppMotion.reduce(this.context)
        ? Duration.zero
        : AppMotion.medium;
  }

  void _tuckAway() {
    this._syncDuration();
    this._tuck.forward();
  }

  void _restore() {
    this._syncDuration();
    this._tuck.reverse();
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

  /// Same surface as the nav bars, clipped to [radius]. A null radius
  /// is the tucked pin (a circle).
  Widget _glass({required Widget child, BorderRadius? radius}) {
    final clipped = GlassBar(contentEdge: GlassBarEdge.bottom, child: child);
    if (radius == null) {
      return ClipOval(child: clipped);
    }
    return ClipRRect(borderRadius: radius, child: clipped);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.textTheme.bodySmall?.color;
    final highlightText =
        (theme.extension<AppTextColors>() ?? AppTextColors.standard)
            .highlightText;
    final pinColor = this._expanded ? highlightText : mutedColor;

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

    final reduce = AppMotion.reduce(context);
    final message = reduce
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
          );

    /// Glyph-sized controls. A 44pt box on the ✕ used to cover the gap
    /// beside the chevron, so a tap there closed the banner.
    Widget glyphButton({
      required String label,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return Semantics(
        button: true,
        label: label,
        child: Pressable(
          haptic: true,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Icon(icon, size: 14.0, color: mutedColor),
          ),
        ),
      );
    }

    final banner = this._glass(
      radius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Pressable(
                haptic: true,
                onTap: () => setState(() => this._expanded = !this._expanded),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.pin_fill, size: 14.0, color: pinColor),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: message),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      this._expanded
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 12.0,
                      color: mutedColor,
                    ),
                  ],
                ),
              ),
            ),
            if (this.widget.onUnpin != null) ...[
              const SizedBox(width: AppSpacing.sm),
              glyphButton(
                label: 'Unpin message',
                icon: CupertinoIcons.pin_slash,
                onTap: () => this._confirmUnpin(context),
              ),
            ],
            const SizedBox(width: AppSpacing.sm),
            glyphButton(
              label: 'Hide pinned message',
              icon: CupertinoIcons.xmark,
              onTap: this._tuckAway,
            ),
          ],
        ),
      ),
    );

    final dock = Semantics(
      button: true,
      label: 'Show pinned message',
      child: Pressable(
        haptic: true,
        onTap: this._restore,
        child: this._glass(
          child: SizedBox(
            width: 40.0,
            height: 40.0,
            child: Icon(CupertinoIcons.pin_fill, size: 16.0, color: pinColor),
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: this._tuck,
      builder: (context, _) {
        final t = this._tuck.value;
        final tucked = this._tuck.status == AnimationStatus.completed;
        if (this.widget.child == null) {
          return tucked ? dock : banner;
        }

        /// Both states float over the timeline. The open banner
        /// collapses toward the top-right, where the pin rests.
        final reveal = (1 - t).clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            this.widget.child!,
            if (!tucked)
              Positioned(
                top: AppSpacing.xs,
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                child: IgnorePointer(
                  ignoring: t > 0.05,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topRight,
                        heightFactor: reveal,
                        widthFactor: reveal,
                        child: Opacity(opacity: reveal, child: banner),
                      ),
                    ),
                  ),
                ),
              ),
            if (t > 0)
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.sm,
                child: IgnorePointer(
                  ignoring: t < 0.9,
                  child: Opacity(
                    opacity: const Interval(
                      0.45,
                      1.0,
                      curve: AppMotion.emphasized,
                    ).transform(t),
                    child: dock,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
