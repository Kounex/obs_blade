import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../utils/styling_helper.dart';
import 'native_chat_appearance.dart' show readableNameColor;

/// The sheet chrome lived here before every sheet in the app shared it
export '../../../../../../shared/general/base/sheet.dart';

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

  /// Neutral OFFLINE chip — the counterpart of [NativeChatStatusChip.live]
  /// in the channel pickers.
  factory NativeChatStatusChip.offline({Key? key}) =>
      NativeChatStatusChip(key: key, label: 'OFFLINE');

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

/// Live state of a channel in the channel pickers: `LIVE · viewers` while
/// on air, `OFFLINE` once known to be off air, nothing while unknown (not
/// polled yet, lookup failed) — an unknown channel never claims offline.
class NativeChatLiveTag extends StatelessWidget {
  /// true = live, false = offline, null = unknown (renders nothing).
  final bool? live;
  final int? viewerCount;

  const NativeChatLiveTag({super.key, required this.live, this.viewerCount});

  @override
  Widget build(BuildContext context) => switch (this.live) {
    true => NativeChatStatusChip.live(
      color:
          (Theme.of(context).extension<AppStatusColors>() ??
                  AppStatusColors.standard)
              .live,
      viewerCount: this.viewerCount,
    ),
    false => NativeChatStatusChip.offline(),
    null => const SizedBox.shrink(),
  };
}

/// The toast for a mod action the platform refused with 403 — on Kick
/// and YouTube the app can't know up front whether the account moderates
/// a channel, so the button is always offered and a refusal explains
/// itself instead of reading like a bug.
String chatNotModeratorText(String platform) =>
    'Nothing changed - $platform says you are not a moderator in this '
    'channel.';

/// Height cap of the channel pickers' open menus — longer lists scroll.
const double kChatChannelMenuMaxHeight = 360.0;

/// A–Z order of the channel pickers (case-insensitive; the own "You"
/// entry is placed first by the callers, not by this).
int compareChatChannelNames(String a, String b) {
  final byName = a.toLowerCase().compareTo(b.toLowerCase());
  return byName != 0 ? byName : a.compareTo(b);
}

/// The "You" marker on the signed-in account's own channel in the channel
/// dropdowns: a solid pill in the platform color with a contrasting
/// label, so it reads apart from the neutral LIVE / Mod chips.
class NativeChatYouChip extends StatelessWidget {
  final Color color;

  const NativeChatYouChip({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final label =
        ThemeData.estimateBrightnessForColor(this.color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2.0,
        vertical: 1.0,
      ),
      decoration: BoxDecoration(
        color: this.color,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        'You',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: label,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
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

/// A run of chat sheets that replace each other, the way Search chat
/// opens from the options: the old sheet slides down while the next one
/// slides up, instead of one sheet swapping its content and jumping to
/// the new height. [open] shows the sheet for a page and completes with
/// what that sheet popped - the page to show next (a back chevron pops
/// with the page it came from), or null (dismissed, or its action done),
/// which ends the run. Completes when the run ends, so a caller awaiting
/// the sheet (message selection chrome) waits for the last one.
Future<void> showChatSheetRun<P extends Object>(
  BuildContext context, {
  required P first,
  required Future<P?> Function(P page) open,
}) async {
  P? page = first;
  while (page != null && context.mounted) {
    page = await open(page);
  }
}

/// "── New messages ──" marker between backfilled history and the first
/// message that arrived live (Kick's own WebView chat does the same).
/// Lines take the platform [color]; the label sits in the same tint.
class ChatHistoryDivider extends StatelessWidget {
  final Color color;

  const ChatHistoryDivider({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1.0, color: this.color.withValues(alpha: 0.7)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'New messages',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: readableNameColor(
                  this.color,
                  Theme.of(context).cardColor,
                ),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          line,
        ],
      ),
    );
  }
}

/// Index in a timeline where the [ChatHistoryDivider] goes: right after
/// the last history row, but only once a live row follows it (no divider
/// while history is all there is). -1 = no divider.
int chatHistoryDividerIndex(List<bool> isHistorical) {
  final last = isHistorical.lastIndexOf(true);
  if (last < 0 || last == isHistorical.length - 1) return -1;
  return last + 1;
}

/// "── Some messages while away are missing ──" marker between the last
/// pre-suspend rows and a resume catch-up block whose history fetch
/// couldn't reach back (Twitch ≤ 800 rows, Kick ~50) — the honest loss
/// signal for the iOS background window. Same visual idiom as
/// [ChatHistoryDivider], own widget/key/semantics.
class ChatResumeGapDivider extends StatelessWidget {
  final Color color;

  const ChatResumeGapDivider({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Container(height: 1.0, color: this.color.withValues(alpha: 0.7)),
    );
    return Semantics(
      container: true,
      label: 'Some messages while away are missing',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            line,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                'Some messages while away are missing',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: readableNameColor(
                    this.color,
                    Theme.of(context).cardColor,
                  ),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            line,
          ],
        ),
      ),
    );
  }
}
