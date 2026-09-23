import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../utils/styling_helper.dart';

/// Compact LIVE / Mod chip used in the add-chat picker and the native
/// chat header — same visual language in both places.
class NativeChatStatusChip extends StatelessWidget {
  final String label;

  /// Tint color (LIVE chip). Null renders the neutral contained variant —
  /// static role badges don't spend the highlight.
  final Color? color;

  /// When set (LIVE chip only), rendered after ` · ` in white, tweened via
  /// [CountUpText] (the count updates on poll).
  final String? viewerCountLabel;

  const NativeChatStatusChip({
    super.key,
    required this.label,
    this.color,
    this.viewerCountLabel,
  });

  /// [viewerCount] when known → `LIVE · 1.2k` with the count in white;
  /// omit for a plain LIVE chip.
  factory NativeChatStatusChip.live({
    Key? key,
    required Color color,
    int? viewerCount,
  }) => NativeChatStatusChip(
    key: key,
    label: 'LIVE',
    viewerCountLabel: viewerCount == null
        ? null
        : formatChatViewerCount(viewerCount),
    color: color,
  );

  factory NativeChatStatusChip.mod({Key? key}) =>
      NativeChatStatusChip(key: key, label: 'Mod');

  @override
  Widget build(BuildContext context) {
    final Color? color = this.color;

    /// Static role badge (Mod): neutral contained chip in the bar-control
    /// idiom — lightened card fill, hairline, secondary label.
    if (color == null) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2.0,
        ),
        decoration: BoxDecoration(
          color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            width: 0.0,
          ),
        ),
        child: Text(
          this.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color:
                (Theme.of(context).extension<AppTextColors>() ??
                        AppTextColors.standard)
                    .textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    final baseStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.0),
      ),
      child: this.viewerCountLabel == null
          ? Text(this.label, style: baseStyle)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${this.label} · ', style: baseStyle),
                CountUpText(
                  value: this.viewerCountLabel!,
                  style: baseStyle?.copyWith(color: Colors.white),
                ),
              ],
            ),
    );
  }
}

/// Self-mention / keyword highlight wash — a warm, low-alpha tint distinct
/// from [TwitchChatMessageRow.holdHighlightColor]'s neutral gray (that one
/// means "selected for a mod action right now"; this one is passive, so it
/// borrows the app's warning hue rather than a stronger accent).
Color chatMentionHighlightColor(BuildContext context) =>
    (Theme.of(context).extension<AppStatusColors>() ?? AppStatusColors.standard)
        .warning
        .withValues(alpha: 0.12);

/// Compact viewer count for LIVE chips: `999`, `1.2k`, `3.4M`.
String formatChatViewerCount(int count) {
  if (count >= 1000000) {
    final value = count / 1000000;
    if (count % 1000000 == 0) return '${value.toInt()}M';
    return '${value.toStringAsFixed(1)}M';
  }
  if (count >= 1000) {
    final value = count / 1000;
    if (count % 1000 == 0) return '${value.toInt()}k';
    return '${value.toStringAsFixed(1)}k';
  }
  return '$count';
}

/// Sheet / page titles — title2 scale so they read clearly above body
/// (`titleMedium` is 15px in the On Air theme, same as body).
TextStyle? nativeChatSheetTitleStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .titleLarge
    ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3);

/// Section labels inside a sheet (Emotes, Badges groups, etc.) — the
/// app-wide caption contract (`labelSmall` 11/w600/0.8 on the tertiary text
/// level); apply `.toUpperCase()` at the use site.
TextStyle? nativeChatSheetSectionStyle(BuildContext context) =>
    Theme.of(context).textTheme.labelSmall;

/// Bottom overlay chip: "Paused" while scrolled up, "New messages" once
/// something arrives. Glass, same surface as the nav bars — it floats
/// over the timeline instead of pushing it.
class NativeChatScrollPill extends StatelessWidget {
  final bool hasNewMessages;
  final VoidCallback onTap;

  /// Count of messages that arrived since scrolling up — shown inline
  /// when known and positive (`"3 new messages ↓"`); falls back to the
  /// plain copy when null/zero (count not tracked, or reset mid-flight).
  final int? newMessageCount;

  const NativeChatScrollPill({
    super.key,
    required this.hasNewMessages,
    required this.onTap,
    this.newMessageCount,
  });

  String _unreadLabel() {
    final count = this.newMessageCount;
    if (count == null || count <= 0) return 'New messages ↓';
    return '$count new message${count == 1 ? '' : 's'} ↓';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool unread = this.hasNewMessages;
    final AppGlass glass = appGlassOf(context);
    final Color? tint = unread
        ? Color.alphaBlend(
            theme.colorScheme.primary.withValues(alpha: 0.18),
            glass.barColor,
          )
        : null;
    final Color? highlight =
        (theme.extension<AppTextColors>() ?? AppTextColors.standard)
            .highlightText;

    return Pressable(
      haptic: true,
      onTap: this.onTap,
      child: Container(
        /// Invisible 44pt hit expansion — the chip's visual bottom
        /// edge stays put
        constraints: const BoxConstraints(
          minWidth: kMinInteractiveDimensionCupertino,
          minHeight: kMinInteractiveDimensionCupertino,
        ),
        alignment: Alignment.bottomCenter,
        child: AnimatedSwitcher(
          duration: AppMotion.medium,
          transitionBuilder: (child, animation) =>
              nativeChatSwapTransition(context, child, animation),
          child: ClipRRect(
            key: ValueKey(unread),
            borderRadius: AppRadius.pill,
            child: GlassBar(
              contentEdge: GlassBarEdge.top,
              color: tint,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  unread ? this._unreadLabel() : 'Paused ↓',
                  style: unread
                      ? theme.textTheme.bodySmall?.copyWith(color: highlight)
                      : theme.textTheme.bodySmall,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Swap transition for small in-place morphs (status label, pause chip):
/// fade + slight rise at [AppMotion.emphasized], fade-only under reduced
/// motion — mirrors `switcher_card.dart`'s title swap.
Widget nativeChatSwapTransition(
  BuildContext context,
  Widget child,
  Animation<double> animation,
) {
  final CurvedAnimation curved = CurvedAnimation(
    parent: animation,
    curve: AppMotion.emphasized,
  );
  final Widget faded = FadeTransition(opacity: curved, child: child);
  if (AppMotion.reduce(context)) return faded;
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(curved),
    child: faded,
  );
}

/// Thin hairline matching native chat message separators.
Widget nativeChatHairline(BuildContext context) => Divider(
  height: 1.0,
  thickness: 0.5,
  color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
);

/// Drag handle for dismissible chat sheets.
Widget nativeChatSheetDragHandle(BuildContext context) => Center(
  child: Container(
    width: 36.0,
    height: 4.0,
    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
    decoration: BoxDecoration(
      color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
      borderRadius: AppRadius.pill,
    ),
  ),
);

/// Standard chat sheet layout: drag handle + [header] (title, back
/// chevron, actions) pinned at the top, only [body] scrolls. The shared
/// modal body caps the sheet height and still turns a pull past the top
/// of [body] into a sheet drag (same setup as the YouTube setup sheet).
/// Rule: sheets with a handle / title / back chevron never put those
/// inside the scroll view.
class NativeChatSheetScaffold extends StatelessWidget {
  final Widget header;
  final Widget body;

  /// Gap between the pinned header and the scrolling body.
  final double headerGap;

  const NativeChatSheetScaffold({
    super.key,
    required this.header,
    required this.body,
    this.headerGap = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            this.headerGap,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [nativeChatSheetDragHandle(context), this.header],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            primary: false,
            physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0.0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: this.body,
          ),
        ),
      ],
    );
  }
}
