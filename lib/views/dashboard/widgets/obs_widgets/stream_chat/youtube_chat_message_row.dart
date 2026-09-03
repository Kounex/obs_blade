import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/utils/icons/jam_icons.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_link.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

/// YouTube's published Super Chat / Super Sticker tier color table
/// (support.google.com/youtube/answer/7277005 — tiers map to price bands,
/// blue → red ascending). The API reports `tier` 1–11; tiers above 7 share
/// the top red band.
Color youTubeSuperChatTierColor(int tier) => switch (tier) {
      1 => const Color(0xFF1565C0),
      2 => const Color(0xFF00B8D4),
      3 => const Color(0xFF00BFA5),
      4 => const Color(0xFFFFB300),
      5 => const Color(0xFFE65100),
      6 => const Color(0xFFC2185B),
      _ => const Color(0xFFD50000),
    };

/// YouTube sends no per-chatter chat color (unlike Twitch) — derive a
/// stable pastel from the author channel id so names stay distinguishable
/// without clashing with the tier card colors. Authors without a channel
/// id fall back to the plain body color (what the Twitch row does for
/// uncolored names).
Color youTubeAuthorColor(BuildContext context, String? authorChannelId) {
  final id = authorChannelId;
  if (id == null || id.isEmpty) {
    return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
  }
  var hash = 0;
  for (final unit in id.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return HSLColor.fromAHSL(1.0, (hash % 360).toDouble(), 0.55, 0.62)
      .toColor();
}

/// Accent for member notices (new member / milestone / gifts) — YouTube's
/// member green.
const Color kYouTubeMemberAccent = Color(0xFF2BA640);

/// One native YouTube chat line, mirroring [TwitchChatMessageRow]'s
/// structure but bound to [YouTubeChatMessage]: icon badges (no badge
/// artwork exists in the API), hash-colored author, link-aware body,
/// Super Chat / Super Sticker tier cards, member/poll notice rows and the
/// dimmed ` —Deleted` tombstone treatment.
class YouTubeChatMessageRow extends StatelessWidget {
  final YouTubeChatMessage message;

  /// Settings box — appearance keys ([NativeChatAppearance]), read with
  /// defaults.
  final Box settingsBox;

  /// Long-press handler for mod actions on a live message (signed-in
  /// only — gated by the caller, plan §7).
  final VoidCallback? onMessageLongPress;

  /// Light gray wash while this row is the open mod-sheet target.
  final bool highlighted;

  const YouTubeChatMessageRow({
    super.key,
    required this.message,
    required this.settingsBox,
    this.onMessageLongPress,
    this.highlighted = false,
  });

  double get _textSize => NativeChatAppearance.textSize(this.settingsBox);
  double get _spacing =>
      NativeChatAppearance.messageSpacing(this.settingsBox);

  /// Role badges as inline icons, in YouTube's own order (owner, mod,
  /// member, verified).
  List<Widget> _badgeWidgets() {
    return [
      if (this.message.isOwner)
        this._badge(
          key: const Key('yt-badge-owner'),
          icon: JamIcons.crown_f,
          color: const Color(0xFFFFB300),
        ),
      if (this.message.isModerator)
        this._badge(
          key: const Key('yt-badge-mod'),
          icon: JamIcons.wrench_f,
          color: const Color(0xFF78909C),
        ),
      if (this.message.isSponsor)
        this._badge(
          key: const Key('yt-badge-member'),
          icon: JamIcons.star_f,
          color: kYouTubeMemberAccent,
        ),
      if (this.message.isVerified)
        this._badge(
          key: const Key('yt-badge-verified'),
          icon: CupertinoIcons.checkmark_seal_fill,
          color: const Color(0xFF78909C),
        ),
    ];
  }

  Widget _badge({required Key key, required IconData icon, Color? color}) =>
      Padding(
        key: key,
        padding: const EdgeInsets.only(right: AppSpacing.xs / 2),
        child: Icon(icon, size: 14.0, color: color),
      );

  List<InlineSpan> _badgeSpans() => [
        for (final widget in this._badgeWidgets())
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: widget,
          ),
      ];

  TextSpan _authorSpan(BuildContext context) => TextSpan(
        text: this.message.authorName ?? 'Unknown',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: youTubeAuthorColor(context, this.message.authorChannelId),
        ),
      );

  /// Body text with tappable links — same split idiom as the Twitch row.
  List<InlineSpan> _linkAwareTextSpans(BuildContext context, String text) {
    if (text.isEmpty) return const [];
    final matches = chatUrlMatches(text).toList();
    if (matches.isEmpty) return [TextSpan(text: text)];

    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
      decorationColor: Theme.of(context).colorScheme.primary,
    );
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final url = match.group(0)!;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Pressable(
            haptic: true,
            onTap: () => confirmAndOpenChatLink(context, url),
            child: Text(url, style: linkStyle),
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return spans;
  }

  List<InlineSpan> _messageSpans(BuildContext context) =>
      this._linkAwareTextSpans(
        context,
        this.message.snippet.textMessageDetails?.messageText ??
            this.message.displayText ??
            '',
      );

  /// Tombstone treatment — the content stays visible but dims hard, with
  /// the italic marker appended (same UX as the Twitch row).
  List<InlineSpan> _dimmedMessageSpans(BuildContext context) {
    final color = Theme.of(context)
        .textTheme
        .bodySmall
        ?.color
        ?.withValues(alpha: 0.5);
    return [
      for (final span in this._messageSpans(context))
        if (span is TextSpan)
          TextSpan(text: span.text, style: TextStyle(color: color))
        else if (span is WidgetSpan)
          WidgetSpan(
            alignment: span.alignment,
            child: Opacity(opacity: 0.5, child: span.child),
          )
        else
          span,
    ];
  }

  TextSpan _deletedMarkerSpan(BuildContext context) => TextSpan(
        text: ' —Deleted',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      );

  /// The plain chat line: badges + colored author + body.
  Widget _textRow(BuildContext context) => Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: this._textSize,
              ),
          children: [
            ...this._badgeSpans(),
            this._authorSpan(context),
            const TextSpan(text: ': '),
            if (this.message.isTombstoned) ...[
              ...this._dimmedMessageSpans(context),
              this._deletedMarkerSpan(context),
            ] else
              ...this._messageSpans(context),
          ],
        ),
      );

  /// Tier-colored money card (Super Chat with comment / Super Sticker).
  Widget _tierCard(
    BuildContext context, {
    required Key key,
    required int tier,
    required String? amountDisplayString,
    required List<InlineSpan> bodySpans,
  }) {
    final tierColor = youTubeSuperChatTierColor(tier);
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: this._textSize,
        );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: baseStyle,
                  children: [
                    ...this._badgeSpans(),
                    this._authorSpan(context),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (amountDisplayString != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                amountDisplayString,
                style: baseStyle?.copyWith(
                  color: tierColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
        if (bodySpans.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs / 2),
          Text.rich(
            TextSpan(style: baseStyle, children: [
              if (this.message.isTombstoned) ...[
                ...this._dimmedSpans(context, bodySpans),
                this._deletedMarkerSpan(context),
              ] else
                ...bodySpans,
            ]),
          ),
        ],
      ],
    );

    final card = Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tierColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: tierColor.withValues(alpha: 0.55),
          width: 1.0,
        ),
      ),
      child: content,
    );

    /// A tombstoned card keeps its structure but dims — the tier band is
    /// part of the message, not live content.
    return this.message.isTombstoned
        ? Opacity(opacity: 0.6, child: card)
        : card;
  }

  List<InlineSpan> _dimmedSpans(BuildContext context, List<InlineSpan> spans) {
    final color = Theme.of(context)
        .textTheme
        .bodySmall
        ?.color
        ?.withValues(alpha: 0.5);
    return [
      for (final span in spans)
        if (span is TextSpan)
          TextSpan(text: span.text, style: TextStyle(color: color))
        else
          span,
    ];
  }

  /// Member/system notice: small icon + author + one-line notice, with an
  /// optional comment line below (milestones carry a user comment).
  Widget _noticeRow(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required String notice,
    String? comment,

    /// Member notices name the author; pure system lines (chat ended)
    /// don't have a meaningful one.
    bool showAuthor = true,
  }) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: this._textSize,
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, size: 14.0, color: accent),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: baseStyle,
                  children: [
                    if (showAuthor) ...[
                      this._authorSpan(context),
                      const TextSpan(text: ' '),
                    ],
                    TextSpan(text: notice),
                  ],
                ),
              ),
              if (comment != null && comment.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs / 2),
                Text.rich(
                  TextSpan(
                    style: baseStyle,
                    children: this._linkAwareTextSpans(context, comment),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _pollCard(BuildContext context, YouTubePollMetadata metadata) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: this._textSize,
        );
    final mutedStyle = Theme.of(context).textTheme.bodySmall;
    return Container(
      key: const Key('yt-poll-card'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.chart_bar,
                size: 14.0,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  metadata.questionText ?? 'Poll',
                  style: baseStyle?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (metadata.status == 'closed')
                Text('closed', style: mutedStyle),
            ],
          ),
          for (final option in metadata.options)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option.optionText ?? '',
                      style: baseStyle,
                    ),
                  ),

                  /// Tallies are owner-only in the API — show when present.
                  if (option.tally != null)
                    Text(option.tally!, style: mutedStyle),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildByType(BuildContext context) {
    final snippet = this.message.snippet;
    switch (this.message.type) {
      case YouTubeChatMessageType.superChat:
        final details = snippet.superChatDetails;
        final comment = details?.userComment;
        return this._tierCard(
          context,
          key: const Key('yt-super-chat-card'),
          tier: details?.tier ?? 0,
          amountDisplayString: details?.amountDisplayString,
          bodySpans: comment == null
              ? const []
              : this._linkAwareTextSpans(context, comment),
        );
      case YouTubeChatMessageType.superSticker:

        /// No sticker image exists in the API — alt text is all we get.
        final details = snippet.superStickerDetails;
        final altText = details?.superStickerMetadata?.altText;
        return this._tierCard(
          context,
          key: const Key('yt-super-sticker-card'),
          tier: details?.tier ?? 0,
          amountDisplayString: details?.amountDisplayString,
          bodySpans: [
            TextSpan(
              text: altText == null ? 'Sent a sticker' : 'Sent a sticker: ',
            ),
            if (altText != null)
              TextSpan(
                text: altText,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        );
      case YouTubeChatMessageType.newSponsor:
        final level = snippet.newSponsorDetails?.memberLevelName;
        return this._noticeRow(
          context,
          icon: JamIcons.star_f,
          accent: kYouTubeMemberAccent,
          notice: level == null ? 'became a member' : 'became a member ($level)',
        );
      case YouTubeChatMessageType.memberMilestone:
        final details = snippet.memberMilestoneChatDetails;
        final months = details?.memberMonth ?? 0;
        return this._noticeRow(
          context,
          icon: JamIcons.star_f,
          accent: kYouTubeMemberAccent,
          notice: months > 0
              ? 'has been a member for $months months'
              : 'celebrated a membership milestone',
          comment: details?.userComment,
        );
      case YouTubeChatMessageType.membershipGifting:
        final details = snippet.membershipGiftingDetails;
        final count = details?.giftMembershipsCount ?? 0;
        return this._noticeRow(
          context,
          icon: JamIcons.gift_f,
          accent: kYouTubeMemberAccent,
          notice: count > 0
              ? 'gifted $count ${details?.giftMembershipsLevelName ?? ''} memberships'
                  .replaceAll('  ', ' ')
              : 'gifted memberships',
        );
      case YouTubeChatMessageType.giftMembershipReceived:
        final level = snippet.giftMembershipReceivedDetails?.memberLevelName;
        return this._noticeRow(
          context,
          icon: JamIcons.gift_f,
          accent: kYouTubeMemberAccent,
          notice: level == null
              ? 'received a gift membership'
              : 'received a gift membership ($level)',
        );
      case YouTubeChatMessageType.poll:
        final metadata = snippet.pollDetails?.metadata;
        if (metadata == null) return const SizedBox.shrink();
        return this._pollCard(context, metadata);
      case YouTubeChatMessageType.sponsorOnlyModeStarted:
        return this._noticeRow(
          context,
          icon: JamIcons.shield_f,
          accent: kYouTubeMemberAccent,
          notice: 'turned on members-only mode',
        );
      case YouTubeChatMessageType.sponsorOnlyModeEnded:
        return this._noticeRow(
          context,
          icon: JamIcons.shield,
          accent: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
          notice: 'turned off members-only mode',
        );
      case YouTubeChatMessageType.chatEnded:
        return this._noticeRow(
          context,
          icon: CupertinoIcons.stop_circle,
          accent: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
          notice: 'Live chat has ended',
          showAuthor: false,
        );

      /// Lifecycle events (tombstone / userBanned) are consumed by the
      /// store — they never land in the message buffer as rows.
      case YouTubeChatMessageType.tombstone:
      case YouTubeChatMessageType.userBanned:
        return const SizedBox.shrink();
      case YouTubeChatMessageType.textMessage:
      case YouTubeChatMessageType.unknown:
        return this._textRow(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Lifecycle pseudo-events render nothing at all — skip the padding
    /// and the long-press chrome too.
    if (this.message.type == YouTubeChatMessageType.tombstone ||
        this.message.type == YouTubeChatMessageType.userBanned) {
      return const SizedBox.shrink();
    }

    final padded = Padding(
      padding: EdgeInsets.symmetric(vertical: this._spacing),
      child: this._buildByType(context),
    );

    if (this.onMessageLongPress != null && !this.message.isTombstoned) {
      return ChatRowLongPressListener(
        highlighted: this.highlighted,
        onLongPress: this.onMessageLongPress!,
        child: padded,
      );
    }
    if (this.highlighted) {
      return ColoredBox(
        color: TwitchChatMessageRow.holdHighlightColor(context),
        child: padded,
      );
    }
    return padded;
  }
}
