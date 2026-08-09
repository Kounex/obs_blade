import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_link.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_message_display.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_notice_chrome.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_notice_visibility.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';

/// One chat line: role badges + colored author name + message text with
/// inline emotes (first-party fragments and third-party 7TV/BTTV tokens),
/// @mentions, reply previews, and first-message / notice accent chrome.
class TwitchChatMessageRow extends StatelessWidget {
  final ChatMessageEvent event;

  /// Settings box — the badge visibility toggles
  /// ([settingsKeyForBadgeSetId]) plus the third-party emote toggle
  /// ([SettingsKeys.TwitchChatThirdPartyEmotes]) and appearance keys
  /// ([NativeChatAppearance]), read with defaults.
  final Box settingsBox;

  /// Moderation tombstone — username/badges stay; the body renders its
  /// original content dimmed (Twitch mod view) with a kind-specific
  /// marker (` —Deleted` / ` —Timed out (10m)` / ` —Banned`).
  final bool isDeleted;

  /// Marker copy when [isDeleted] — defaults to ` —Deleted`.
  final String deletedMarker;

  /// Display name of the moderator who deleted this message — arrives via
  /// `channel.moderate` when the token carries the moderation scope
  /// bundle; null for pre-upgrade tokens and always for purge//clear ids.
  /// Non-null together with [isDeleted] makes the row tappable
  /// ([onDeletedTap]).
  final String? deletedActor;

  /// Whether the actor reveal line under a deleted message is expanded.
  final bool isDeletedExpanded;

  /// Tap handler for a deleted message — toggles the reveal line.
  /// Tappability is gated on [isDeleted] + [deletedActor]; a null
  /// callback with an actor yields an inert, tap-swallowing target.
  final VoidCallback? onDeletedTap;

  /// Tap handler for a LIVE message (multi-chat mod actions) — set by the
  /// window only when the store allows moderating the selected channel.
  /// Tombstones keep their actor-reveal tap and never get this.
  final VoidCallback? onMessageTap;

  /// Left accent when this row continues a prior chat notification
  /// (same chatter).
  final Color? accentBarColor;

  /// Resolves a mention's chatter hex (`#RRGGBB`) from recent history.
  /// Broadcaster mentions always use [kChatBroadcasterMentionColor].
  final String? Function(String userId)? mentionHexFor;

  /// When embedded under a notification banner, skip outer vertical
  /// padding (the banner owns spacing).
  final bool compact;

  const TwitchChatMessageRow({
    super.key,
    required this.event,
    required this.settingsBox,
    this.isDeleted = false,
    this.deletedMarker = ' —Deleted',
    this.deletedActor,
    this.isDeletedExpanded = false,
    this.onDeletedTap,
    this.onMessageTap,
    this.accentBarColor,
    this.mentionHexFor,
    this.compact = false,
  });

  static const double _badgeSize = 18.0;

  bool get _isFirstMessage =>
      this.event.messageType == 'user_intro' &&
      isChatFirstMessageVisible(this.settingsBox);

  double get _emoteSize => NativeChatAppearance.emoteSize(this.settingsBox);
  double get _textSize => NativeChatAppearance.textSize(this.settingsBox);
  double get _spacing =>
      NativeChatAppearance.messageSpacing(this.settingsBox);

  Color _authorColor(BuildContext context) {
    final hex = this.event.color;
    if (hex != null && hex.length == 7) {
      final value = int.tryParse(hex.substring(1), radix: 16);
      if (value != null) {
        return Color(0xFF000000 | value);
      }
    }
    return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
  }

  /// Badges before the author name, in payload order. Unknown badges
  /// (catalog not loaded yet, new Twitch set) and toggled-off categories
  /// are skipped silently.
  List<InlineSpan> _badgeSpans() {
    if (this.event.badges.isEmpty) return const [];
    final badgeStore = GetIt.instance<TwitchBadgeStore>();
    return [
      for (final badge in this.event.badges)
        if (this.settingsBox.get(
          settingsKeyForBadgeSetId(badge.setId).name,
          defaultValue: true,
        ))
          if (badgeStore.badgeVersion(
                  this.event.broadcasterUserId, badge.setId, badge.id)
              case final version?)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs / 2),
                child: Image.network(
                  version.imageUrl2x,
                  height: _badgeSize,
                  width: _badgeSize,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
    ];
  }

  List<InlineSpan> _messageSpans(BuildContext context) {
    final fragments = fragmentsForChatDisplay(this.event);
    if (fragments.isEmpty) {
      /// Reply with only a suppressed `@parent` — fall back carefully:
      /// don't re-print the full wire text (it still has the @).
      if (this.event.reply != null && this.event.message.fragments.isNotEmpty) {
        return const [];
      }
      return this._linkAwareTextSpans(context, this.event.message.text);
    }
    return [
      for (final fragment in fragments)
        if (fragment.type == 'emote' && fragment.emote != null)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.network(
              twitchEmoteUrl(fragment.emote!.id),
              height: _emoteSize,
              width: _emoteSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(fragment.text),
            ),
          )
        else if (fragment.type == 'mention' && fragment.mention != null)
          TextSpan(
            text: fragment.text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: mentionColorForFragment(
                    mentionUserId: fragment.mention!.userId,
                    broadcasterUserId: this.event.broadcasterUserId,
                    chatterHex:
                        this.mentionHexFor?.call(fragment.mention!.userId),
                  ) ??
                  Colors.white,
            ),
          )
        else
          ...this._textSpans(context, fragment.text),
    ];
  }

  /// Body spans for a deleted message — the content stays (Twitch mod
  /// view) but dims hard: text recolors to half the marker's opacity and
  /// emote images get a matching [Opacity]. Structure, spacing and error
  /// builders are preserved. Assumes [_messageSpans] results are flat and
  /// recognizer-less (true today: plain TextSpans + emote WidgetSpans).
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

  /// Third-party emotes (7TV/BTTV) arrive as plain text — split on
  /// spaces and swap known tokens for inline images, preserving spacing
  /// exactly. Unknown tokens (and the toggle-off case) stay text / links.
  List<InlineSpan> _textSpans(BuildContext context, String text) {
    if (!this.settingsBox.get(
      SettingsKeys.TwitchChatThirdPartyEmotes.name,
      defaultValue: true,
    )) {
      return this._linkAwareTextSpans(context, text);
    }
    final emoteStore = GetIt.instance<ThirdPartyEmoteStore>();
    final tokens = text.split(' ');
    return [
      for (var i = 0; i < tokens.length; i++) ...[
        if (i > 0) const TextSpan(text: ' '),
        if (emoteStore.emoteImageUrl(tokens[i],
                broadcasterId: this.event.broadcasterUserId)
            case final imageUrl?)
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.network(
              imageUrl,
              height: _emoteSize,
              width: _emoteSize,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Text(tokens[i]),
            ),
          )
        else
          ...this._linkAwareTextSpans(context, tokens[i]),
      ],
    ];
  }

  /// Split [text] into plain runs and tappable links (http(s) + bare domains).
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
          child: GestureDetector(
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

  /// Badge-less rows never change — an Observer that tracks nothing
  /// spams flutter_mobx's "No observables" warning, so only rows with
  /// badges observe the catalog (arrivals/changes rebuild them;
  /// toggle changes come from the HiveBuilder above the list).
  @override
  Widget build(BuildContext context) {
    final Widget line = this.event.badges.isEmpty
        ? this._richText(context)
        : Observer(builder: this._richText);
    final bool revealable = this.isDeleted && this.deletedActor != null;
    final reply = this.event.reply;
    final Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (this._isFirstMessage)
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'FIRST MESSAGE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: kChatFirstMessageAccent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
            ),
          ),
        if (reply != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.reply,
                  size: 12.0,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: AppSpacing.xs / 2),
                Expanded(
                  child: Text(
                    'Replying to @${reply.parentUserName}: ${reply.parentMessageBody}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: this._textSize * 0.85,
                        ),
                  ),
                ),
              ],
            ),
          ),
        line,
        if (revealable && this.isDeletedExpanded)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
            child: Text(
              "${this.deletedActor} deleted ${this.event.chatterUserName}'s message",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );

    Widget chrome = body;
    if (this.accentBarColor != null || this._isFirstMessage) {
      final accent = this._isFirstMessage
          ? kChatFirstMessageAccent
          : this.accentBarColor!;
      chrome = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3.0,
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(child: body),
            if (this._isFirstMessage)
              Container(
                width: 3.0,
                margin: const EdgeInsets.only(left: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      );
      if (this._isFirstMessage) {
        chrome = ColoredBox(
          color: kChatFirstMessageTint,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs / 2,
            ),
            child: chrome,
          ),
        );
      }
    }

    final padded = this.compact
        ? chrome
        : Padding(
            padding: EdgeInsets.symmetric(vertical: this._spacing),
            child: chrome,
          );
    return revealable
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: this.onDeletedTap,
            child: padded,
          )
        : this.onMessageTap != null
            ? GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: this.onMessageTap,
                child: padded,
              )
            : padded;
  }

  Text _richText(BuildContext context) => Text.rich(
        TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: this._textSize,
              ),
          children: [
            ...this._badgeSpans(),
            TextSpan(
              text: this.event.chatterUserName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: this._authorColor(context),
              ),
            ),
            const TextSpan(text: ': '),
            if (this.isDeleted) ...[
              ...this._dimmedMessageSpans(context),
              TextSpan(
                text: this.deletedMarker,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ] else
              ...this._messageSpans(context),
          ],
        ),
      );
}
