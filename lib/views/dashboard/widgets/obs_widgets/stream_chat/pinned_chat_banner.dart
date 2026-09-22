import 'dart:ui' show lerpDouble;

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
/// there passively and shouldn't draw focus. Tapping the text toggles
/// the expanded state (even for one-liners): full message, active colors
/// (accent name, normal-contrast text). The ✕ closes the banner into a
/// pin button on the right of [child]; tapping that pin brings the
/// banner back. That close is local — the channel pin stays up. The
/// unpin affordance only renders when [onUnpin] is set and confirms
/// first — pinning affects the whole room; a failed unpin surfaces as
/// a snackbar.
class PinnedChatBanner extends StatefulWidget {
  final String messageId;
  final String senderName;
  final String text;

  /// Confirmed unpin. Null hides the unpin control (the viewer cannot
  /// unpin). Distinct from the ✕, which only tucks the banner.
  final Future<bool> Function()? onUnpin;

  /// Timeline under the banner. When set, the tucked pin floats over
  /// this child's right edge. When null, the banner is the whole widget
  /// (tests and any caller that only wants the card).
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

  /// Height of the open banner, captured at the moment it tucks so the
  /// timeline can keep that gap and release it as the pin travels.
  double _openHeight = 0;

  final GlobalKey _bannerKey = GlobalKey();

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
      this._openHeight = 0;
      if (this._tuck.value != 0) this._tuck.value = 0;
    }
  }

  void _syncDuration() {
    this._tuck.duration = AppMotion.reduce(this.context)
        ? Duration.zero
        : AppMotion.medium;
  }

  void _tuckAway() {
    final box =
        this._bannerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) this._openHeight = box.size.height;
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

  BoxDecoration _card(ThemeData theme, {bool circle = false}) => BoxDecoration(
    color: StylingHelper.lightenDarkenColor(theme.cardColor),
    borderRadius: circle ? null : BorderRadius.circular(AppRadius.md),
    shape: circle ? BoxShape.circle : BoxShape.rectangle,
    border: Border.all(
      color: theme.dividerColor.withValues(alpha: 0.4),
      width: 0.0,
    ),
  );

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
    final banner = Container(
      key: this._bannerKey,
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: this._card(theme),
      child: Row(
        children: [
          Icon(CupertinoIcons.pin_fill, size: 14.0, color: pinColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Pressable(
              haptic: true,
              onTap: () => setState(() => this._expanded = !this._expanded),
              child: reduce
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
            Semantics(
              button: true,
              label: 'Unpin message',
              child: Pressable(
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
                    CupertinoIcons.pin_slash,
                    size: 14.0,
                    color: mutedColor,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.xs),
          Semantics(
            button: true,
            label: 'Hide pinned message',
            child: Pressable(
              haptic: true,
              onTap: this._tuckAway,
              child: Container(
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
          ),
        ],
      ),
    );

    final dock = Semantics(
      button: true,
      label: 'Show pinned message',
      child: Pressable(
        haptic: true,
        onTap: this._restore,
        child: Container(
          width: 40.0,
          height: 40.0,
          alignment: Alignment.center,
          decoration: this._card(theme, circle: true),
          child: Icon(CupertinoIcons.pin_fill, size: 16.0, color: pinColor),
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
        if (t == 0 && this._tuck.status == AnimationStatus.dismissed) {
          return Column(
            children: [
              banner,
              Expanded(child: this.widget.child!),
            ],
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                SizedBox(height: this._openHeight * (1 - t)),
                Expanded(child: this.widget.child!),
              ],
            ),
            if (!tucked)
              IgnorePointer(
                child: _TravelingBanner(t: t, child: banner),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: IgnorePointer(
                  ignoring: t < 0.9,
                  child: Opacity(
                    opacity: const Interval(
                      0.35,
                      1.0,
                      curve: AppMotion.emphasized,
                    ).transform(t),
                    child: dock,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Banner sliding from the top of the chat toward the pin on the right,
/// clipping down to the pin's size as it goes.
class _TravelingBanner extends StatelessWidget {
  final double t;
  final Widget child;

  const _TravelingBanner({required this.t, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = (constraints.maxWidth - AppSpacing.sm * 2).clamp(
          40.0,
          double.infinity,
        );
        final width = lerpDouble(full, 40.0, this.t)!;
        return Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.sm,
            right: AppSpacing.sm,
          ),
          child: Align(
            alignment: Alignment.lerp(
              Alignment.topCenter,
              Alignment.centerRight,
              this.t,
            )!,
            child: SizedBox(
              width: width,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.centerRight,
                  minWidth: full,
                  maxWidth: full,
                  child: Opacity(
                    opacity: (1 - this.t).clamp(0.0, 1.0),
                    child: this.child,
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
